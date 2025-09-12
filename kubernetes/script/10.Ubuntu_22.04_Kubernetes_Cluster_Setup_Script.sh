#!/bin/bash

#############################################
# Ubuntu 22.04 Kubernetes Cluster Setup Script
# Purpose: Complete K8s cluster deployment for Ubuntu 22.04 LTS on KVM
# Version: 3.0
#############################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_VERSION="3.0"
LOG_FILE="/var/log/k8s-setup-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/root/k8s-backup-$(date +%Y%m%d-%H%M%S)"

# Cluster Configuration
K8S_VERSION="1.29.0"
POD_NETWORK_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
CLUSTER_NAME="ubuntu-cluster"

# Node Configuration (자동 감지)
CURRENT_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
HOSTNAME=$(hostname -f)

# Function definitions
log_info() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "${LOG_FILE}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "${LOG_FILE}"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"; }
log_section() { 
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"
    echo -e "${BLUE}▶ $1${NC}" | tee -a "${LOG_FILE}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

#############################################
# PHASE 0: INSTALL PREREQUISITES
#############################################

install_prerequisites() {
    log_section "PHASE 0: Installing Prerequisites"
    
    log_info "Updating package list..."
    apt-get update
    
    log_info "Installing essential packages..."
    
    # Install required packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        bash-completion \
        net-tools \
        wget \
        jq \
        git \
        vim \
        htop \
        iotop \
        sysstat \
        ipvsadm \
        ipset \
        conntrack \
        socat \
        tree \
        unzip \
        tar \
        gzip \
        bzip2 \
        nfs-common \
        cifs-utils \
        open-iscsi \
        ethtool \
        bridge-utils \
        ebtables \
        arptables \
        iptables \
        chrony \
        ufw
    
    # Install monitoring tools
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        dstat \
        iftop \
        ncdu \
        hdparm \
        lvm2 \
        parted
    
    # Install build essentials (might be needed for some CNI plugins)
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        linux-headers-$(uname -r)
    
    log_info "✓ Prerequisites installed successfully"
}

# Backup current configuration
backup_system() {
    log_section "Creating System Backup"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup important files
    cp -r /etc/sysctl.d "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /etc/modules-load.d "${BACKUP_DIR}/" 2>/dev/null || true
    cp /etc/fstab "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /etc/apt/sources.list* "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /etc/netplan "${BACKUP_DIR}/" 2>/dev/null || true
    
    log_info "Backup created at ${BACKUP_DIR}"
}

#############################################
# PHASE 1: SYSTEM PREPARATION
#############################################

prepare_system() {
    log_section "PHASE 1: System Preparation"
    
    # 1. Disable Swap
    log_info "Disabling swap..."
    swapoff -a
    sed -i '/\sswap\s/d' /etc/fstab
    
    # Remove swap file if exists
    if [ -f /swap.img ]; then
        rm -f /swap.img
        log_info "Removed swap file /swap.img"
    fi
    
    # Verify swap is disabled
    if [ "$(free | awk '/^Swap:/{print $2}')" = "0" ]; then
        log_info "✓ Swap disabled successfully"
    else
        log_error "Failed to disable swap"
        exit 1
    fi
    
    # 2. Configure time synchronization
    log_info "Configuring time synchronization..."
    systemctl enable --now chrony
    chronyc sources
    
    # 3. Configure required kernel modules
    log_info "Loading required kernel modules..."
    cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
ip_vs_lc
nf_conntrack
EOF
    
    # Load modules immediately
    modprobe overlay
    modprobe br_netfilter
    modprobe ip_vs
    modprobe ip_vs_rr
    modprobe ip_vs_wrr
    modprobe ip_vs_sh
    modprobe ip_vs_lc
    modprobe nf_conntrack
    
    # Verify modules are loaded
    for module in overlay br_netfilter ip_vs nf_conntrack; do
        if lsmod | grep -q "^$module "; then
            log_info "✓ Module $module loaded"
        else
            log_error "Failed to load module $module"
        fi
    done
    
    # 4. Configure sysctl parameters
    log_info "Configuring kernel parameters..."
    cat > /etc/sysctl.d/99-kubernetes.conf <<EOF
# Network settings for Kubernetes
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Increase limits for containers
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
fs.file-max = 2097152
kernel.pid_max = 4194304

# Network tuning
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10

# Memory settings
vm.swappiness = 0
vm.overcommit_memory = 1
vm.panic_on_oom = 0
vm.max_map_count = 262144

# Connection tracking
net.netfilter.nf_conntrack_max = 1000000
net.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 3600

# Buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
EOF
    
    sysctl --system
    
    # 5. Configure UFW firewall for Kubernetes
    log_info "Configuring firewall..."
    
    # Disable UFW initially (we'll configure it properly)
    ufw --force disable
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    ufw default allow routed
    
    # Allow SSH (important!)
    ufw allow 22/tcp comment 'SSH'
    
    # Master node ports
    ufw allow 6443/tcp comment 'Kubernetes API server'
    ufw allow 2379:2380/tcp comment 'etcd server client API'
    ufw allow 10250/tcp comment 'Kubelet API'
    ufw allow 10251/tcp comment 'kube-scheduler'
    ufw allow 10252/tcp comment 'kube-controller-manager'
    ufw allow 10255/tcp comment 'Read-only Kubelet API'
    
    # Worker node ports
    ufw allow 30000:32767/tcp comment 'NodePort Services'
    
    # Flannel VXLAN
    ufw allow 8472/udp comment 'Flannel VXLAN'
    
    # Calico
    ufw allow 179/tcp comment 'Calico BGP'
    ufw allow 4789/udp comment 'Calico VXLAN'
    
    # Cilium
    ufw allow 8472/udp comment 'Cilium VXLAN'
    ufw allow 4240/tcp comment 'Cilium health checks'
    
    # Allow pod and service networks
    ufw allow from 10.244.0.0/16 comment 'Pod network'
    ufw allow from 10.96.0.0/12 comment 'Service network'
    
    # Enable UFW
    ufw --force enable
    ufw status numbered
    
    # 6. Configure systemd resolved (for CoreDNS compatibility)
    log_info "Configuring systemd-resolved..."
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    
    # 7. Set up limits
    log_info "Configuring system limits..."
    cat > /etc/security/limits.d/kubernetes.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft memlock unlimited
* hard memlock unlimited
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
root soft memlock unlimited
root hard memlock unlimited
EOF
    
    log_info "✓ System preparation complete"
}

#############################################
# PHASE 2: CONTAINER RUNTIME INSTALLATION
#############################################

install_containerd() {
    log_section "PHASE 2: Installing Containerd"
    
    # 1. Remove any existing Docker/containerd installations
    log_info "Removing any existing container runtime..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    apt-get autoremove -y
    
    # 2. Add Docker's official GPG key
    log_info "Adding Docker repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # 3. Add Docker repository
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 4. Update package list
    apt-get update
    
    # 5. Install containerd
    log_info "Installing containerd..."
    apt-get install -y containerd.io
    
    # 6. Configure containerd
    log_info "Configuring containerd..."
    mkdir -p /etc/containerd
    containerd config default > /etc/containerd/config.toml
    
    # Enable SystemdCgroup
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    
    # Configure registry endpoints
    cat >> /etc/containerd/config.toml <<EOF

# Additional registry configuration
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://registry-1.docker.io"]
EOF
    
    # 7. Create containerd service override
    mkdir -p /etc/systemd/system/containerd.service.d
    cat > /etc/systemd/system/containerd.service.d/override.conf <<EOF
[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStartPre=-/sbin/modprobe br_netfilter
EOF
    
    # 8. Restart and enable containerd
    systemctl daemon-reload
    systemctl restart containerd
    systemctl enable containerd
    
    # Verify containerd is running
    if systemctl is-active containerd >/dev/null 2>&1; then
        log_info "✓ Containerd installed and running"
        ctr version
    else
        log_error "Containerd installation failed"
        exit 1
    fi
    
    # 9. Install crictl for debugging
    log_info "Installing crictl..."
    CRICTL_VERSION="v1.29.0"
    wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
    tar zxf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin
    rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
    
    # Configure crictl
    cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    
    crictl version
    log_info "✓ Container runtime setup complete"
}

#############################################
# PHASE 3: KUBERNETES INSTALLATION
#############################################

install_kubernetes() {
    log_section "PHASE 3: Installing Kubernetes"
    
    # 1. Add Kubernetes GPG key
    log_info "Adding Kubernetes repository..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    # 2. Add Kubernetes repository
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    
    # 3. Update package list
    apt-get update
    
    # 4. Check available versions
    log_info "Available Kubernetes versions:"
    apt-cache madison kubeadm | head -5
    
    # 5. Install Kubernetes components
    log_info "Installing Kubernetes components..."
    apt-get install -y kubelet="${K8S_VERSION}-*" kubeadm="${K8S_VERSION}-*" kubectl="${K8S_VERSION}-*"
    
    # 6. Hold packages to prevent automatic updates
    apt-mark hold kubelet kubeadm kubectl
    
    # 7. Configure kubelet
    log_info "Configuring kubelet..."
    cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
    
    # 8. Enable and start kubelet
    systemctl daemon-reload
    systemctl enable kubelet
    systemctl start kubelet
    
    # Note: kubelet will be in a crashloop until kubeadm init is run
    log_info "✓ Kubernetes components installed"
    log_info "  kubelet version: $(kubelet --version)"
    log_info "  kubeadm version: $(kubeadm version -o short)"
    log_info "  kubectl version: $(kubectl version --client --short)"
}

#############################################
# PHASE 4: CLUSTER INITIALIZATION
#############################################

init_master() {
    log_section "PHASE 4: Initializing Kubernetes Master"
    
    # Check if already initialized
    if [ -f /etc/kubernetes/admin.conf ]; then
        log_warn "Kubernetes appears to be already initialized"
        read -p "Do you want to reset and reinitialize? (yes/no): " reset_choice
        if [[ "$reset_choice" == "yes" ]]; then
            kubeadm reset -f
            rm -rf /etc/cni/net.d
            rm -rf $HOME/.kube
            rm -rf /var/lib/etcd
        else
            return
        fi
    fi
    
    # Ask for cluster configuration
    read -p "Is this the FIRST master node? (yes/no): " is_first_master
    
    if [[ "$is_first_master" == "yes" ]]; then
        # Option for HA setup
        read -p "Will you add more master nodes later? (yes/no): " ha_setup
        
        if [[ "$ha_setup" == "yes" ]]; then
            read -p "Enter the Load Balancer IP/hostname for API server (or press Enter to use current IP): " lb_endpoint
            CONTROL_PLANE_ENDPOINT="${lb_endpoint:-$CURRENT_IP}"
        else
            CONTROL_PLANE_ENDPOINT="$CURRENT_IP"
        fi
        
        # Create audit log directory
        mkdir -p /var/log/kube-audit
        
        # Create kubeadm configuration
        cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${CURRENT_IP}
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  kubeletExtraArgs:
    pod-infra-container-image: registry.k8s.io/pause:3.9
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v${K8S_VERSION}
clusterName: ${CLUSTER_NAME}
controlPlaneEndpoint: "${CONTROL_PLANE_ENDPOINT}:6443"
networking:
  serviceSubnet: ${SERVICE_CIDR}
  podSubnet: ${POD_NETWORK_CIDR}
  dnsDomain: "cluster.local"
apiServer:
  certSANs:
  - "${CURRENT_IP}"
  - "${HOSTNAME}"
  - "127.0.0.1"
  - "localhost"
  extraArgs:
    enable-admission-plugins: NodeRestriction,ResourceQuota
    audit-log-maxage: "30"
    audit-log-maxbackup: "10"
    audit-log-maxsize: "100"
    audit-log-path: /var/log/kube-audit/audit.log
    event-ttl: "24h"
    service-node-port-range: "30000-32767"
  extraVolumes:
  - name: audit-log
    hostPath: /var/log/kube-audit
    mountPath: /var/log/kube-audit
    pathType: DirectoryOrCreate
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
    node-monitor-grace-period: "40s"
    node-monitor-period: "5s"
    cluster-cidr: "${POD_NETWORK_CIDR}"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
etcd:
  local:
    dataDir: "/var/lib/etcd"
    extraArgs:
      listen-metrics-urls: "http://0.0.0.0:2381"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
evictionHard:
  memory.available: "200Mi"
  nodefs.available: "10%"
  imagefs.available: "15%"
evictionSoft:
  memory.available: "500Mi"
  nodefs.available: "15%"
evictionSoftGracePeriod:
  memory.available: "1m"
  nodefs.available: "1m30s"
kubeReserved:
  cpu: "200m"
  memory: "500Mi"
  ephemeral-storage: "1Gi"
systemReserved:
  cpu: "200m"
  memory: "500Mi"
  ephemeral-storage: "1Gi"
maxPods: 110
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
clusterCIDR: "${POD_NETWORK_CIDR}"
mode: "ipvs"
ipvs:
  strictARP: true
EOF
        
        log_info "Initializing cluster (this may take several minutes)..."
        
        if [[ "$ha_setup" == "yes" ]]; then
            kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs | tee /root/kubeadm-init.log
        else
            kubeadm init --config=/tmp/kubeadm-config.yaml | tee /root/kubeadm-init.log
        fi
        
        # Configure kubectl for root
        mkdir -p $HOME/.kube
        cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        chown $(id -u):$(id -g) $HOME/.kube/config
        
        # Configure kubectl for regular user if exists
        if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != "root" ]; then
            USER_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
            mkdir -p "${USER_HOME}/.kube"
            cp -i /etc/kubernetes/admin.conf "${USER_HOME}/.kube/config"
            chown -R "${SUDO_USER}:${SUDO_USER}" "${USER_HOME}/.kube"
            log_info "kubectl configured for user ${SUDO_USER}"
        fi
        
        # Save join commands
        log_info "Generating join commands..."
        echo "# Generated on $(date)" > /root/join-commands.txt
        echo "" >> /root/join-commands.txt
        
        if [[ "$ha_setup" == "yes" ]]; then
            echo "# Master join command:" >> /root/join-commands.txt
            echo "sudo $(kubeadm token create --print-join-command) --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)" >> /root/join-commands.txt
            echo "" >> /root/join-commands.txt
        fi
        
        echo "# Worker join command:" >> /root/join-commands.txt
        echo "sudo $(kubeadm token create --print-join-command)" >> /root/join-commands.txt
        
        log_info "✓ Master node initialized"
        log_info "Join commands saved to /root/join-commands.txt"
        
        # Wait for node to be ready
        log_info "Waiting for node to be ready..."
        kubectl wait --for=condition=Ready node/${HOSTNAME} --timeout=60s || true
        
    else
        log_info "For additional master nodes, use the join command from the first master"
        log_info "The command should be in /root/join-commands.txt on the first master"
    fi
}

#############################################
# PHASE 5: NETWORK PLUGIN INSTALLATION
#############################################

install_network_plugin() {
    log_section "PHASE 5: Installing Network Plugin"
    
    echo ""
    echo "Select network plugin:"
    echo "1) Flannel (Simple, lightweight, recommended for development)"
    echo "2) Calico (Feature-rich, recommended for production)"
    echo "3) Cilium (eBPF-based, high performance, advanced features)"
    echo "4) Weave Net (Simple, automatic encryption)"
    echo ""
    read -p "Enter choice (1-4): " network_choice
    
    case $network_choice in
        1)
            log_info "Installing Flannel..."
            kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
            log_info "Waiting for Flannel to be ready..."
            sleep 10
            kubectl wait --for=condition=Ready pods -l app=flannel -n kube-flannel --timeout=300s || true
            ;;
        2)
            log_info "Installing Calico..."
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
            
            # Download and modify custom resources
            curl -s https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml -o /tmp/calico-custom-resources.yaml
            sed -i "s|192.168.0.0/16|${POD_NETWORK_CIDR}|g" /tmp/calico-custom-resources.yaml
            kubectl create -f /tmp/calico-custom-resources.yaml
            
            log_info "Waiting for Calico to be ready..."
            sleep 30
            kubectl wait --for=condition=Ready pods -l k8s-app=calico-node -n calico-system --timeout=300s || true
            ;;
        3)
            log_info "Installing Cilium CLI..."
            CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
            CLI_ARCH=amd64
            if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
            curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
            sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
            tar xzvf cilium-linux-${CLI_ARCH}.tar.gz
            mv cilium /usr/local/bin/
            rm -f cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
            
            log_info "Installing Cilium..."
            cilium install --version 1.15.0
            
            log_info "Waiting for Cilium to be ready..."
            cilium status --wait
            ;;
        4)
            log_info "Installing Weave Net..."
            kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
            log_info "Waiting for Weave to be ready..."
            sleep 10
            kubectl wait --for=condition=Ready pods -l name=weave-net -n kube-system --timeout=300s || true
            ;;
        *)
            log_warn "Invalid choice, installing Flannel by default..."
            kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
            ;;
    esac
    
    log_info "✓ Network plugin installation initiated"
    
    # Show pod status
    echo ""
    log_info "Network plugin pods status:"
    kubectl get pods --all-namespaces | grep -E "flannel|calico|cilium|weave"
}

#############################################
# PHASE 6: POST-INSTALLATION CONFIGURATION
#############################################

post_install_config() {
    log_section "PHASE 6: Post-Installation Configuration"
    
    # 1. Install metrics server
    log_info "Installing metrics server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for self-signed certificates
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
      {
        "op": "add",
        "path": "/spec/template/spec/containers/0/args/-",
        "value": "--kubelet-insecure-tls"
      },
      {
        "op": "add",
        "path": "/spec/template/spec/containers/0/args/-",
        "value": "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      }
    ]' 2>/dev/null || true
    
    # 2. Create local-path storage class
    log_info "Creating local-path storage class..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: local-path-storage
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-path-config
  namespace: local-path-storage
data:
  config.json: |-
    {
      "nodePathMap": [
        {
          "node": "DEFAULT_PATH_FOR_NON_LISTED_NODES",
          "paths": ["/opt/local-path-provisioner"]
        }
      ]
    }
  setup: |-
    #!/bin/sh
    set -eu
    mkdir -m 0777 -p "\$VOL_DIR"
  teardown: |-
    #!/bin/sh
    set -eu
    rm -rf "\$VOL_DIR"
EOF
    
    # Install local-path provisioner
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
    
    # 3. Configure kubectl autocompletion
    log_info "Setting up kubectl autocompletion..."
    kubectl completion bash > /etc/bash_completion.d/kubectl
    
    # Add to bashrc
    cat >> ~/.bashrc <<EOF

# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kap='kubectl apply -f'
alias kdel='kubectl delete'
alias kgpo='kubectl get pods'
alias kgno='kubectl get nodes'
alias kgsvc='kubectl get svc'
alias kging='kubectl get ingress'

# Enable kubectl autocompletion for alias
complete -F __start_kubectl k
EOF
    
    # 4. Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # 5. Create ingress-nginx namespace
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
    
    # 6. Label master node
    kubectl label node ${HOSTNAME} node-role.kubernetes.io/control-plane="" --overwrite || true
    
    # 7. Optional: Allow pods on master node (for single-node clusters)
    read -p "Allow pods to be scheduled on master node? (yes/no): " allow_master_pods
    if [[ "$allow_master_pods" == "yes" ]]; then
        kubectl taint nodes ${HOSTNAME} node-role.kubernetes.io/control-plane:NoSchedule- 2>/dev/null || true
        kubectl taint nodes ${HOSTNAME} node-role.kubernetes.io/master:NoSchedule- 2>/dev/null || true
        log_info "Master node scheduling enabled"
    fi
    
    log_info "✓ Post-installation configuration complete"
}

#############################################
# PHASE 7: CLUSTER VALIDATION
#############################################

validate_cluster() {
    log_section "PHASE 7: Cluster Validation"
    
    log_info "Checking cluster status..."
    
    # Check nodes
    echo -e "\n${GREEN}=== Nodes ===${NC}"
    kubectl get nodes -o wide
    
    # Check system pods
    echo -e "\n${GREEN}=== System Pods ===${NC}"
    kubectl get pods -n kube-system -o wide
    
    # Check cluster info
    echo -e "\n${GREEN}=== Cluster Info ===${NC}"
    kubectl cluster-info
    
    # Check component status
    echo -e "\n${GREEN}=== Component Status ===${NC}"
    kubectl get componentstatuses 2>/dev/null || kubectl get --raw='/readyz?verbose' | grep -E "ok|failed"
    
    # Create test deployment
    log_info "Creating test deployment..."
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-nginx
  template:
    metadata:
      labels:
        app: test-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: test-nginx
  namespace: default
spec:
  type: NodePort
  selector:
    app: test-nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
    
    log_info "Waiting for test deployment to be ready..."
    kubectl wait --for=condition=available --timeout=60s deployment/test-nginx || true
    
    # Check test deployment
    echo -e "\n${GREEN}=== Test Deployment ===${NC}"
    kubectl get deployment test-nginx
    kubectl get pods -l app=test-nginx
    kubectl get svc test-nginx
    
    # Test connectivity
    NODE_PORT=$(kubectl get svc test-nginx -o jsonpath='{.spec.ports[0].nodePort}')
    log_info "Test application available at: http://${CURRENT_IP}:${NODE_PORT}"
    
    # Test DNS
    echo -e "\n${GREEN}=== DNS Test ===${NC}"
    kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default || true
    
    # Cleanup test deployment
    read -p "Remove test deployment? (yes/no): " remove_test
    if [[ "$remove_test" == "yes" ]]; then
        kubectl delete deployment test-nginx
        kubectl delete svc test-nginx
        log_info "Test deployment removed"
    fi
    
    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}     CLUSTER VALIDATION COMPLETE${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    
    log_info "✓ Cluster validation complete"
}

#############################################
# HELPER FUNCTIONS
#############################################

join_worker() {
    log_section "Joining Worker Node"
    
    echo "Please run the following command on the master node to get the join command:"
    echo "  kubeadm token create --print-join-command"
    echo ""
    read -p "Paste the join command here: " join_cmd
    
    if [ -n "$join_cmd" ]; then
        log_info "Executing join command..."
        eval $join_cmd
        log_info "✓ Worker node joined to cluster"
    else
        log_error "No join command provided"
    fi
}

reset_cluster() {
    log_section "Resetting Kubernetes"
    
    log_warn "This will completely remove Kubernetes from this node!"
    log_warn "All data will be lost!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        log_info "Resetting Kubernetes..."
        
        # Reset kubeadm
        kubeadm reset -f
        
        # Clean up iptables
        iptables -F
        iptables -t nat -F
        iptables -t mangle -F
        iptables -X
        iptables -t nat -X
        iptables -t mangle -X
        
        # Clean up IPVS
        ipvsadm --clear
        
        # Remove Kubernetes directories
        rm -rf /etc/kubernetes
        rm -rf /var/lib/etcd
        rm -rf /var/lib/kubelet
        rm -rf /var/lib/dockershim
        rm -rf /var/run/kubernetes
        rm -rf /etc/cni/net.d
        rm -rf /opt/cni/bin
        rm -rf $HOME/.kube
        
        # Restart containerd
        systemctl restart containerd
        
        log_info "✓ Kubernetes reset complete"
    else
        log_info "Reset cancelled"
    fi
}

show_status() {
    log_section "Cluster Status"
    
    echo -e "\n${GREEN}=== Node Status ===${NC}"
    kubectl get nodes -o wide 2>/dev/null || echo "kubectl not configured or cluster not initialized"
    
    echo -e "\n${GREEN}=== System Services ===${NC}"
    systemctl status kubelet --no-pager | head -10
    echo ""
    systemctl status containerd --no-pager | head -10
    
    echo -e "\n${GREEN}=== Cluster Pods ===${NC}"
    kubectl get pods --all-namespaces 2>/dev/null || echo "Unable to get pod status"
    
    echo -e "\n${GREEN}=== Resource Usage ===${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not installed or not ready"
}

install_dashboard() {
    log_section "Installing Kubernetes Dashboard"
    
    # Install dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Create admin user
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
    
    # Get token
    log_info "Creating access token..."
    TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=87600h)
    
    echo ""
    echo "Dashboard installed successfully!"
    echo "To access the dashboard, run:"
    echo "  kubectl proxy"
    echo ""
    echo "Then open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    echo "Token for login:"
    echo "$TOKEN"
    echo ""
    echo "Token saved to: /root/dashboard-token.txt"
    echo "$TOKEN" > /root/dashboard-token.txt
}

#############################################
# MAIN MENU
#############################################

main_menu() {
    clear
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
     Ubuntu 22.04 Kubernetes Setup Script v${SCRIPT_VERSION}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

Select an option:

  ${GREEN}QUICK INSTALLATION${NC}
  1) Complete Master Setup (All phases)
  2) Complete Worker Setup
  
  ${YELLOW}INDIVIDUAL PHASES${NC}
  3) Phase 0: Install Prerequisites
  4) Phase 1: System Preparation
  5) Phase 2: Install Containerd
  6) Phase 3: Install Kubernetes
  7) Phase 4: Initialize Master
  8) Phase 5: Install Network Plugin
  9) Phase 6: Post-Install Configuration
  
  ${BLUE}UTILITIES${NC}
  10) Join Worker Node
  11) Show Cluster Status
  12) Validate Cluster
  13) Install Dashboard
  14) Reset Cluster
  
  0) Exit

EOF
    read -p "Enter choice [0-14]: " choice
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    check_root
    
    # Create log file
    touch "${LOG_FILE}"
    
    while true; do
        main_menu
        
        case $choice in
            1)
                backup_system
                install_prerequisites
                prepare_system
                install_containerd
                install_kubernetes
                init_master
                install_network_plugin
                post_install_config
                validate_cluster
                ;;
            2)
                backup_system
                install_prerequisites
                prepare_system
                install_containerd
                install_kubernetes
                join_worker
                ;;
            3) install_prerequisites ;;
            4) prepare_system ;;
            5) install_containerd ;;
            6) install_kubernetes ;;
            7) init_master ;;
            8) install_network_plugin ;;
            9) post_install_config ;;
            10) join_worker ;;
            11) show_status ;;
            12) validate_cluster ;;
            13) install_dashboard ;;
            14) reset_cluster ;;
            0) 
                log_info "Exiting..."
                exit 0 
                ;;
            *)
                log_error "Invalid option"
                sleep 2
                ;;
        esac
        
        if [ "$choice" != "0" ]; then
            echo ""
            echo -e "${YELLOW}Press Enter to continue...${NC}"
            read
        fi
    done
}

# Trap for cleanup on exit
trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 1' INT TERM

# Run main function
main "$@"

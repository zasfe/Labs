#!/bin/bash

#############################################
# Rocky Linux 9.5 Kubernetes Cluster Setup Script
# Purpose: Complete K8s cluster deployment for Rocky Linux 9.5 on KVM
# Version: 2.0
#############################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_VERSION="2.0"
LOG_FILE="/var/log/k8s-setup-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/root/k8s-backup-$(date +%Y%m%d-%H%M%S)"

# Cluster Configuration
K8S_VERSION="1.29.0"
POD_NETWORK_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
CLUSTER_NAME="rocky-cluster"

# Node Configuration (자동 감지 또는 수동 설정)
CURRENT_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
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

# Backup current configuration
backup_system() {
    log_section "Creating System Backup"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup important files
    cp -r /etc/sysctl.d "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /etc/modules-load.d "${BACKUP_DIR}/" 2>/dev/null || true
    cp /etc/fstab "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /etc/yum.repos.d "${BACKUP_DIR}/" 2>/dev/null || true
    
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
    sed -i '/swap/d' /etc/fstab
    
    # Verify swap is disabled
    if [ "$(free | awk '/^Swap:/{print $2}')" = "0" ]; then
        log_info "✓ Swap disabled successfully"
    else
        log_error "Failed to disable swap"
        exit 1
    fi
    
    # 2. Set SELinux to permissive
    log_info "Configuring SELinux..."
    setenforce 0 || true
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    
    # 3. Configure required kernel modules
    log_info "Loading required kernel modules..."
    cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
    
    # Load modules immediately
    modprobe overlay
    modprobe br_netfilter
    modprobe ip_vs
    modprobe ip_vs_rr
    modprobe ip_vs_wrr
    modprobe ip_vs_sh
    modprobe nf_conntrack
    
    # 4. Configure sysctl parameters
    log_info "Configuring kernel parameters..."
    cat > /etc/sysctl.d/99-kubernetes.conf <<EOF
# Network settings for Kubernetes
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

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

# Memory settings
vm.swappiness = 0
vm.overcommit_memory = 1
vm.panic_on_oom = 0
vm.max_map_count = 262144

# Connection tracking (increase for large clusters)
net.netfilter.nf_conntrack_max = 1000000
net.nf_conntrack_max = 1000000
EOF
    
    sysctl --system > /dev/null 2>&1
    
    # 5. Configure firewall for Kubernetes
    log_info "Configuring firewall..."
    
    # Master node ports
    firewall-cmd --permanent --add-port=6443/tcp --zone=public
    firewall-cmd --permanent --add-port=2379-2380/tcp --zone=public
    firewall-cmd --permanent --add-port=10250-10252/tcp --zone=public
    firewall-cmd --permanent --add-port=10255/tcp --zone=public
    
    # Worker node ports
    firewall-cmd --permanent --add-port=30000-32767/tcp --zone=public
    
    # Flannel VXLAN
    firewall-cmd --permanent --add-port=8472/udp --zone=public
    
    # Calico (alternative)
    firewall-cmd --permanent --add-port=179/tcp --zone=public
    firewall-cmd --permanent --add-port=4789/udp --zone=public
    
    # Allow pod network
    firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=10.244.0.0/16 accept' --zone=public
    firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=10.96.0.0/12 accept' --zone=public
    
    firewall-cmd --reload
    
    log_info "✓ System preparation complete"
}

#############################################
# PHASE 2: CONTAINER RUNTIME INSTALLATION
#############################################

install_containerd() {
    log_section "PHASE 2: Installing Containerd"
    
    # 1. Install required packages
    log_info "Installing prerequisites..."
    dnf install -y yum-utils device-mapper-persistent-data lvm2
    
    # 2. Add Docker repository (for containerd)
    log_info "Adding container repository..."
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # 3. Install containerd
    log_info "Installing containerd..."
    dnf install -y containerd.io
    
    # 4. Configure containerd
    log_info "Configuring containerd..."
    mkdir -p /etc/containerd
    containerd config default > /etc/containerd/config.toml
    
    # Enable SystemdCgroup
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    
    # Configure registry mirrors (optional)
    cat >> /etc/containerd/config.toml <<EOF

[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://registry-1.docker.io"]
EOF
    
    # 5. Start and enable containerd
    systemctl daemon-reload
    systemctl enable --now containerd
    
    # Verify containerd is running
    if systemctl is-active containerd >/dev/null 2>&1; then
        log_info "✓ Containerd installed and running"
    else
        log_error "Containerd installation failed"
        exit 1
    fi
}

#############################################
# PHASE 3: KUBERNETES INSTALLATION
#############################################

install_kubernetes() {
    log_section "PHASE 3: Installing Kubernetes"
    
    # 1. Add Kubernetes repository
    log_info "Adding Kubernetes repository..."
    cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
    
    # 2. Install Kubernetes components
    log_info "Installing Kubernetes components..."
    dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    
    # 3. Configure kubelet
    log_info "Configuring kubelet..."
    cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
    
    # 4. Enable kubelet
    systemctl enable --now kubelet
    
    log_info "✓ Kubernetes components installed"
}

#############################################
# PHASE 4: CLUSTER INITIALIZATION
#############################################

init_master() {
    log_section "PHASE 4: Initializing Kubernetes Master"
    
    # Check if this is the first master
    read -p "Is this the FIRST master node? (yes/no): " is_first_master
    
    if [[ "$is_first_master" == "yes" ]]; then
        # Create kubeadm configuration
        cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${CURRENT_IP}
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v${K8S_VERSION}
clusterName: ${CLUSTER_NAME}
controlPlaneEndpoint: "${CURRENT_IP}:6443"
networking:
  serviceSubnet: ${SERVICE_CIDR}
  podSubnet: ${POD_NETWORK_CIDR}
  dnsDomain: "cluster.local"
apiServer:
  extraArgs:
    enable-admission-plugins: NodeRestriction,ResourceQuota
    audit-log-maxage: "30"
    audit-log-maxbackup: "10"
    audit-log-maxsize: "100"
    audit-log-path: /var/log/kube-audit/audit.log
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
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
etcd:
  local:
    dataDir: "/var/lib/etcd"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
evictionHard:
  memory.available: "200Mi"
  nodefs.available: "10%"
  imagefs.available: "15%"
kubeReserved:
  cpu: "200m"
  memory: "500Mi"
systemReserved:
  cpu: "200m"
  memory: "500Mi"
EOF
        
        log_info "Initializing cluster..."
        kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs | tee /root/kubeadm-init.log
        
        # Configure kubectl for root
        mkdir -p $HOME/.kube
        cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        chown $(id -u):$(id -g) $HOME/.kube/config
        
        # Save join commands
        log_info "Generating join commands..."
        echo "# Master join command:" > /root/join-commands.txt
        kubeadm token create --print-join-command --certificate-key $(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1) >> /root/join-commands.txt
        echo "" >> /root/join-commands.txt
        echo "# Worker join command:" >> /root/join-commands.txt
        kubeadm token create --print-join-command >> /root/join-commands.txt
        
        log_info "✓ Master node initialized"
        log_info "Join commands saved to /root/join-commands.txt"
    else
        log_info "For additional master nodes, use the join command from the first master"
    fi
}

#############################################
# PHASE 5: NETWORK PLUGIN INSTALLATION
#############################################

install_network_plugin() {
    log_section "PHASE 5: Installing Network Plugin"
    
    echo "Select network plugin:"
    echo "1) Flannel (Simple, recommended for small clusters)"
    echo "2) Calico (Advanced features, recommended for production)"
    echo "3) Cilium (eBPF-based, high performance)"
    read -p "Enter choice (1-3): " network_choice
    
    case $network_choice in
        1)
            log_info "Installing Flannel..."
            kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
            ;;
        2)
            log_info "Installing Calico..."
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
            curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml -O
            sed -i "s|192.168.0.0/16|${POD_NETWORK_CIDR}|g" custom-resources.yaml
            kubectl create -f custom-resources.yaml
            rm -f custom-resources.yaml
            ;;
        3)
            log_info "Installing Cilium..."
            curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
            tar xzvf cilium-linux-amd64.tar.gz
            mv cilium /usr/local/bin/
            cilium install --version 1.14.0
            rm -f cilium-linux-amd64.tar.gz
            ;;
        *)
            log_warn "Invalid choice, installing Flannel by default..."
            kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
            ;;
    esac
    
    log_info "✓ Network plugin installation initiated"
}

#############################################
# PHASE 6: POST-INSTALLATION CONFIGURATION
#############################################

post_install_config() {
    log_section "PHASE 6: Post-Installation Configuration"
    
    # 1. Install metrics server
    log_info "Installing metrics server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for self-signed certificates (if needed)
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
      {
        "op": "add",
        "path": "/spec/template/spec/containers/0/args/-",
        "value": "--kubelet-insecure-tls"
      }
    ]' 2>/dev/null || true
    
    # 2. Create default storage class (local-path)
    log_info "Creating local storage class..."
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
    
    # 3. Configure kubectl autocompletion
    log_info "Setting up kubectl autocompletion..."
    dnf install -y bash-completion
    kubectl completion bash > /etc/bash_completion.d/kubectl
    source /etc/bash_completion.d/kubectl
    
    # 4. Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # 5. Label nodes
    kubectl label node ${HOSTNAME} node-role.kubernetes.io/master="" --overwrite
    
    log_info "✓ Post-installation configuration complete"
}

#############################################
# PHASE 7: CLUSTER VALIDATION
#############################################

validate_cluster() {
    log_section "PHASE 7: Cluster Validation"
    
    log_info "Checking cluster status..."
    
    # Check nodes
    echo -e "\n${GREEN}Nodes:${NC}"
    kubectl get nodes -o wide
    
    # Check system pods
    echo -e "\n${GREEN}System Pods:${NC}"
    kubectl get pods -n kube-system
    
    # Check cluster info
    echo -e "\n${GREEN}Cluster Info:${NC}"
    kubectl cluster-info
    
    # Create test deployment
    log_info "Creating test deployment..."
    kubectl create deployment test-nginx --image=nginx:alpine --replicas=2
    kubectl expose deployment test-nginx --port=80 --type=NodePort
    
    sleep 10
    
    # Check test deployment
    echo -e "\n${GREEN}Test Deployment:${NC}"
    kubectl get deployment test-nginx
    kubectl get pods -l app=test-nginx
    kubectl get svc test-nginx
    
    # Cleanup test deployment
    read -p "Remove test deployment? (yes/no): " remove_test
    if [[ "$remove_test" == "yes" ]]; then
        kubectl delete deployment test-nginx
        kubectl delete svc test-nginx
    fi
    
    log_info "✓ Cluster validation complete"
}

#############################################
# HELPER FUNCTIONS
#############################################

join_worker() {
    log_section "Joining Worker Node"
    
    read -p "Enter the kubeadm join command: " join_cmd
    eval $join_cmd
    
    log_info "✓ Worker node joined to cluster"
}

reset_cluster() {
    log_section "Resetting Kubernetes"
    
    log_warn "This will remove all Kubernetes configuration!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        kubeadm reset -f
        rm -rf /etc/cni/net.d
        rm -rf $HOME/.kube
        rm -rf /etc/kubernetes
        rm -rf /var/lib/etcd
        
        # Clean iptables
        iptables -F
        iptables -t nat -F
        iptables -t mangle -F
        iptables -X
        
        log_info "✓ Kubernetes reset complete"
    fi
}

show_status() {
    log_section "Cluster Status"
    
    echo -e "\n${GREEN}=== Node Status ===${NC}"
    kubectl get nodes -o wide 2>/dev/null || echo "Cluster not initialized"
    
    echo -e "\n${GREEN}=== Pod Status ===${NC}"
    kubectl get pods --all-namespaces 2>/dev/null || echo "No pods found"
    
    echo -e "\n${GREEN}=== Service Status ===${NC}"
    systemctl status kubelet --no-pager
    systemctl status containerd --no-pager
}

#############################################
# MAIN MENU
#############################################

main_menu() {
    clear
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
     Rocky Linux 9.5 Kubernetes Setup Script v${SCRIPT_VERSION}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

Select an option:

  ${GREEN}INSTALLATION${NC}
  1) Complete Master Setup (All phases)
  2) Complete Worker Setup
  
  ${YELLOW}INDIVIDUAL PHASES${NC}
  3) Phase 1: System Preparation
  4) Phase 2: Install Containerd
  5) Phase 3: Install Kubernetes
  6) Phase 4: Initialize Master
  7) Phase 5: Install Network Plugin
  8) Phase 6: Post-Install Configuration
  
  ${BLUE}UTILITIES${NC}
  9) Join Worker Node
  10) Show Cluster Status
  11) Validate Cluster
  12) Reset Cluster
  
  0) Exit

EOF
    read -p "Enter choice [0-12]: " choice
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    check_root
    
    while true; do
        main_menu
        
        case $choice in
            1)
                backup_system
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
                prepare_system
                install_containerd
                install_kubernetes
                join_worker
                ;;
            3) prepare_system ;;
            4) install_containerd ;;
            5) install_kubernetes ;;
            6) init_master ;;
            7) install_network_plugin ;;
            8) post_install_config ;;
            9) join_worker ;;
            10) show_status ;;
            11) validate_cluster ;;
            12) reset_cluster ;;
            0) 
                log_info "Exiting..."
                exit 0 
                ;;
            *)
                log_error "Invalid option"
                sleep 2
                ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Run main function
main "$@"

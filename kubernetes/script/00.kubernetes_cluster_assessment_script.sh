#!/bin/bash

#############################################
# Kubernetes Cluster Assessment Script
# Purpose: Collect comprehensive system information for K8s deployment planning
# Version: 1.0
#############################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="/tmp/k8s_assessment_${TIMESTAMP}"
REPORT_FILE="${OUTPUT_DIR}/assessment_report.txt"
JSON_FILE="${OUTPUT_DIR}/assessment.json"
PERF_TEST_DURATION=10

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} \$1" | tee -a "${REPORT_FILE}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} \$1" | tee -a "${REPORT_FILE}"; }
log_error() { echo -e "${RED}[ERROR]${NC} \$1" | tee -a "${REPORT_FILE}"; }
log_section() { echo -e "\n${BLUE}═══════════════════════════════════════════${NC}" | tee -a "${REPORT_FILE}"; echo -e "${BLUE}▶ \$1${NC}" | tee -a "${REPORT_FILE}"; echo -e "${BLUE}═══════════════════════════════════════════${NC}" | tee -a "${REPORT_FILE}"; }

# Check if command exists
command_exists() {
    command -v "\$1" >/dev/null 2>&1
}

# Safe command execution
safe_exec() {
    local cmd="\$1"
    local output_file="\$2"
    local description="${3:-}"
    
    if [ -n "${description}" ]; then
        echo -e "\n### ${description}" >> "${output_file}"
    fi
    echo "# Command: ${cmd}" >> "${output_file}"
    echo "# Timestamp: $(date)" >> "${output_file}"
    echo "---" >> "${output_file}"
    
    if eval "${cmd}" >> "${output_file}" 2>&1; then
        return 0
    else
        echo "Error executing: ${cmd}" >> "${output_file}"
        return 1
    fi
    echo "" >> "${output_file}"
}

#############################################
# MAIN ASSESSMENT START
#############################################

cat << EOF | tee "${REPORT_FILE}"
═══════════════════════════════════════════════════════════════════
       KUBERNETES DEPLOYMENT ASSESSMENT REPORT
═══════════════════════════════════════════════════════════════════
Date: $(date)
Hostname: $(hostname)
User: $(whoami)
═══════════════════════════════════════════════════════════════════
EOF

#############################################
# 1. BASIC SYSTEM INFORMATION
#############################################
log_section "1. BASIC SYSTEM INFORMATION"

BASIC_INFO_FILE="${OUTPUT_DIR}/01_basic_system.txt"
{
    echo "═══ System Identification ═══"
    safe_exec "hostname -f" "${BASIC_INFO_FILE}" "Hostname"
    safe_exec "uname -a" "${BASIC_INFO_FILE}" "Kernel Version"
    safe_exec "cat /etc/os-release" "${BASIC_INFO_FILE}" "OS Release"
    safe_exec "lsb_release -a 2>/dev/null || echo 'lsb_release not available'" "${BASIC_INFO_FILE}" "LSB Release"
    safe_exec "hostnamectl 2>/dev/null || echo 'hostnamectl not available'" "${BASIC_INFO_FILE}" "Host Details"
    safe_exec "uptime" "${BASIC_INFO_FILE}" "Uptime"
    safe_exec "date" "${BASIC_INFO_FILE}" "Current Date/Time"
    safe_exec "timedatectl status 2>/dev/null || echo 'timedatectl not available'" "${BASIC_INFO_FILE}" "Time Configuration"
} &

#############################################
# 2. VIRTUALIZATION DETECTION
#############################################
log_section "2. VIRTUALIZATION ENVIRONMENT"

VIRT_INFO_FILE="${OUTPUT_DIR}/02_virtualization.txt"
{
    echo "═══ Virtualization Detection ═══"
    safe_exec "systemd-detect-virt 2>/dev/null || echo 'Not detected'" "${VIRT_INFO_FILE}" "Systemd Detection"
    safe_exec "dmidecode -s system-manufacturer 2>/dev/null || echo 'dmidecode failed (need sudo?)'" "${VIRT_INFO_FILE}" "System Manufacturer"
    safe_exec "dmidecode -s system-product-name 2>/dev/null || echo 'dmidecode failed'" "${VIRT_INFO_FILE}" "System Product"
    safe_exec "cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'DMI not available'" "${VIRT_INFO_FILE}" "Product Name"
    safe_exec "cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'DMI not available'" "${VIRT_INFO_FILE}" "System Vendor"
    safe_exec "cat /sys/hypervisor/type 2>/dev/null || echo 'Hypervisor info not available'" "${VIRT_INFO_FILE}" "Hypervisor Type"
    safe_exec "lscpu | grep -i 'hypervisor\\|virtualization' || echo 'No virtualization info in lscpu'" "${VIRT_INFO_FILE}" "CPU Virtualization"
    safe_exec "grep -E 'vmx|svm' /proc/cpuinfo | head -5 || echo 'No virtualization extensions found'" "${VIRT_INFO_FILE}" "CPU Virtualization Extensions"
} &

#############################################
# 3. CLOUD PROVIDER DETECTION
#############################################
log_section "3. CLOUD PROVIDER DETECTION"

CLOUD_INFO_FILE="${OUTPUT_DIR}/03_cloud_provider.txt"
{
    echo "═══ Cloud Provider Metadata ═══"
    
    # AWS
    echo -e "\n### AWS Metadata Check" >> "${CLOUD_INFO_FILE}"
    if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; then
        echo "AWS detected" >> "${CLOUD_INFO_FILE}"
        curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null >> "${CLOUD_INFO_FILE}"
        curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null >> "${CLOUD_INFO_FILE}"
    else
        echo "AWS metadata not accessible" >> "${CLOUD_INFO_FILE}"
    fi
    
    # GCP
    echo -e "\n### GCP Metadata Check" >> "${CLOUD_INFO_FILE}"
    if curl -s --max-time 2 -H "Metadata-Flavor: Google" http://metadata.google.internal/ >/dev/null 2>&1; then
        echo "GCP detected" >> "${CLOUD_INFO_FILE}"
        curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/machine-type 2>/dev/null >> "${CLOUD_INFO_FILE}"
    else
        echo "GCP metadata not accessible" >> "${CLOUD_INFO_FILE}"
    fi
    
    # Azure
    echo -e "\n### Azure Metadata Check" >> "${CLOUD_INFO_FILE}"
    if curl -s --max-time 2 -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" >/dev/null 2>&1; then
        echo "Azure detected" >> "${CLOUD_INFO_FILE}"
        curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 2>/dev/null | python3 -m json.tool 2>/dev/null >> "${CLOUD_INFO_FILE}" || echo "JSON parse failed" >> "${CLOUD_INFO_FILE}"
    else
        echo "Azure metadata not accessible" >> "${CLOUD_INFO_FILE}"
    fi
} &

#############################################
# 4. CPU INFORMATION
#############################################
log_section "4. CPU RESOURCES"

CPU_INFO_FILE="${OUTPUT_DIR}/04_cpu.txt"
{
    echo "═══ CPU Configuration ═══"
    safe_exec "lscpu" "${CPU_INFO_FILE}" "CPU Architecture"
    safe_exec "nproc --all" "${CPU_INFO_FILE}" "Total CPU Cores"
    safe_exec "cat /proc/cpuinfo | grep -E 'processor|vendor_id|model name|cpu MHz|cache size|cpu cores' | head -20" "${CPU_INFO_FILE}" "CPU Details"
    
    echo "═══ CPU Limits (cgroups) ═══" >> "${CPU_INFO_FILE}"
    safe_exec "cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || echo 'No CPU quota'" "${CPU_INFO_FILE}" "CPU Quota"
    safe_exec "cat /sys/fs/cgroup/cpu/cpu.cfs_period_us 2>/dev/null || echo 'No CPU period'" "${CPU_INFO_FILE}" "CPU Period"
    safe_exec "cat /sys/fs/cgroup/cpu/cpu.shares 2>/dev/null || echo 'No CPU shares'" "${CPU_INFO_FILE}" "CPU Shares"
    
    # cgroups v2
    safe_exec "cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo 'cgroups v2 cpu.max not found'" "${CPU_INFO_FILE}" "CPU Max (cgroups v2)"
} &

#############################################
# 5. MEMORY INFORMATION
#############################################
log_section "5. MEMORY RESOURCES"

MEM_INFO_FILE="${OUTPUT_DIR}/05_memory.txt"
{
    echo "═══ Memory Configuration ═══"
    safe_exec "free -h" "${MEM_INFO_FILE}" "Memory Summary"
    safe_exec "cat /proc/meminfo | head -20" "${MEM_INFO_FILE}" "Memory Details"
    safe_exec "vmstat -s" "${MEM_INFO_FILE}" "VM Statistics"
    
    echo "═══ Memory Limits (cgroups) ═══" >> "${MEM_INFO_FILE}"
    safe_exec "cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo 'No memory limit'" "${MEM_INFO_FILE}" "Memory Limit"
    safe_exec "cat /sys/fs/cgroup/memory/memory.stat 2>/dev/null | head -10 || echo 'No memory stats'" "${MEM_INFO_FILE}" "Memory Stats"
    
    # cgroups v2
    safe_exec "cat /sys/fs/cgroup/memory.max 2>/dev/null || echo 'cgroups v2 memory.max not found'" "${MEM_INFO_FILE}" "Memory Max (cgroups v2)"
    safe_exec "cat /sys/fs/cgroup/memory.current 2>/dev/null || echo 'cgroups v2 memory.current not found'" "${MEM_INFO_FILE}" "Memory Current (cgroups v2)"
} &

#############################################
# 6. STORAGE INFORMATION
#############################################
log_section "6. STORAGE CONFIGURATION"

STORAGE_INFO_FILE="${OUTPUT_DIR}/06_storage.txt"
{
    echo "═══ Block Devices ═══"
    safe_exec "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA,DISC-GRAN,MODEL" "${STORAGE_INFO_FILE}" "Block Device List"
    safe_exec "df -Th" "${STORAGE_INFO_FILE}" "Filesystem Usage"
    safe_exec "findmnt -D" "${STORAGE_INFO_FILE}" "Mount Points"
    safe_exec "cat /proc/mounts" "${STORAGE_INFO_FILE}" "Current Mounts"
    
    echo "═══ Storage Performance Test ═══" >> "${STORAGE_INFO_FILE}"
    # Quick write test
    echo "Performing quick I/O test..." >> "${STORAGE_INFO_FILE}"
    TEMP_FILE="/tmp/io_test_$$"
    dd if=/dev/zero of="${TEMP_FILE}" bs=1M count=100 oflag=direct 2>&1 | grep -E 'copied|MB/s' >> "${STORAGE_INFO_FILE}" || echo "Write test failed" >> "${STORAGE_INFO_FILE}"
    rm -f "${TEMP_FILE}"
    
    # Check for LVM
    echo "═══ LVM Configuration ═══" >> "${STORAGE_INFO_FILE}"
    safe_exec "vgs 2>/dev/null || echo 'No LVM volume groups'" "${STORAGE_INFO_FILE}" "Volume Groups"
    safe_exec "lvs 2>/dev/null || echo 'No LVM logical volumes'" "${STORAGE_INFO_FILE}" "Logical Volumes"
} &

#############################################
# 7. NETWORK CONFIGURATION
#############################################
log_section "7. NETWORK CONFIGURATION"

NET_INFO_FILE="${OUTPUT_DIR}/07_network.txt"
{
    echo "═══ Network Interfaces ═══"
    safe_exec "ip addr show" "${NET_INFO_FILE}" "IP Addresses"
    safe_exec "ip link show" "${NET_INFO_FILE}" "Network Links"
    safe_exec "ip route show" "${NET_INFO_FILE}" "Routing Table"
    safe_exec "cat /sys/class/net/*/mtu" "${NET_INFO_FILE}" "MTU Settings"
    
    echo "═══ Network Performance ═══" >> "${NET_INFO_FILE}"
    for iface in $(ls /sys/class/net/ | grep -v lo); do
        echo "Interface: $iface" >> "${NET_INFO_FILE}"
        safe_exec "ethtool $iface 2>/dev/null | grep -E 'Speed|Duplex|Port|Link detected' || echo 'ethtool not available or permission denied'" "${NET_INFO_FILE}"
    done
    
    echo "═══ DNS Configuration ═══" >> "${NET_INFO_FILE}"
    safe_exec "cat /etc/resolv.conf" "${NET_INFO_FILE}" "Resolver Configuration"
    safe_exec "systemd-resolve --status 2>/dev/null | head -20 || echo 'systemd-resolved not available'" "${NET_INFO_FILE}" "Systemd Resolver"
    
    echo "═══ Firewall Rules ═══" >> "${NET_INFO_FILE}"
    safe_exec "iptables -L -n -v 2>/dev/null || echo 'iptables not accessible (need sudo?)'" "${NET_INFO_FILE}" "Filter Table"
    safe_exec "iptables -t nat -L -n -v 2>/dev/null || echo 'nat table not accessible'" "${NET_INFO_FILE}" "NAT Table"
} &

#############################################
# 8. KERNEL PARAMETERS
#############################################
log_section "8. KERNEL CONFIGURATION"

KERNEL_INFO_FILE="${OUTPUT_DIR}/08_kernel.txt"
{
    echo "═══ Kernel Modules ═══"
    safe_exec "lsmod | grep -E 'overlay|br_netfilter|ip_vs|nf_conntrack' || echo 'Key modules not found'" "${KERNEL_INFO_FILE}" "Container-related Modules"
    
    echo "═══ Important Kernel Parameters ═══" >> "${KERNEL_INFO_FILE}"
    for param in net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables \
                 vm.swappiness vm.max_map_count fs.file-max fs.inotify.max_user_instances \
                 kernel.pid_max net.core.somaxconn net.netfilter.nf_conntrack_max; do
        value=$(sysctl -n $param 2>/dev/null || echo "not set")
        echo "$param = $value" >> "${KERNEL_INFO_FILE}"
    done
    
    echo "═══ Security Features ═══" >> "${KERNEL_INFO_FILE}"
    safe_exec "sestatus 2>/dev/null || echo 'SELinux not found'" "${KERNEL_INFO_FILE}" "SELinux Status"
    safe_exec "aa-status 2>/dev/null || echo 'AppArmor not found'" "${KERNEL_INFO_FILE}" "AppArmor Status"
    safe_exec "grep Seccomp /proc/self/status" "${KERNEL_INFO_FILE}" "Seccomp Status"
} &

#############################################
# 9. CONTAINER RUNTIME CHECK
#############################################
log_section "9. CONTAINER RUNTIME"

CONTAINER_INFO_FILE="${OUTPUT_DIR}/09_container.txt"
{
    echo "═══ Container Runtime Detection ═══"
    
    # Docker
    if command_exists docker; then
        echo "Docker found" >> "${CONTAINER_INFO_FILE}"
        safe_exec "docker version" "${CONTAINER_INFO_FILE}" "Docker Version"
        safe_exec "docker info 2>/dev/null | head -30 || echo 'Docker daemon not accessible'" "${CONTAINER_INFO_FILE}" "Docker Info"
    else
        echo "Docker not found" >> "${CONTAINER_INFO_FILE}"
    fi
    
    # Containerd
    if command_exists containerd; then
        echo "Containerd found" >> "${CONTAINER_INFO_FILE}"
        safe_exec "containerd --version" "${CONTAINER_INFO_FILE}" "Containerd Version"
        safe_exec "ctr version 2>/dev/null || echo 'ctr not accessible'" "${CONTAINER_INFO_FILE}" "CTR Version"
    else
        echo "Containerd not found" >> "${CONTAINER_INFO_FILE}"
    fi
    
    # Podman
    if command_exists podman; then
        echo "Podman found" >> "${CONTAINER_INFO_FILE}"
        safe_exec "podman version" "${CONTAINER_INFO_FILE}" "Podman Version"
    else
        echo "Podman not found" >> "${CONTAINER_INFO_FILE}"
    fi
    
    # CRI-O
    if command_exists crio; then
        echo "CRI-O found" >> "${CONTAINER_INFO_FILE}"
        safe_exec "crio version" "${CONTAINER_INFO_FILE}" "CRI-O Version"
    else
        echo "CRI-O not found" >> "${CONTAINER_INFO_FILE}"
    fi
} &

#############################################
# 10. EXISTING KUBERNETES CHECK
#############################################
log_section "10. EXISTING KUBERNETES"

K8S_INFO_FILE="${OUTPUT_DIR}/10_kubernetes.txt"
{
    echo "═══ Kubernetes Components Check ═══"
    
    # kubectl
    if command_exists kubectl; then
        echo "kubectl found" >> "${K8S_INFO_FILE}"
        safe_exec "kubectl version --client" "${K8S_INFO_FILE}" "kubectl Version"
        safe_exec "kubectl config current-context 2>/dev/null || echo 'No context set'" "${K8S_INFO_FILE}" "Current Context"
    else
        echo "kubectl not found" >> "${K8S_INFO_FILE}"
    fi
    
    # kubeadm
    if command_exists kubeadm; then
        echo "kubeadm found" >> "${K8S_INFO_FILE}"
        safe_exec "kubeadm version" "${K8S_INFO_FILE}" "kubeadm Version"
    else
        echo "kubeadm not found" >> "${K8S_INFO_FILE}"
    fi
    
    # kubelet
    if command_exists kubelet; then
        echo "kubelet found" >> "${K8S_INFO_FILE}"
        safe_exec "kubelet --version" "${K8S_INFO_FILE}" "kubelet Version"
    else
        echo "kubelet not found" >> "${K8S_INFO_FILE}"
    fi
    
    # Check for running k8s processes
    safe_exec "ps aux | grep -E 'kube-|etcd' | grep -v grep || echo 'No Kubernetes processes found'" "${K8S_INFO_FILE}" "Running Kubernetes Processes"
} &

#############################################
# 11. PORT AVAILABILITY
#############################################
log_section "11. PORT AVAILABILITY"

PORT_INFO_FILE="${OUTPUT_DIR}/11_ports.txt"
{
    echo "═══ Port Usage ═══"
    safe_exec "netstat -tulpn 2>/dev/null || ss -tulpn" "${PORT_INFO_FILE}" "Listening Ports"
    
    echo -e "\n═══ Kubernetes Required Ports Check ═══" >> "${PORT_INFO_FILE}"
    K8S_PORTS="6443 2379 2380 10250 10251 10252 10255 30000-32767"
    for port in 6443 2379 2380 10250 10251 10252 10255; do
        if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln | grep -q ":$port "; then
            echo "Port $port: IN USE" >> "${PORT_INFO_FILE}"
        else
            echo "Port $port: Available" >> "${PORT_INFO_FILE}"
        fi
    done
} &

#############################################
# 12. SYSTEM LIMITS
#############################################
log_section "12. SYSTEM LIMITS"

LIMITS_INFO_FILE="${OUTPUT_DIR}/12_limits.txt"
{
    echo "═══ System Limits ═══"
    safe_exec "ulimit -a" "${LIMITS_INFO_FILE}" "User Limits"
    safe_exec "cat /proc/sys/fs/file-max" "${LIMITS_INFO_FILE}" "Max File Descriptors"
    safe_exec "cat /proc/sys/kernel/pid_max" "${LIMITS_INFO_FILE}" "Max PIDs"
    safe_exec "cat /etc/security/limits.conf | grep -v '^#' | grep -v '^$'" "${LIMITS_INFO_FILE}" "Security Limits"
} &

#############################################
# 13. PACKAGE INFORMATION
#############################################
log_section "13. PACKAGE MANAGEMENT"

PKG_INFO_FILE="${OUTPUT_DIR}/13_packages.txt"
{
    echo "═══ Package Manager Detection ═══"
    
    if command_exists apt; then
        echo "APT (Debian/Ubuntu) detected" >> "${PKG_INFO_FILE}"
        safe_exec "apt list --installed 2>/dev/null | grep -E 'docker|container|kube' | head -20" "${PKG_INFO_FILE}" "Container-related Packages"
    elif command_exists yum; then
        echo "YUM (RHEL/CentOS) detected" >> "${PKG_INFO_FILE}"
        safe_exec "yum list installed 2>/dev/null | grep -E 'docker|container|kube' | head -20" "${PKG_INFO_FILE}" "Container-related Packages"
    elif command_exists dnf; then
        echo "DNF (Fedora) detected" >> "${PKG_INFO_FILE}"
        safe_exec "dnf list installed 2>/dev/null | grep -E 'docker|container|kube' | head -20" "${PKG_INFO_FILE}" "Container-related Packages"
    fi
} &

#############################################
# 14. PERFORMANCE METRICS
#############################################
log_section "14. PERFORMANCE BASELINE"

PERF_INFO_FILE="${OUTPUT_DIR}/14_performance.txt"
{
    echo "═══ Current Performance Metrics ═══"
    safe_exec "top -b -n 1 | head -20" "${PERF_INFO_FILE}" "Process Statistics"
    safe_exec "vmstat 1 5" "${PERF_INFO_FILE}" "VM Statistics (5 samples)"
    safe_exec "iostat -x 1 5 2>/dev/null || echo 'iostat not available'" "${PERF_INFO_FILE}" "IO Statistics"
    
    if command_exists sar; then
        safe_exec "sar -u 1 5" "${PERF_INFO_FILE}" "CPU Usage"
        safe_exec "sar -r 1 5" "${PERF_INFO_FILE}" "Memory Usage"
    else
        echo "sar not available for detailed metrics" >> "${PERF_INFO_FILE}"
    fi
} &

#############################################
# 15. SECURITY AND PERMISSIONS
#############################################
log_section "15. SECURITY CONTEXT"

SEC_INFO_FILE="${OUTPUT_DIR}/15_security.txt"
{
    echo "═══ User and Permission Info ═══"
    safe_exec "id" "${SEC_INFO_FILE}" "Current User"
    safe_exec "groups" "${SEC_INFO_FILE}" "User Groups"
    safe_exec "sudo -l 2>/dev/null || echo 'sudo not available or not configured'" "${SEC_INFO_FILE}" "Sudo Permissions"
    
    echo "═══ Capability Check ═══" >> "${SEC_INFO_FILE}"
    safe_exec "capsh --print 2>/dev/null || echo 'capsh not available'" "${SEC_INFO_FILE}" "Process Capabilities"
} &

# Wait for all background jobs
wait

#############################################
# GENERATE SUMMARY
#############################################
log_section "GENERATING SUMMARY"

SUMMARY_FILE="${OUTPUT_DIR}/00_SUMMARY.txt"
{
    echo "═════════════════════════════════════════════════════════════"
    echo "                    ASSESSMENT SUMMARY"
    echo "═════════════════════════════════════════════════════════════"
    echo ""
    echo "Timestamp: $(date)"
    echo "Hostname: $(hostname -f 2>/dev/null || hostname)"
    echo ""
    
    echo "▶ SYSTEM OVERVIEW"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Unknown')"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Virtualization: $(systemd-detect-virt 2>/dev/null || echo 'Unknown')"
    echo ""
    
    echo "▶ RESOURCES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CPUs: $(nproc)"
    echo "Memory: $(free -h | awk '/^Mem:/{print \$2}')"
    echo "Swap: $(free -h | awk '/^Swap:/{print \$2}')"
    echo "Root Disk: $(df -h / | awk 'NR==2{print \$2}')"
    echo ""
    
    echo "▶ NETWORK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Primary IP: $(ip route get 8.8.8.8 2>/dev/null | awk '{print \$7; exit}' || echo 'Unknown')"
    echo "Interfaces: $(ip link show | grep -c '^[0-9]')"
    echo ""
    
    echo "▶ CONTAINER RUNTIME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    command_exists docker && echo "Docker: $(docker --version 2>/dev/null | awk '{print \$3}')" || echo "Docker: Not found"
    command_exists containerd && echo "Containerd: $(containerd --version 2>/dev/null | awk '{print \$3}')" || echo "Containerd: Not found"
    command_exists podman && echo "Podman: $(podman --version 2>/dev/null | awk '{print \$3}')" || echo "Podman: Not found"
    echo ""
    
    echo "▶ KUBERNETES READINESS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check critical kernel modules
    MODULES_OK=true
    for mod in overlay br_netfilter; do
        if lsmod | grep -q "^$mod "; then
            echo "✓ Module $mod: Loaded"
        else
            echo "✗ Module $mod: Not loaded"
            MODULES_OK=false
        fi
    done
    
    # Check critical sysctl parameters
    if [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = "1" ]; then
        echo "✓ IP Forwarding: Enabled"
    else
        echo "✗ IP Forwarding: Disabled"
    fi
    
    # Check swap
    if [ "$(free | awk '/^Swap:/{print \$2}')" = "0" ]; then
        echo "✓ Swap: Disabled (recommended)"
    else
        echo "⚠ Swap: Enabled (should be disabled for K8s)"
    fi
    
    echo ""
    echo "▶ FILES GENERATED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ls -la "${OUTPUT_DIR}/" | tail -n +2 | awk '{print "  - " \$9 " (" \$5 " bytes)"}'
    
} | tee "${SUMMARY_FILE}"

#############################################
# CREATE ARCHIVE
#############################################
log_section "CREATING ARCHIVE"

ARCHIVE_NAME="k8s_assessment_${HOSTNAME}_${TIMESTAMP}.tar.gz"
cd /tmp
tar czf "${ARCHIVE_NAME}" "k8s_assessment_${TIMESTAMP}" 2>/dev/null

log_info "Assessment complete!"
log_info "Output directory: ${OUTPUT_DIR}"
log_info "Archive created: /tmp/${ARCHIVE_NAME}"
log_info ""
log_info "Please review the ${OUTPUT_DIR}/00_SUMMARY.txt file for key findings."
log_info "Share the archive file for detailed analysis."

# Display quick recommendations
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                    QUICK RECOMMENDATIONS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC

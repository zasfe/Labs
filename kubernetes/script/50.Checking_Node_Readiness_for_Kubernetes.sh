#!/bin/bash
# check-node-ready.sh

echo "=== Checking Node Readiness for Kubernetes ==="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_pass() { echo -e "${GREEN}✓${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; }

# Check swap
if [ "$(free | awk '/^Swap:/{print $2}')" = "0" ]; then
    check_pass "Swap is disabled"
else
    check_fail "Swap is enabled (must be disabled)"
fi

# Check required modules
for module in overlay br_netfilter; do
    if lsmod | grep -q "^$module "; then
        check_pass "Module $module is loaded"
    else
        check_fail "Module $module is not loaded"
    fi
done

# Check sysctl parameters
if [ "$(sysctl -n net.ipv4.ip_forward)" = "1" ]; then
    check_pass "IP forwarding is enabled"
else
    check_fail "IP forwarding is disabled"
fi

if [ "$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null)" = "1" ]; then
    check_pass "Bridge netfilter is enabled"
else
    check_fail "Bridge netfilter is disabled"
fi

# Check containerd
if systemctl is-active containerd >/dev/null 2>&1; then
    check_pass "Containerd is running"
else
    check_fail "Containerd is not running"
fi

# Check firewall ports
for port in 6443 10250; do
    if firewall-cmd --list-ports 2>/dev/null | grep -q "$port/tcp"; then
        check_pass "Port $port/tcp is open"
    else
        check_fail "Port $port/tcp is not open"
    fi
done

echo ""
echo "=== Summary ==="
echo "If all checks pass, the node is ready for Kubernetes installation."

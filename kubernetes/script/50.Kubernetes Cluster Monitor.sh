#!/bin/bash
# monitor-cluster.sh

while true; do
    clear
    echo "=== Kubernetes Cluster Monitor ==="
    echo "Time: $(date)"
    echo ""
    
    echo "=== Nodes ==="
    kubectl get nodes
    echo ""
    
    echo "=== System Pods ==="
    kubectl get pods -n kube-system | grep -E "NAME|Running|Pending|Error|Crash"
    echo ""
    
    echo "=== Resource Usage ==="
    kubectl top nodes 2>/dev/null || echo "Metrics server not ready"
    echo ""
    
    echo "=== Recent Events ==="
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -5
    
    sleep 5
done

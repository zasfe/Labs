#!/usr/bin/env bash

systemctl restart kubelet 
ping -c 3 127.0.0.1 >/dev/null 2>&1

systemctl restart docker
ping -c 3 127.0.0.1 >/dev/null 2>&1

# config for work_nodes only 
kubeadm join --token 123456.1234567890123456 \
             --discovery-token-unsafe-skip-ca-verification 192.168.1.10:6443 \
             --ignore-preflight-errors=all \
             --v=5 

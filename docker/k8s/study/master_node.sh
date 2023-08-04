#!/usr/bin/env bash

echo "####################"
echo "master_node.sh run.."
echo "####################"


ping -c 3 127.0.0.1 >/dev/null 2>&1
systemctl restart docker

ping -c 3 127.0.0.1 >/dev/null 2>&1
systemctl restart kubelet

# init kubernetes 
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10 \
--v=5


# config for master node only 
mkdir -p $HOME/.kube
cp -if /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# config for kubernetes's network 
curl -fsSL https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/172.16_net_calico.yaml -o 172.16_net_calico.yaml

kubectl apply -f 172.16_net_calico.yaml
ping -c 3 127.0.0.1 >/dev/null 2>&1


kubectl apply -f 172.16_net_calico.yaml


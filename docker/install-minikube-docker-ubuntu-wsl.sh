#!/bin/bash
set -e

sudo mkdir /sys/fs/cgroup/systemd && sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

sudo useradd -m zasfe
echo "zasfe:P@ssw0rd" | sudo chpasswd

sudo chmod u+w /etc/sudoers.d
sudo echo "zasfe        ALL=(ALL)       ALL" >> /etc/sudoers.d/zasfe
sudo chmod u-w /etc/sudoers.d

sudo usermod -aG docker zasfe
echo \
  alias kubectl="minikube kubectl --" | \
  sudo tee -a /home/zasfe/.bashrc > /dev/null

su - zasfe -c minikube config set driver docker
su - zasfe -c minikube start --driver=docker

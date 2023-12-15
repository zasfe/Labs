#!/usr/bin/env bash
set -e

# Uninstall old versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done


# Add Docker's official GPG key:
sudo apt-get update -y 
sudo apt-get install ca-certificates curl gnupg -y 
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y 

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y


# Minikube wsl
sudo mkdir /sys/fs/cgroup/systemd && sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Add User
sudo useradd --create-home --shell /bin/bash zasfe 
echo "zasfe:P@ssw0rd" | sudo chpasswd

sudo chmod u+w /etc/sudoers.d
sudo echo "zasfe        ALL=(ALL)       ALL" >> /etc/sudoers.d/zasfe
sudo chmod u-w /etc/sudoers.d

sudo usermod -aG docker zasfe
echo \
  alias kubectl=\"minikube kubectl --\" | \
  sudo tee -a /home/zasfe/.bashrc > /dev/null

# Start minikube
su - zasfe -c "minikube config set driver docker"
su - zasfe -c "minikube start --driver=docker"
su - zasfe -c "minikube addons enable metrics-server"


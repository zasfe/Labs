#!/bin/bash
set -e

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

sudo useradd -m zasfe
sudo usermod -aG docker zasfe
su - zasfe -c minikube config set driver docker
su - zasfe -c minikube start --driver=docker

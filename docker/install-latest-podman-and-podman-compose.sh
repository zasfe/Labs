#!/usr/bin/env bash
set -e

# - url: https://velog.io/@composite/Podman-Compose-설치-방법

# 1. Podman 설치
sudo yum install podman -y

# 데비안 예시
#$ sudo apt install podman -y
# RHEL 계열 예시
#$ sudo yum install podman -y
# (또는)
#$ sudo dpt install podman -y
# 맥 예시
#$ brew install podman
# ... 등등


# 2. Podman Compose 설치
sudo yum install python3-pip -y

# 데비안 예시
#$ sudo apt install python3-pip -y
# RHEL 계열 예시
#$ sudo yum install python3-pip -y
# (또는)
#$ sudo dpt install python3-pip -y
# 맥 예시
#$ brew install python3-pip
# ... 등등

# 업그레이드
sudo -H pip3 install --upgrade pip

# 설치
sudo pip3 install podman-compose



# 3. Docker Compose 설치
sudo yum install podman-docker -y

# 데비안 예시
#$ sudo apt install podman-docker -y
# RHEL 계열 예시
#$ sudo yum install podman-docker -y
# (또는)
#$ sudo dpt install podman-docker -y
# 맥 예시
#$ brew install podman-docker
# ... 등등

sudo curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# version
docker-compose version


# 4. Podman Socket 으로 Docker 서비스 흉내

sudo systemctl enable --now podman.socket
# 또는
#$ sudo service podman.socket start


# 5. example

mkdir -p ~/docker/echo
cd ~/docker/echo
cat >> docker-compose.yaml << EOF
---
version: '3' 
services: 
  web: 
    image: k8s.gcr.io/echoserver:1.4
    ports:
        - "${HOST_PORT:-8080}:8080" 
EOF

podman-compose up -d

curl -X POST -d "foobar" http://localhost:8080/; echo

podman-compose logs





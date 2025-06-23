#!/bin/bash

cat <<EOF >> /etc/profile 
#ulimit setting
ulimit -u 65535  # max number of process modified
ulimit -n 65535  # open files modified
EOF

source /etc/profile 

cat <<EOF >> /etc/security/limits.conf
*               soft    nproc          65535
*               hard    nproc          65535
root            soft    nproc          65535
root            hard    nproc          65535
mysql           soft    nproc          65535
mysql           hard    nproc          65535
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
mysql           soft    nofile          65535
mysql           hard    nofile          65535
EOF

# Uninstall old versions
sudo apt-get -y remove docker docker-engine docker.io containerd runc

# Install using the apt repository
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
 "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
 sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Swarm Setting
docker swarm init

# Docker Swarm Node Add
# docker swarm join \
#  --token <docker-swarm-join-token> \
#  <hostname>
# 
# ex) docker swarm join --token SWMTKN-1-0p6o2h2ljg6t5au37e5vs4qxe3ylswlbunbleurpyxjdn1i11w-0fzjcydog6yhjsaes6ssqizap 10.24.25.4:2377

# Docker 설치하기
```bash

# 이전 버전 삭제하기
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
                  
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker.service

docker version
```

# 테스트 환경 만들기 - CentOS7

```bash
docker run --rm -it centos:centos7 bash
```

# (예시) mariadb 10.5 설치하기

> 아래는 Docker 내부에서 실행하는 명렁입니다.
> 
``` bash
yum -y install sudo vim

sudo tee /etc/yum.repos.d/mariadb.repo<<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

sudo yum makecache
sudo yum repolist
sudo yum install MariaDB-server MariaDB-client
sudo systemctl enable --now mariadb

vim /usr/lib/systemd/system/mariadb.service
```

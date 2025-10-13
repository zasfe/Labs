#!/bin/bash

# 1. 시스템 패키지 업데이트 및 필수 패키지 설치
apt install -y sudo
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# 2. Nginx 공식 GPG 키 가져오기 및 추가
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# 3. Nginx 저장소 추가
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

# 4. Nginx 저장소에 높은 우선순위 부여 (Ubuntu 기본 패키지보다 우선)
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx

# 5. 패키지 목록 업데이트 및 Nginx 설치
sudo apt update

# 6. Nginx 최신 버전으로 설치
apt install -y nginx

# 7. Nginx 버전 확인
nginx -v

# 8. Nginx 서비스 시작 및 부팅 시 자동 실행 설정
sudo systemctl start nginx
sudo systemctl enable nginx

# 9. Nginx 서비스 상태 확인
sudo systemctl status nginx

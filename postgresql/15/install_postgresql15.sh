#!/bin/bash

# 0. 시스템의 타임존을 'Asia/Seoul'로 설정합니다.
timedatectl set-timezone Asia/Seoul

# 1. 시스템 패키지 업데이트 및 필수 패키지 설치
apt install -y sudo
sudo apt update
sudo apt install -y wget ca-certificates gnupg sudo lsb-release

# 2. PostgreSQL 공식 저장소 GPG 키 추가
sudo install -d /usr/share/postgresql-common/pgdg-keyring
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg


# 3. PostgreSQL 저장소 추가
echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

# 4. 패키지 목록 업데이트 및 PostgreSQL 15 설치
sudo apt update
sudo apt install -y postgresql-15

# 5. PostgreSQL 서비스 상태 확인
sudo systemctl status postgresql

# --- (선택 사항) 외부 접속 허용 설정 ---

# 6. postgresql.conf 파일 수정 (외부 접속 허용)
# listen_addresses = '*'로 변경하여 모든 IP에서 접속 허용
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/15/main/postgresql.conf

# 7. pg_hba.conf 파일 수정 (외부 접속 계정 인증 방식 설정)
# IPv4 및 IPv6 원격 연결 허용 (인증 방식은 scram-sha-256 사용)
echo "host    all             all             0.0.0.0/0               scram-sha-256" | sudo tee -a /etc/postgresql/15/main/pg_hba.conf
echo "host    all             all             ::/0                    scram-sha-256" | sudo tee -a /etc/postgresql/15/main/pg_hba.conf

# 8. PostgreSQL 서비스 재시작
sudo systemctl restart postgresql

# 9. 방화벽에서 PostgreSQL 포트(5432) 허용
sudo ufw allow 5432/tcp
sudo ufw reload

echo "PostgreSQL 15 설치 및 외부 접속 설정이 완료되었습니다."

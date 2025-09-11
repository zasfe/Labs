#!/bin/bash
# fix_postgresql.sh - PostgreSQL 16 완전 복구

echo "Fixing PostgreSQL 16 installation..."

# 1. 서비스 중지
sudo systemctl stop postgresql@16-main

# 2. 설정 파일 수정 (stats_temp_directory 제거)
sudo sed -i '/^stats_temp_directory/d' /etc/postgresql/16/main/postgresql.conf

# 3. 권한 재설정
sudo chown -R postgres:postgres /data/postgresql
sudo chmod 700 /data/postgresql/16/main

# 4. PID 디렉토리 확인
sudo mkdir -p /var/run/postgresql
sudo chown postgres:postgres /var/run/postgresql

# 5. 로그 디렉토리 생성
sudo -u postgres mkdir -p /data/postgresql/16/main/log

# 6. 설정 검증
echo "Validating configuration..."
sudo -u postgres /usr/lib/postgresql/16/bin/postgres \
    -D /data/postgresql/16/main \
    --config-file=/etc/postgresql/16/main/postgresql.conf \
    -C shared_buffers

# 7. systemd 재로드
sudo systemctl daemon-reload

# 8. 서비스 시작
sudo systemctl start postgresql@16-main

# 9. 상태 확인
sleep 3
if systemctl is-active --quiet postgresql@16-main; then
    echo "✓ PostgreSQL is now running!"
    sudo -u postgres psql -c "SELECT version();"
else
    echo "✗ Still having issues. Check detailed logs:"
    echo "sudo journalctl -xeu postgresql@16-main"
fi

#!/bin/bash
# postgresql_troubleshoot.sh - PostgreSQL 오류 진단 스크립트

echo "========================================="
echo "PostgreSQL 16 Troubleshooting"
echo "========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 서비스 상태 확인
echo -e "\n${YELLOW}[1] Service Status:${NC}"
systemctl status postgresql@16-main --no-pager | head -20

# 2. 설정 파일 위치 확인
echo -e "\n${YELLOW}[2] Configuration Files:${NC}"
echo "Main config: /etc/postgresql/16/main/postgresql.conf"
ls -la /etc/postgresql/16/main/

# 3. 데이터 디렉토리 확인
echo -e "\n${YELLOW}[3] Data Directory:${NC}"
ls -la /data/postgresql/16/main/ 2>/dev/null || echo "Data directory not found!"

# 4. 로그 파일 확인
echo -e "\n${YELLOW}[4] Recent PostgreSQL Logs:${NC}"
if [ -d "/data/postgresql/16/main/log" ]; then
    tail -50 /data/postgresql/16/main/log/*.log 2>/dev/null | tail -20
else
    echo "Log directory not found, checking systemd logs..."
    journalctl -u postgresql@16-main -n 50 --no-pager
fi

# 5. 설정 파일 문법 검사
echo -e "\n${YELLOW}[5] Configuration Validation:${NC}"
sudo -u postgres /usr/lib/postgresql/16/bin/postgres \
    -D /data/postgresql/16/main \
    -C config_file 2>&1 | grep -E "ERROR|FATAL|WARNING"

# 6. 권한 확인
echo -e "\n${YELLOW}[6] Permission Check:${NC}"
echo "Data directory permissions:"
ls -ld /data/postgresql/16/main
echo "Owner check:"
stat -c "%U:%G" /data/postgresql/16/main

# 7. 포트 사용 확인
echo -e "\n${YELLOW}[7] Port Usage:${NC}"
ss -tulpn | grep 5432 || echo "Port 5432 is not in use"

# 8. 디스크 공간 확인
echo -e "\n${YELLOW}[8] Disk Space:${NC}"
df -h /data

# 9. 프로세스 확인
echo -e "\n${YELLOW}[9] PostgreSQL Processes:${NC}"
ps aux | grep postgres | grep -v grep || echo "No PostgreSQL processes running"

# 10. Systemd override 확인
echo -e "\n${YELLOW}[10] Systemd Override:${NC}"
cat /etc/systemd/system/postgresql@.service.d/override.conf 2>/dev/null || echo "No override file"

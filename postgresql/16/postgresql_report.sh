#!/bin/bash
# postgresql_report.sh - PostgreSQL 16 설치 정보 보고서 생성

# 색상 정의
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 보고서 생성 시작
echo "========================================="
echo "     PostgreSQL 16 Installation Report   "
echo "     Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 함수: 섹션 헤더
print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}■ $1${NC}"
    echo "----------------------------------------"
}

# 함수: 항목 출력
print_item() {
    printf "  %-25s: %s\n" "$1" "$2"
}

# 1. 시스템 정보
print_section "1. SYSTEM INFORMATION"
print_item "Hostname" "$(hostname)"
print_item "IP Address" "$(hostname -I | awk '{print $1}')"
print_item "OS Version" "$(lsb_release -d | cut -f2)"
print_item "Kernel" "$(uname -r)"
print_item "CPU Cores" "$(nproc)"
print_item "Total Memory" "$(free -h | awk '/^Mem:/{print $2}')"
print_item "Available Memory" "$(free -h | awk '/^Mem:/{print $7}')"
print_item "Disk Usage (/data)" "$(df -h /data 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo 'N/A')"

# 2. PostgreSQL 기본 정보
print_section "2. POSTGRESQL BASIC INFO"
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
print_item "PostgreSQL Version" "${PG_VERSION:-Not Available}"
print_item "Installation Date" "$(stat -c %y /usr/lib/postgresql/16/bin/postgres 2>/dev/null | cut -d' ' -f1 || echo 'Unknown')"
print_item "Service Status" "$(systemctl is-active postgresql@16-main)"
print_item "Service Enabled" "$(systemctl is-enabled postgresql@16-main 2>/dev/null)"
print_item "Process ID" "$(pgrep -f 'postgres.*-D' | head -1 || echo 'Not Running')"

# 3. 설정 정보
print_section "3. CONFIGURATION"
print_item "Config File" "/etc/postgresql/16/main/postgresql.conf"
print_item "HBA File" "/etc/postgresql/16/main/pg_hba.conf"
print_item "Data Directory" "/data/postgresql/16/main"
print_item "Log Directory" "/data/postgresql/16/main/log"
print_item "Listen Addresses" "$(grep '^listen_addresses' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'localhost')"
print_item "Port" "5432"
print_item "Max Connections" "$(grep '^max_connections' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo '100')"
print_item "SSL Enabled" "$(grep '^ssl' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | grep -v '#' | cut -d'=' -f2 | xargs || echo 'off')"

# 4. 메모리 설정
print_section "4. MEMORY CONFIGURATION"
print_item "Shared Buffers" "$(grep '^shared_buffers' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Effective Cache Size" "$(grep '^effective_cache_size' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Work Memory" "$(grep '^work_mem' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Maintenance Work Mem" "$(grep '^maintenance_work_mem' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"

# 5. 성능 설정
print_section "5. PERFORMANCE SETTINGS"
print_item "Max Worker Processes" "$(grep '^max_worker_processes' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Max Parallel Workers" "$(grep '^max_parallel_workers' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Random Page Cost" "$(grep '^random_page_cost' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"
print_item "Effective IO Concurrency" "$(grep '^effective_io_concurrency' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Default')"

# 6. 네트워크 접근 설정
print_section "6. NETWORK ACCESS"
print_item "External Access" "Enabled (listen_addresses = '*')"
print_item "Firewall Status" "$(ufw status | grep 5432 | head -1 || echo 'Not configured')"
print_item "Active Connections" "$(ss -tan | grep :5432 | grep ESTAB | wc -l)"
print_item "Listening on" "$(ss -tln | grep :5432 | awk '{print $4}')"

# 7. 데이터베이스 정보
print_section "7. DATABASE INFORMATION"
if systemctl is-active --quiet postgresql@16-main; then
    # 데이터베이스 목록
    echo "  Databases:"
    sudo -u postgres psql -t -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datname NOT IN ('template0', 'template1') ORDER BY pg_database_size(datname) DESC;" 2>/dev/null | sed 's/^/    /'
    
    # 사용자 목록
    echo ""
    echo "  Users:"
    sudo -u postgres psql -t -c "SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles WHERE rolname NOT LIKE 'pg_%' ORDER BY rolname;" 2>/dev/null | sed 's/^/    /'
else
    echo "  [Service not running - cannot retrieve database information]"
fi

# 8. 디스크 사용량
print_section "8. DISK USAGE"
if [ -d "/data/postgresql/16/main" ]; then
    print_item "Data Directory Size" "$(du -sh /data/postgresql/16/main 2>/dev/null | cut -f1)"
    print_item "WAL Directory Size" "$(du -sh /data/postgresql/16/main/pg_wal 2>/dev/null | cut -f1)"
    print_item "Log Directory Size" "$(du -sh /data/postgresql/16/main/log 2>/dev/null | cut -f1 || echo 'N/A')"
else
    echo "  [Data directory not accessible]"
fi

# 9. 백업 정보
print_section "9. BACKUP INFORMATION"
if [ -d "/data/postgresql/backups" ]; then
    LATEST_BACKUP=$(ls -t /data/postgresql/backups/*.sql.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        print_item "Backup Directory" "/data/postgresql/backups"
        print_item "Latest Backup" "$(basename $LATEST_BACKUP)"
        print_item "Backup Size" "$(du -h $LATEST_BACKUP | cut -f1)"
        print_item "Backup Count" "$(ls /data/postgresql/backups/*.sql.gz 2>/dev/null | wc -l)"
    else
        print_item "Backup Status" "No backups found"
    fi
else
    print_item "Backup Status" "Backup directory not configured"
fi

# 10. 보안 설정
print_section "10. SECURITY SETTINGS"
print_item "Password Encryption" "scram-sha-256"
print_item "SSL Status" "$(grep '^ssl' /etc/postgresql/16/main/postgresql.conf 2>/dev/null | cut -d'=' -f2 | xargs || echo 'Disabled')"
print_item "pg_hba.conf Method" "scram-sha-256 for network connections"
echo "  Access Rules:"
grep -E "^host" /etc/postgresql/16/main/pg_hba.conf 2>/dev/null | sed 's/^/    /' | head -5

# 11. 추천 사항
print_section "11. RECOMMENDATIONS"
echo -e "  ${YELLOW}[!]${NC} Security:"
echo "      • Change default postgres password"
echo "      • Restrict pg_hba.conf to specific IP ranges"
echo "      • Enable and configure SSL certificates"
echo ""
echo -e "  ${YELLOW}[!]${NC} Maintenance:"
echo "      • Set up automated backups"
echo "      • Configure log rotation"
echo "      • Monitor disk space regularly"
echo ""
echo -e "  ${YELLOW}[!]${NC} Performance:"
echo "      • Monitor connection pool usage"
echo "      • Review and optimize slow queries"
echo "      • Regular VACUUM and ANALYZE"

echo ""
echo "========================================="
echo "          Report Generation Complete      "
echo "========================================="

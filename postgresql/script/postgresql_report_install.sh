#!/bin/bash
# pg_report_universal.sh - PostgreSQL 설치 정보 보고서 생성 (버전 독립적)

# 색상 정의
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 기본 연결 정보 및 OS 계정
DB_USER="postgres"
DB_PORT="5432" 

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

# 함수: 설정 파일 값 추출
get_conf_value() {
    local setting_name=$1
    local conf_file=$2
    grep "^${setting_name}" "$conf_file" 2>/dev/null | grep -v '#' | cut -d'=' -f2 | awk '{$1=$1};1' | head -1 || echo "Default"
}

# =================================================================
# 핵심: 동적 PostgreSQL 경로 및 포트 추출
# =================================================================

# 1. 실행 중인 PostgreSQL 프로세스 확인 및 기본 포트 찾기
PG_PID=$(pgrep -u "$DB_USER" -f '^postgres: .*-D' | head -1 || echo '')
if [ -n "$PG_PID" ]; then
    PG_PORT_CMD=$(ps -p $PG_PID -o cmd --no-header | grep -o '\-p [0-9]\+' | awk '{print $2}' || echo '5432')
    DB_PORT="$PG_PORT_CMD"
    PG_STATUS="active (PID: $PG_PID)"
else
    PG_STATUS="inactive"
fi

# 2. 데이터베이스 연결 및 정보 질의
PG_VERSION_FULL="Not Available"
PG_DATA_DIR=""
PG_CONF_FILE=""
PG_HBA_FILE=""
PG_LOG_DIR_ABS=""

if [ "$PG_STATUS" != "inactive" ]; then
    PG_VERSION_FULL=$(sudo -u "$DB_USER" psql -p "$DB_PORT" -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
    
    if [ -n "$PG_VERSION_FULL" ]; then
        PG_DATA_DIR=$(sudo -u "$DB_USER" psql -p "$DB_PORT" -t -c "SHOW data_directory;" 2>/dev/null | xargs)
        PG_CONF_FILE="${PG_DATA_DIR}/postgresql.conf"
        PG_HBA_FILE="${PG_DATA_DIR}/pg_hba.conf"
        
        PG_LOG_DIR=$(sudo -u "$DB_USER" psql -p "$DB_PORT" -t -c "SHOW log_directory;" 2>/dev/null | xargs)
        if [[ "$PG_LOG_DIR" != /* ]] && [ -n "$PG_DATA_DIR" ]; then
            PG_LOG_DIR_ABS="${PG_DATA_DIR}/${PG_LOG_DIR}"
        else
            PG_LOG_DIR_ABS="$PG_LOG_DIR"
        fi
    else
        PG_STATUS="active, but psql connection failed. Check authentication."
    fi
fi

# 보고서 생성 시작
echo "========================================="
echo "      PostgreSQL Universal Report      "
echo "      Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 1. 시스템 정보
print_section "1. SYSTEM INFORMATION"
print_item "Hostname" "$(hostname)"
print_item "IP Address" "$(hostname -I | awk '{print $1}')"
print_item "OS Version" "$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/issue | head -1)"
print_item "Kernel" "$(uname -r)"
print_item "CPU Cores" "$(nproc)"
print_item "Total Memory" "$(free -h | awk '/^Mem:/{print $2}')"
print_item "Available Memory" "$(free -h | awk '/^Mem:/{print $7}')"
DISK_CHECK_DIR="${PG_DATA_DIR:-/}"
print_item "Disk Usage ($(basename $DISK_CHECK_DIR))" "$(df -h "$DISK_CHECK_DIR" 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo 'N/A')"

# 2. PostgreSQL 기본 정보
print_section "2. POSTGRESQL BASIC INFO"
print_item "PostgreSQL Version" "${PG_VERSION_FULL:-Not Available}"
print_item "Service Status" "${PG_STATUS}"
print_item "Port" "$DB_PORT"
print_item "Process ID" "${PG_PID:-Not Running}"
print_item "Installation Date" "$(stat -c %y $(which postgres) 2>/dev/null | cut -d' ' -f1 || echo 'Unknown')"
if command -v systemctl >/dev/null 2>&1; then
    print_item "Service Enabled" "$(systemctl is-enabled postgresql.service 2>/dev/null || echo 'Check Manually')"
fi

# 3. 설정 정보
print_section "3. CONFIGURATION"
print_item "Config File" "${PG_CONF_FILE:-Not Running}"
print_item "HBA File" "${PG_HBA_FILE:-Not Running}"
print_item "Data Directory" "${PG_DATA_DIR:-Not Running}"
print_item "Log Directory" "${PG_LOG_DIR_ABS:-Not Running}"

if [ -f "$PG_CONF_FILE" ]; then
    print_item "Listen Addresses" "$(get_conf_value 'listen_addresses' "$PG_CONF_FILE")"
    print_item "Max Connections" "$(get_conf_value 'max_connections' "$PG_CONF_FILE")"
    print_item "SSL Enabled" "$(get_conf_value 'ssl' "$PG_CONF_FILE")"
fi

# 4. 메모리/성능 설정
if [ -f "$PG_CONF_FILE" ]; then
    print_section "4. MEMORY CONFIGURATION"
    print_item "Shared Buffers" "$(get_conf_value 'shared_buffers' "$PG_CONF_FILE")"
    print_item "Effective Cache Size" "$(get_conf_value 'effective_cache_size' "$PG_CONF_FILE")"
    print_item "Work Memory" "$(get_conf_value 'work_mem' "$PG_CONF_FILE")"
    print_item "Maintenance Work Mem" "$(get_conf_value 'maintenance_work_mem' "$PG_CONF_FILE")"

    print_section "5. PERFORMANCE SETTINGS"
    print_item "Max Worker Processes" "$(get_conf_value 'max_worker_processes' "$PG_CONF_FILE")"
    print_item "Max Parallel Workers" "$(get_conf_value 'max_parallel_workers' "$PG_CONF_FILE")"
    print_item "Random Page Cost" "$(get_conf_value 'random_page_cost' "$PG_CONF_FILE")"
    print_item "Effective IO Concurrency" "$(get_conf_value 'effective_io_concurrency' "$PG_CONF_FILE")"
fi

# 6. 네트워크 접근 설정
print_section "6. NETWORK ACCESS"
LISTEN_ADDR="$(ss -tln | grep :$DB_PORT | awk '{print $4}')"
print_item "Listening on" "${LISTEN_ADDR:-N/A}"
print_item "Active Connections" "$(ss -tan | grep :$DB_PORT | grep ESTAB | wc -l)"
print_item "Firewall Status" "$(sudo iptables -L INPUT -n 2>/dev/null | grep "$DB_PORT" | head -1 || ufw status | grep "$DB_PORT" | head -1 || echo 'Check Manually')"

if [ -f "$PG_HBA_FILE" ]; then
    HBA_METHOD=$(grep -E "^host" "$PG_HBA_FILE" 2>/dev/null | awk '{print $5}' | sort | uniq | xargs)
    print_item "HBA File Method" "${HBA_METHOD:-N/A}"
    echo "  Access Rules (Top 5 hosts):"
    grep -E "^host" "$PG_HBA_FILE" 2>/dev/null | sed 's/^/    /' | head -5
else
    print_item "HBA File" "Not accessible or service not running."
fi

# 7. 데이터베이스 정보
print_section "7. DATABASE INFORMATION"
if [ -n "$PG_VERSION_FULL" ]; then
    echo "  Databases:"
    sudo -u "$DB_USER" psql -p "$DB_PORT" -t -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datname NOT IN ('template0', 'template1') ORDER BY pg_database_size(datname) DESC;" 2>/dev/null | sed 's/^/    /'
    
    echo ""
    echo "  Users:"
    sudo -u "$DB_USER" psql -p "$DB_PORT" -t -c "SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles WHERE rolname NOT LIKE 'pg_%' ORDER BY rolname;" 2>/dev/null | sed 's/^/    /'
else
    echo "  [Service not running or psql connection failed - cannot retrieve database information]"
fi

# 8. 디스크 사용량
print_section "8. DISK USAGE"
if [ -d "$PG_DATA_DIR" ]; then
    PG_WAL_DIR_NAME="pg_wal"
    if [ ! -d "${PG_DATA_DIR}/pg_wal" ] && [ -d "${PG_DATA_DIR}/pg_xlog" ]; then
        PG_WAL_DIR_NAME="pg_xlog"
    fi
    
    print_item "Data Directory Size" "$(du -sh "$PG_DATA_DIR" 2>/dev/null | cut -f1)"
    print_item "WAL Directory Size" "$(du -sh "${PG_DATA_DIR}/$PG_WAL_DIR_NAME" 2>/dev/null | cut -f1 || echo 'N/A')"
    print_item "Log Directory Size" "$(du -sh "$PG_LOG_DIR_ABS" 2>/dev/null | cut -f1 || echo 'N/A')"
else
    echo "  [Data directory not accessible]"
fi

# 9. 백업 정보 (예시 경로 사용)
print_section "9. BACKUP INFORMATION"
BACKUP_PATH="/data/postgresql/backups" # 백업 스크립트의 경로와 맞추어 사용하거나 수정 필요
if [ -d "$BACKUP_PATH" ]; then
    LATEST_BACKUP=$(find "$BACKUP_PATH" -type f \( -name "*.sql.gz" -o -name "*.dump" \) -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)
    if [ -n "$LATEST_BACKUP" ]; then
        print_item "Backup Directory" "$BACKUP_PATH"
        print_item "Latest Backup" "$(basename "$LATEST_BACKUP")"
        print_item "Backup Size" "$(du -h "$LATEST_BACKUP" 2>/dev/null | cut -f1)"
        print_item "Backup Count" "$(find "$BACKUP_PATH" -type f \( -name "*.sql.gz" -o -name "*.dump" \) 2>/dev/null | wc -l)"
    else
        print_item "Backup Status" "No backups found"
    fi
else
    print_item "Backup Status" "Backup directory ($BACKUP_PATH) not found or configured"
fi

# 10. 보안 설정
print_section "10. SECURITY SUMMARY"
print_item "HBA Host Rules" "${HBA_RULES:-0} rules"
print_item "Primary Auth Method" "${HBA_METHOD:-N/A}"
print_item "SSL Status" "$(get_conf_value 'ssl' "$PG_CONF_FILE" || echo 'Disabled')"
print_item "Data Dir Ownership" "$(stat -c %U "$PG_DATA_DIR" 2>/dev/null || echo 'Check Manually')"

# 11. 추천 사항
print_section "11. RECOMMENDATIONS"
echo -e "  ${YELLOW}[!]${NC} Security:"
echo "      • Change default postgres password (if applicable)"
echo "      • Restrict pg_hba.conf access to specific IPs"
echo "      • Enable and configure SSL certificates"
echo ""
echo -e "  ${YELLOW}[!]${NC} Maintenance:"
echo "      • Set up automated backups and log rotation"
echo "      • Monitor disk space ($PG_DATA_DIR)"
echo ""
echo -e "  ${YELLOW}[!]${NC} Performance:"
echo "      • Review memory settings (e.g., shared_buffers) based on load"
echo "      • Implement connection pooling (e.g., PgBouncer)"

echo ""
echo "========================================="
echo "        Report Generation Complete       "
echo "========================================="

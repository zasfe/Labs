#!/bin/bash
# postgresql_troubleshoot_universal.sh - PostgreSQL 오류 진단 스크립트 (버전 독립적)

# set -euo pipefail # 진단 스크립트는 오류 발생 시에도 최대한 많은 정보를 수집해야 하므로 set -e를 사용하지 않습니다.

echo "========================================="
echo "PostgreSQL Universal Troubleshooting"
echo "========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 기본 정보 설정 (postgres 계정 가정)
DB_USER="postgres"
DEFAULT_PORT="5432"

# 1. 동적 정보 추출
PG_PID=$(pgrep -u "$DB_USER" -f '^postgres: .*-D' | head -1 || echo '')
PG_SERVICE_NAME="N/A" # systemctl 서비스 이름 (배포판마다 다름)
PG_DATA_DIR=""
PG_PORT="$DEFAULT_PORT"
PG_BIN_PATH=""

if [ -n "$PG_PID" ]; then
    # 프로세스 명령줄에서 -p 옵션과 -D 옵션을 찾아 포트와 데이터 디렉토리 추출
    CMD_LINE=$(ps -p "$PG_PID" -o cmd --no-header)
    PG_PORT=$(echo "$CMD_LINE" | grep -o '\-p [0-9]\+' | awk '{print $2}' || echo "$DEFAULT_PORT")
    PG_DATA_DIR=$(echo "$CMD_LINE" | grep -o '\-D [^[:space:]]\+' | awk '{print $2}' || echo "N/A")
    
    # 실행 파일 경로 추출
    PG_BIN_PATH=$(readlink -f /proc/"$PG_PID"/exe)
    
    # Debian/Ubuntu 계열의 systemctl 서비스 이름 추정 (버전과 클러스터 이름 기반)
    if command -v pg_lsclusters >/dev/null 2>&1; then
        PG_VERSION_CLUSTER=$(pg_lsclusters | awk -v dir="$PG_DATA_DIR" '$4 == dir {print $1"-"$2}' | head -1)
        if [ -n "$PG_VERSION_CLUSTER" ]; then
            PG_SERVICE_NAME="postgresql@$PG_VERSION_CLUSTER"
        else
             # systemctl service name fallback (RHEL/CentOS style)
             PG_SERVICE_NAME="postgresql" 
        fi
    else
        # RHEL/CentOS/기타 systemctl 서비스 이름 추정
        PG_SERVICE_NAME="postgresql"
    fi
fi

# ---------------------------------------------------------------------

# 1. 서비스 상태 확인 (가장 정확한 서비스 이름 또는 일반적인 이름 사용)
echo -e "\n${YELLOW}[1] Service Status:${NC}"
if [ "$PG_SERVICE_NAME" != "N/A" ] && command -v systemctl >/dev/null 2>&1; then
    echo "Checking service: $PG_SERVICE_NAME"
    systemctl status "$PG_SERVICE_NAME" --no-pager | head -20
else
    echo "Service name or systemctl command not available. Checking process status."
    if [ -n "$PG_PID" ]; then
        echo "PostgreSQL is running (PID: $PG_PID, Port: $PG_PORT)."
    else
        echo "PostgreSQL service appears to be DOWN."
    fi
fi

# 2. 설정 파일 위치 확인
echo -e "\n${YELLOW}[2] Configuration Files:${NC}"
if [ "$PG_DATA_DIR" != "N/A" ]; then
    PG_CONF_FILE="${PG_DATA_DIR}/postgresql.conf"
    PG_HBA_FILE="${PG_DATA_DIR}/pg_hba.conf"
    
    echo "Data Directory: $PG_DATA_DIR"
    echo "Main Config: $PG_CONF_FILE"
    echo "HBA Config: $PG_HBA_FILE"
    
    echo "Directory contents (top 5 files):"
    ls -la "$PG_DATA_DIR" 2>/dev/null | head -5
else
    echo "Data directory path (-D) not found in process arguments."
fi

# 3. 데이터 디렉토리 확인
echo -e "\n${YELLOW}[3] Data Directory Access Check:${NC}"
if [ "$PG_DATA_DIR" != "N/A" ] && [ -d "$PG_DATA_DIR" ]; then
    echo "Data directory: $PG_DATA_DIR"
    ls -la "$PG_DATA_DIR" 2>/dev/null | grep -E "pg_hba.conf|postgresql.conf"
else
    echo "Data directory ($PG_DATA_DIR) not found or not running."
fi

# 4. 로그 파일 확인
echo -e "\n${YELLOW}[4] Recent PostgreSQL Logs:${NC}"
if [ "$PG_DATA_DIR" != "N/A" ]; then
    # log_directory 설정값을 DB에서 직접 질의하여 동적으로 찾음
    PG_LOG_DIR_SETTING=$(sudo -u "$DB_USER" psql -p "$PG_PORT" -t -c "SHOW log_directory;" 2>/dev/null | xargs)
    if [ -z "$PG_LOG_DIR_SETTING" ]; then
        PG_LOG_DIR_SETTING="log" # 기본값 추정
    fi

    # 상대 경로 처리 (PostgreSQL은 기본적으로 'log'를 Data Dir 아래에 생성)
    if [[ "$PG_LOG_DIR_SETTING" != /* ]]; then
        PG_LOG_DIR="${PG_DATA_DIR}/${PG_LOG_DIR_SETTING}"
    else
        PG_LOG_DIR="$PG_LOG_DIR_SETTING"
    fi
fi

if [ -d "$PG_LOG_DIR" ]; then
    echo "Checking logs in: $PG_LOG_DIR"
    # 가장 최신 로그 파일 찾기
    LATEST_LOG=$(find "$PG_LOG_DIR" -type f -name "*.log" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2)
    if [ -n "$LATEST_LOG" ]; then
        echo "Latest log file: $(basename "$LATEST_LOG")"
        tail -20 "$LATEST_LOG" 2>/dev/null || echo "Could not read log file."
    else
        echo "No *.log files found in $PG_LOG_DIR. Checking systemd journal."
        journalctl -u "$PG_SERVICE_NAME" -n 20 --no-pager 2>/dev/null || echo "Could not retrieve systemd logs."
    fi
else
    echo "Log directory ($PG_LOG_DIR) not found, checking systemd logs..."
    journalctl -u "$PG_SERVICE_NAME" -n 20 --no-pager 2>/dev/null || echo "Could not retrieve systemd logs for $PG_SERVICE_NAME."
fi


# 5. 설정 파일 문법 검사
echo -e "\n${YELLOW}[5] Configuration Validation:${NC}"
if [ -n "$PG_BIN_PATH" ] && [ -d "$PG_DATA_DIR" ]; then
    echo "Using binary: $PG_BIN_PATH"
    # -C config_file 옵션은 9.3+에서 지원되지만, 에러 체크는 가장 중요한 진단 항목임
    sudo -u "$DB_USER" "$PG_BIN_PATH" \
        -D "$PG_DATA_DIR" \
        -C config_file 2>&1 | grep -E "ERROR|FATAL|WARNING" || echo "No ERROR/FATAL/WARNING found."
else
    echo "Cannot validate: PostgreSQL binary or data directory not identified."
fi

# 6. 권한 확인
echo -e "\n${YELLOW}[6] Permission Check:${NC}"
if [ -d "$PG_DATA_DIR" ]; then
    echo "Data directory permissions:"
    ls -ld "$PG_DATA_DIR"
    echo "Owner check (should be $DB_USER):"
    stat -c "%U:%G" "$PG_DATA_DIR" 2>/dev/null || echo "N/A"
else
    echo "Cannot check permissions: Data directory not found."
fi

# 7. 포트 사용 확인
echo -e "\n${YELLOW}[7] Port Usage:${NC}"
ss -tulpn | grep ":$PG_PORT" || echo "Port $PG_PORT is not in use or process is not visible"

# 8. 디스크 공간 확인
echo -e "\n${YELLOW}[8] Disk Space:${NC}"
if [ -n "$PG_DATA_DIR" ]; then
    # 데이터 디렉토리가 속한 마운트 포인트를 찾아서 확인
    MOUNT_POINT=$(df "$PG_DATA_DIR" | awk 'NR==2 {print $NF}')
    echo "Checking mount point: $MOUNT_POINT"
    df -h "$MOUNT_POINT"
else
    echo "Data directory not found. Checking root partition (/):"
    df -h /
fi


# 9. 프로세스 확인
echo -e "\n${YELLOW}[9] PostgreSQL Processes:${NC}"
ps aux | grep postgres | grep -v grep || echo "No PostgreSQL processes running"

# 10. Systemd override 확인
echo -e "\n${YELLOW}[10] Systemd Override:${NC}"
if [ "$PG_SERVICE_NAME" != "N/A" ] && command -v systemctl >/dev/null 2>&1; then
    # systemctl show 명령을 통해 오버라이드 파일 경로를 추정
    OVERRIDE_PATH=$(systemctl show "$PG_SERVICE_NAME" --property=FragmentPath 2>/dev/null | awk -F= '{print $2}')
    if [ -n "$OVERRIDE_PATH" ]; then
        OVERRIDE_DIR=$(dirname "$OVERRIDE_PATH")/override.conf
        echo "Checking path: $OVERRIDE_DIR"
        cat "$OVERRIDE_DIR" 2>/dev/null || echo "No override file found at expected path."
    else
        echo "Could not determine service file path. Checking common override locations."
        cat /etc/systemd/system/postgresql@.service.d/override.conf 2>/dev/null || echo "No specific override file."
    fi
else
    echo "Systemd not used or service name unknown."
fi

echo "========================================="
echo "Troubleshooting complete. Review output for ${RED}ERROR/FATAL/DOWN${NC} status."

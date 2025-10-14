#!/bin/bash
# postgresql_restore_force_universal.sh - PostgreSQL 완전 복구 (버전 독립적)

# set -euo pipefail # 진단 스크립트는 오류 발생 시에도 최대한 많은 정보를 수집해야 하므로 set -e를 사용하지 않습니다.

echo "========================================="
echo "PostgreSQL Universal Installation Fix"
echo "========================================="

# 기본 정보 설정 및 변수 초기화
DB_USER="postgres"
DEFAULT_PORT="5432"
PG_PID=""
PG_SERVICE_NAME=""
PG_DATA_DIR=""
PG_BIN_PATH=""
PG_CONF_FILE=""

# 1. 동적 정보 추출 (실행 중인 서비스나 경로를 찾습니다.)
echo "Searching for active PostgreSQL instance and configuration paths..."

# PostgreSQL 프로세스 확인
PG_PID=$(pgrep -u "$DB_USER" -f '^postgres: .*-D' | head -1 || echo '')

if [ -n "$PG_PID" ]; then
    # 프로세스 명령줄에서 -D 옵션을 찾아 데이터 디렉토리 추출
    CMD_LINE=$(ps -p "$PG_PID" -o cmd --no-header)
    PG_DATA_DIR=$(echo "$CMD_LINE" | grep -o '\-D [^[:space:]]\+' | awk '{print $2}' || echo "")
    
    # 실행 파일 경로 추출
    PG_BIN_PATH=$(readlink -f /proc/"$PG_PID"/exe || echo "")
fi

# 데이터 디렉토리를 찾지 못하면, 일반적인 경로를 시도하여 버전을 추정합니다.
if [ -z "$PG_DATA_DIR" ]; then
    if command -v pg_lsclusters >/dev/null 2>&1; then
        # Debian/Ubuntu 계열: pg_lsclusters를 사용하여 가장 활성화된 클러스터의 데이터 디렉토리 사용
        PG_VERSION_CLUSTER=$(pg_lsclusters | awk '$5 == "online" {print $1"/"$2}' | tail -1)
        if [ -n "$PG_VERSION_CLUSTER" ]; then
            PG_DATA_DIR=$(pg_lsclusters | awk -v v=$(echo $PG_VERSION_CLUSTER | cut -d'/' -f1) -v c=$(echo $PG_VERSION_CLUSTER | cut -d'/' -f2) '$1 == v && $2 == c {print $4}')
            PG_SERVICE_NAME="postgresql@$(echo $PG_VERSION_CLUSTER | sed 's/\//-/')"
        fi
    fi
fi

# 최종 경로가 없으면 복구 작업을 수행할 수 없습니다.
if [ -z "$PG_DATA_DIR" ]; then
    echo "ERROR: Could not dynamically determine the PostgreSQL data directory. Aborting."
    exit 1
fi

PG_CONF_FILE="${PG_DATA_DIR}/postgresql.conf"
# pg_lsclusters를 사용하지 않는 환경을 위해 서비스 이름 추정
if [ -z "$PG_SERVICE_NAME" ]; then
    PG_SERVICE_NAME="postgresql" 
fi
if [ -z "$PG_BIN_PATH" ]; then
    PG_BIN_PATH=$(which postgres || echo "")
fi

echo "Detected Data Dir: $PG_DATA_DIR"
echo "Target Service: $PG_SERVICE_NAME"
echo "PostgreSQL Binary: $PG_BIN_PATH"
echo "Configuration File: $PG_CONF_FILE"
echo "-----------------------------------------"

# ---------------------------------------------------------------------

# 1. 서비스 중지
echo "Stopping PostgreSQL service: $PG_SERVICE_NAME"
sudo systemctl stop "$PG_SERVICE_NAME" 2>/dev/null || echo "Service stop failed or was already stopped (non-fatal)."

# 2. 설정 파일 수정 (stats_temp_directory 제거)
echo "Removing 'stats_temp_directory' setting from config file."
if [ -f "$PG_CONF_FILE" ]; then
    sudo sed -i '/^stats_temp_directory/d' "$PG_CONF_FILE"
else
    echo "WARNING: Configuration file $PG_CONF_FILE not found. Skipping sed modification."
fi

# 3. 권한 재설정
# Data Directory와 그 상위 디렉토리(/data/postgresql/)의 권한을 복구
echo "Resetting permissions for data directory: $PG_DATA_DIR"
# 상위 디렉토리 (/data/postgresql)의 경로를 추정하여 재귀적으로 소유권 변경
PG_BASE_DATA_DIR=$(dirname "$PG_DATA_DIR" | xargs dirname)
if [[ "$PG_BASE_DATA_DIR" == *"postgresql"* ]]; then
    echo "Setting ownership recursively on $PG_BASE_DATA_DIR"
    sudo chown -R "$DB_USER":"$DB_USER" "$PG_BASE_DATA_DIR"
else
    echo "Setting ownership recursively on $PG_DATA_DIR only."
    sudo chown -R "$DB_USER":"$DB_USER" "$PG_DATA_DIR"
fi

# 데이터 디렉토리 자체는 700으로 설정 (가장 중요)
echo "Setting permissions to 700 for $PG_DATA_DIR"
sudo chmod 700 "$PG_DATA_DIR"

# 4. PID 디렉토리 확인 (/var/run/postgresql은 Ubuntu/Debian 표준)
echo "Ensuring PID directory /var/run/postgresql exists with correct ownership."
sudo mkdir -p /var/run/postgresql
sudo chown "$DB_USER":"$DB_USER" /var/run/postgresql

# 5. 로그 디렉토리 생성
# 로그 디렉토리는 설정 파일에서 동적으로 가져와야 하지만, 복구 스크립트이므로
# Data Directory 내의 'log' 디렉토리를 생성하는 것이 안전합니다.
PG_FALLBACK_LOG_DIR="${PG_DATA_DIR}/log"
echo "Creating fallback log directory: $PG_FALLBACK_LOG_DIR"
sudo -u "$DB_USER" mkdir -p "$PG_FALLBACK_LOG_DIR"

# 6. 설정 검증
echo "Validating configuration using binary..."
if [ -n "$PG_BIN_PATH" ]; then
    if sudo -u "$DB_USER" "$PG_BIN_PATH" \
        -D "$PG_DATA_DIR" \
        --config-file="$PG_CONF_FILE" \
        -C shared_buffers 2>&1 | grep -E "ERROR|FATAL|WARNING"; then
        echo "Configuration validation found potential issues. Proceeding anyway."
    else
        echo "Configuration validation passed successfully."
    fi
else
    echo "WARNING: PostgreSQL binary path not found. Skipping configuration validation."
fi

# 7. systemd 재로드
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# 8. 서비스 시작
echo "Starting PostgreSQL service: $PG_SERVICE_NAME"
sudo systemctl start "$PG_SERVICE_NAME"

# 9. 상태 확인
echo "Waiting 3 seconds for service startup..."
sleep 3
if sudo systemctl is-active --quiet "$PG_SERVICE_NAME"; then
    echo "SUCCESS: PostgreSQL is now running!"
    sudo -u "$DB_USER" psql -c "SELECT version();" 2>/dev/null || echo "Could not run psql command. Check user access."
else
    echo "FAILURE: Still having issues. Check detailed logs:"
    echo "sudo journalctl -xeu $PG_SERVICE_NAME"
fi

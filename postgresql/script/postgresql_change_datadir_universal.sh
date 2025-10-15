#!/bin/bash
# postgresql_change_datadir_universal.sh - PostgreSQL 데이터 디렉토리 변경 스크립트

# 코드 목적: APT로 설치된 PostgreSQL의 버전을 동적으로 확인하고,
#            새로운 데이터 디렉토리로 이동, 클러스터를 초기화한 후,
#            Systemd 환경 변수를 업데이트하여 새 경로를 지정.
# 필요한 명령 패키지: systemctl, chown, initdb, psql (postgresql 설치 시 포함)

set -e # 에러 발생시 스크립트 중단

CUSTOM_DATA_BASE_DIR="/data/postgresql"
DB_USER="postgres"
PG_CLUSTER_NAME="main" # 기본 클러스터 이름

echo "========================================="
echo "PostgreSQL Data Directory Setup Script"
echo "Target Directory: $CUSTOM_DATA_BASE_DIR"
echo "========================================="

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# 1. 설치된 PostgreSQL 버전 확인
# dpkg를 사용하여 설치된 가장 높은 버전을 동적으로 찾습니다.
PG_MAJOR_VERSION=$(dpkg -l | grep -E '^ii.*postgresql-[0-9][\.0-9]' | awk '{print $2}' | grep -oE '[0-9][\.0-9]$' | cut -d'.' -f1 | sort -nr | head -1)

if [ -z "$PG_MAJOR_VERSION" ]; then
    echo "ERROR: PostgreSQL version could not be determined. Run installation script first."
    exit 1
fi

# 동적 경로 설정
PG_BIN_PATH=$(find /usr/lib/postgresql/ -name "initdb" | grep "/$PG_MAJOR_VERSION/bin/initdb" | head -1)
if [ -z "$PG_BIN_PATH" ]; then
    echo "ERROR: initdb binary not found for version $PG_MAJOR_VERSION. Check installation."
    exit 1
fi
PG_BIN_DIR=$(dirname "$PG_BIN_PATH")
PG_DATA_DIR="${CUSTOM_DATA_BASE_DIR}/${PG_MAJOR_VERSION}/${PG_CLUSTER_NAME}"
PG_SERVICE_NAME="postgresql@${PG_MAJOR_VERSION}-${PG_CLUSTER_NAME}"

echo "Detected Version: $PG_MAJOR_VERSION"
echo "New Data Path: $PG_DATA_DIR"
echo "Service Name: $PG_SERVICE_NAME"
echo "-----------------------------------------"

# 2. 커스텀 데이터 디렉토리 생성 및 권한 설정
echo "[1/6] Creating custom data directory and setting permissions..."
mkdir -p "$PG_DATA_DIR"
chown -R "$DB_USER":"$DB_USER" "$CUSTOM_DATA_BASE_DIR"
chmod -R 700 "$PG_DATA_DIR"

# 3. 기존 데이터 디렉토리 백업 및 삭제 (선택적)
DEFAULT_DATA_DIR="/var/lib/postgresql/${PG_MAJOR_VERSION}/${PG_CLUSTER_NAME}"
 if [ -d "$DEFAULT_DATA_DIR" ]; then
    echo "[2/6] Backing up default data directory: $DEFAULT_DATA_DIR -> ${DEFAULT_DATA_DIR}.bak"
    mv "$DEFAULT_DATA_DIR" "${DEFAULT_DATA_DIR}.bak"
fi

# 4. 데이터베이스 클러스터 초기화
echo "[3/6] Initializing new database cluster at $PG_DATA_DIR..."
sudo -u "$DB_USER" "$PG_BIN_PATH" \
    -D "$PG_DATA_DIR" \
    --locale=en_US.UTF-8 \
    --encoding=UTF8 \
    --data-checksums

# 5. Systemd override 설정 (PGDATA 경로 지정)
echo "[4/6] Configuring systemd override to point to the new data path..."
OVERRIDE_DIR="/etc/systemd/system/${PG_SERVICE_NAME}.service.d"
mkdir -p "$OVERRIDE_DIR"

cat > "${OVERRIDE_DIR}/override.conf" <<EOF
[Service]
# Environment variable to explicitly set the data directory for the service
Environment="PGDATA=$PG_DATA_DIR"
# Increase system limits for network connections (for later performance tuning)
LimitNOFILE=65536
LimitNPROC=32768
EOF

# 6. default data path 수정 (PGDATA 경로 지정)
sed -i "/data_directory = '\/var\/lib\/postgresql\/${PG_MAJOR_VERSION}\/main'/ {
    s/^/# /
    a data_directory = '\/data\/postgresql\/${PG_MAJOR_VERSION}\/main'
}" /etc/postgresql/${PG_MAJOR_VERSION}/main/postgresql.conf

echo "[5/6] Reloading systemd daemon..."
systemctl daemon-reload

echo "========================================="
echo "Data directory setup complete. PGDATA is set to $PG_DATA_DIR."
echo "Next, run the performance tuning script and start the service."
echo "========================================="

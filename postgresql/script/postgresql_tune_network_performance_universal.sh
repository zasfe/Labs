#!/bin/bash
# tune_network_performance_universal.sh - PostgreSQL 성능 및 네트워크 최적화 스크립트

# 코드 목적: PostgreSQL 설정 파일(postgresql.conf, pg_hba.conf)을 수정하여
#            네트워크 접속 허용 및 성능 튜닝 값(메모리, CPU, WAL) 적용.
#            OS의 TCP/IP 및 파일 핸들 설정을 최적화.
# 필요한 명령 패키지: systemctl, sysctl, ufw (방화벽), psql (설치 검증)

set -e # 에러 발생시 스크립트 중단

# --- 사용자 환경 변수 (시스템 사양에 맞게 수동 수정 필요) ---
TOTAL_RAM_GB=16
TOTAL_CPU_CORES=16
# --------------------------------------------------------

DB_USER="postgres"
PG_CLUSTER_NAME="main"
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "========================================="
echo "PostgreSQL Performance & Network Tuning"
echo "System Specs: ${TOTAL_CPU_CORES} Cores, ${TOTAL_RAM_GB}GB RAM"
echo "Target: External Access Enabled (Scram-SHA-256)"
echo "========================================="

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# 1. 설치된 PostgreSQL 버전 및 경로 확인 (setup_datadir_universal.sh 실행 후 가정)
PG_MAJOR_VERSION=$(dpkg -l | grep -E '^ii.*postgresql-[0-9]+\.[0-9]' | awk '{print $2}' | grep -oE '[0-9]+\.[0-9]$' | cut -d'.' -f1 | sort -nr | head -1)

if [ -z "$PG_MAJOR_VERSION" ]; then
    echo "ERROR: PostgreSQL version could not be determined. Run installation script first."
    exit 1
fi

PG_DATA_DIR="/data/postgresql/${PG_MAJOR_VERSION}/${PG_CLUSTER_NAME}"
PG_CONF_FILE="${PG_DATA_DIR}/postgresql.conf"
PG_HBA_FILE="${PG_DATA_DIR}/pg_hba.conf"
PG_SERVICE_NAME="postgresql@${PG_MAJOR_VERSION}-${PG_CLUSTER_NAME}"

if [ ! -f "$PG_CONF_FILE" ]; then
    echo "ERROR: Configuration file not found at $PG_CONF_FILE. Run data directory setup first."
    exit 1
fi

echo "Detected Version: $PG_MAJOR_VERSION"
echo "Config File: $PG_CONF_FILE"
echo "Service Name: $PG_SERVICE_NAME"
echo "-----------------------------------------"

# 2. PostgreSQL 설정 (성능 및 네트워크)
echo "[1/4] Configuring PostgreSQL for network access and optimal performance..."

# 기존 설정 파일 백업
cp "$PG_CONF_FILE" "${PG_CONF_FILE}.bak.$(date +%Y%m%d)"
cp "$PG_HBA_FILE" "${PG_HBA_FILE}.bak.$(date +%Y%m%d)"

# 기존 파일에서 커스텀 설정 외의 모든 #주석과 빈 줄을 제거하고, 새로운 설정을 덮어쓰기
# 실제 환경에서는 기존 설정을 유지하고 필요한 부분만 변경하는 것이 좋으나, 여기서는 요구사항에 맞게 전체 파일을 생성
# 파일 템플릿 생성
CONF_CONTENT=$(cat <<EOF
#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------
data_directory = '$PG_DATA_DIR'
hba_file = '$PG_HBA_FILE'
ident_file = '${PG_DATA_DIR}/pg_ident.conf'
external_pid_file = '/var/run/postgresql/${PG_MAJOR_VERSION}-${PG_CLUSTER_NAME}.pid'

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------
listen_addresses = '*'
port = 5432
max_connections = 200
superuser_reserved_connections = 5
unix_socket_directories = '/var/run/postgresql'
authentication_timeout = 1min
password_encryption = scram-sha-256

#------------------------------------------------------------------------------
# NETWORK PERFORMANCE TUNING (TCP)
#------------------------------------------------------------------------------
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 6

# SSL Settings (optional - self-signed included in most installs)
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on

#------------------------------------------------------------------------------
# RESOURCE USAGE (Custom Optimized: ${TOTAL_CPU_CORES} Core, ${TOTAL_RAM_GB}GB RAM)
#------------------------------------------------------------------------------
# Memory Settings (25% Shared, 75% Effective Cache)
shared_buffers = $((TOTAL_RAM_GB / 4))GB
effective_cache_size = $((TOTAL_RAM_GB * 3 / 4))GB
maintenance_work_mem = 1GB
work_mem = 40MB
huge_pages = try
temp_buffers = 16MB

# CPU Settings (Match Cores)
max_worker_processes = $TOTAL_CPU_CORES
max_parallel_workers_per_gather = $((TOTAL_CPU_CORES / 4)) # Example: 4
max_parallel_workers = $((TOTAL_CPU_CORES / 2)) # Example: 8
max_parallel_maintenance_workers = $((TOTAL_CPU_CORES / 4)) # Example: 4

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------
wal_level = replica
wal_buffers = 16MB
min_wal_size = 1GB
max_wal_size = 4GB
checkpoint_completion_target = 0.9
archive_mode = off
max_wal_senders = 10
wal_keep_size = 1GB

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------
random_page_cost = 1.1 # SSD optimization
effective_io_concurrency = 200 # For SSD
default_statistics_target = 100
jit = on

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 0
log_line_prefix = '%m [%p] %q%u@%h:%d '
log_connections = on
log_disconnections = on
log_duration = off
log_hostname = on
log_lock_waits = on
log_statement = 'ddl'
log_temp_files = 0
log_timezone = 'UTC'
log_replication_commands = on

#------------------------------------------------------------------------------
# STATISTICS & AUTOVACUUM
#------------------------------------------------------------------------------
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
track_activities = on
track_io_timing = on
autovacuum = on
autovacuum_max_workers = 4
autovacuum_naptime = 60
autovacuum_vacuum_cost_delay = 2ms

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
statement_timeout = 0
lock_timeout = 0
idle_session_timeout = 0
EOF
# 파일 덮어쓰기
echo "$CONF_CONTENT" | sudo -u "$DB_USER" tee "$PG_CONF_FILE" >/dev/null

# 3. pg_hba.conf 설정 (외부 접속 허용)
echo "Configuring pg_hba.conf for external access..."
cat > "$PG_HBA_FILE" <<EOF
# PostgreSQL Client Authentication Configuration
# =============================================

# DATABASE ADMINISTRATIVE LOGIN (Local Unix socket: peer authentication for admin)
local   all             postgres                                peer

# LOCAL CONNECTIONS (All users, all DBs, Unix socket)
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256

# EXTERNAL CONNECTIONS (Private network ranges - using scram-sha-256 for security)
# WARNING: Modify these ranges for your environment security policy.
host    all             all             10.0.0.0/8              scram-sha-256
host    all             all             172.16.0.0/12           scram-sha-256
host    all             all             192.168.0.0/16          scram-sha-256
# Allow connections from any IP (Security Risk!) - Use with caution.
# host    all             all             0.0.0.0/0               scram-sha-256

# REPLICATION CONNECTIONS (Example for replication user)
# host    replication     replicator      0.0.0.0/0               scram-sha-256
EOF

# 4. OS 시스템 파라미터 최적화 (sysctl)
echo "[2/4] Applying OS network and file handle optimization (sysctl)..."
# 기존 파일에 추가
cat >> /etc/sysctl.conf <<EOF

# PostgreSQL Network Optimization
# ================================
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 4194304
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
fs.file-max = 65536
EOF

sysctl -p

# 5. UFW 방화벽 설정 (선택 사항)
echo "[3/4] Configuring firewall (UFW)..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 22/tcp comment 'SSH'
    ufw allow 5432/tcp comment 'PostgreSQL'
    ufw --force enable
else
    echo "WARNING: UFW not found. Firewall must be configured manually for port 5432."
fi

# 6. 서비스 시작 및 초기 사용자 설정
echo "[4/4] Starting PostgreSQL service and final checks..."
systemctl daemon-reload
systemctl enable "$PG_SERVICE_NAME"
systemctl start "$PG_SERVICE_NAME"

sleep 5

if systemctl is-active --quiet "$PG_SERVICE_NAME"; then
    echo ""
    echo "========================================="
    echo "Tuning Complete! PostgreSQL is running."
    echo "========================================="
    
    # 기본 사용자 비밀번호 설정 및 초기 DB 생성
    sudo -u "$DB_USER" psql -c "ALTER USER postgres WITH PASSWORD 'ChangeThisPassword123!';" 2>/dev/null || echo "WARNING: Failed to set postgres password (perhaps a new user/DB is needed)."
    
    echo "Host: $SERVER_IP (or localhost)"
    echo "Port: 5432"
    echo "Admin Password: ChangeThisPassword123! (!!! CHANGE THIS IMMEDIATELY !!!)"
    
    echo "========================================="
else
    echo "FAILURE: PostgreSQL failed to start after tuning."
    echo "Check logs: journalctl -xeu $PG_SERVICE_NAME"
    exit 1
fi

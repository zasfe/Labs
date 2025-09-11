#!/bin/bash
# install_postgresql16_network_optimized.sh

set -e  # 에러 발생시 스크립트 중단

echo "========================================="
echo "PostgreSQL 16 Installation"
echo "Optimized for: 16 Cores, 16GB RAM"
echo "Network: External Access Enabled"
echo "Data Directory: /data/postgresql"
echo "========================================="

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# 서버 IP 주소 가져오기
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"

# 1. 시스템 업데이트 및 필수 패키지 설치
echo "[1/8] Updating system packages..."
apt update && apt upgrade -y
# apt install -y wget ca-certificates curl gnupg lsb-release ufw
apt install -y wget ca-certificates curl gnupg lsb-release

# 2. PostgreSQL 16 공식 저장소 추가
echo "[2/8] Adding PostgreSQL repository..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt update

# 3. PostgreSQL 16 설치
echo "[3/8] Installing PostgreSQL 16..."
apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16
systemctl stop postgresql
systemctl disable postgresql

# 4. 커스텀 데이터 디렉토리 생성
echo "[4/8] Creating custom data directory..."
mkdir -p /data/postgresql/16/main
chown -R postgres:postgres /data/postgresql
chmod -R 700 /data/postgresql/16/main

# 기존 데이터 디렉토리 백업
if [ -d "/var/lib/postgresql/16/main" ]; then
    mv /var/lib/postgresql/16/main /var/lib/postgresql/16/main.bak
fi

# 5. 데이터베이스 클러스터 초기화
echo "[5/8] Initializing database cluster..."
sudo -u postgres /usr/lib/postgresql/16/bin/initdb \
    -D /data/postgresql/16/main \
    --locale=en_US.UTF-8 \
    --encoding=UTF8 \
    --data-checksums

# 6. PostgreSQL 설정 (네트워크 접속 + 성능 최적화)
echo "[6/8] Configuring PostgreSQL for network access and optimal performance..."

cat > /etc/postgresql/16/main/postgresql.conf <<EOF
#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------
data_directory = '/data/postgresql/16/main'
hba_file = '/etc/postgresql/16/main/pg_hba.conf'
ident_file = '/etc/postgresql/16/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/16-main.pid'

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------
# Network Settings - MODIFIED FOR EXTERNAL ACCESS
listen_addresses = '*'                  # Listen on all interfaces
port = 5432
max_connections = 200                   # Increased for network connections
superuser_reserved_connections = 5      # Reserved for admin connections
unix_socket_directories = '/var/run/postgresql'

# Authentication
authentication_timeout = 1min
password_encryption = scram-sha-256

#------------------------------------------------------------------------------
# NETWORK PERFORMANCE TUNING
#------------------------------------------------------------------------------
# TCP Settings for Network Performance
tcp_keepalives_idle = 60               # TCP keepalive time (seconds)
tcp_keepalives_interval = 10           # Time between keepalive probes
tcp_keepalives_count = 6                # Maximum keepalive probes
tcp_user_timeout = 60000               # TCP user timeout (milliseconds)

# SSL Settings (optional but recommended for external access)
ssl = on                                # Enable SSL
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on

#------------------------------------------------------------------------------
# RESOURCE USAGE (16 Core, 16GB RAM Optimized)
#------------------------------------------------------------------------------
# Memory Settings
shared_buffers = 4GB                    # 25% of RAM
effective_cache_size = 12GB             # 75% of RAM
maintenance_work_mem = 1GB              # for VACUUM, CREATE INDEX, etc.
work_mem = 40MB                         # per sort/hash operation
huge_pages = try                        # Use huge pages if available
temp_buffers = 16MB                     # Temp tables per session

# Connection Memory (for 200 connections)
# Total connection memory ≈ max_connections * (work_mem + temp_buffers)
# 200 * (40MB + 16MB) = ~11.2GB max (worst case)

# CPU Settings
max_worker_processes = 16               # Match CPU cores
max_parallel_workers_per_gather = 4     # Parallel query workers
max_parallel_workers = 8                # Total parallel workers
max_parallel_maintenance_workers = 4    # For maintenance operations

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------
wal_level = replica                     # Support for streaming replication
wal_buffers = 16MB
min_wal_size = 1GB
max_wal_size = 4GB
checkpoint_completion_target = 0.9
archive_mode = off                      # Enable if you need WAL archiving
max_wal_senders = 10                    # For replication connections
wal_keep_size = 1GB

#------------------------------------------------------------------------------
# REPLICATION (Network related)
#------------------------------------------------------------------------------
max_replication_slots = 10              # For logical/physical replication
hot_standby = on                        # Allow queries during recovery

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------
random_page_cost = 1.1                  # SSD optimization
effective_io_concurrency = 200          # For SSD
default_statistics_target = 100
jit = on                                # JIT compilation for queries

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 0
log_line_prefix = '%m [%p] %q%u@%h:%d '  # Include host in logs
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = off
log_hostname = on                       # Log client hostnames
log_lock_waits = on
log_statement = 'ddl'
log_temp_files = 0
log_timezone = 'UTC'

# Network Activity Logging
log_replication_commands = on
log_autovacuum_min_duration = 0

#------------------------------------------------------------------------------
# STATISTICS
#------------------------------------------------------------------------------
track_activities = on
track_activity_query_size = 1024
track_counts = on
track_io_timing = on
track_wal_io_timing = on
track_functions = all

# postgresql16 deleted 
# stats_temp_directory = '/var/run/postgresql/16-main.pg_stat_tmp'

#------------------------------------------------------------------------------
# AUTOVACUUM
#------------------------------------------------------------------------------
autovacuum = on
autovacuum_max_workers = 4
autovacuum_naptime = 60
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.05
autovacuum_vacuum_cost_delay = 2ms
autovacuum_vacuum_cost_limit = 200

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'

# Statement behavior
statement_timeout = 0                   # No timeout (set per session if needed)
lock_timeout = 0
idle_in_transaction_session_timeout = 0
idle_session_timeout = 0               # Disconnect idle sessions (0 = disabled)

#------------------------------------------------------------------------------
# EXTENSIONS
#------------------------------------------------------------------------------
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
EOF

# pg_hba.conf 설정 (외부 접속 허용)
cat > /etc/postgresql/16/main/pg_hba.conf <<EOF
# PostgreSQL Client Authentication Configuration
# =============================================

# DATABASE ADMINISTRATIVE LOGIN
# Local Unix domain socket (peer authentication for local admin)
local   all             postgres                                peer

# LOCAL CONNECTIONS
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256

# EXTERNAL CONNECTIONS (외부 접속 허용)
# =====================================
# Allow connections from any IP (보안 주의!)
# 운영 환경에서는 특정 IP 대역으로 제한 권장
# host    all             all             0.0.0.0/0               scram-sha-256
# host    all             all             ::/0                    scram-sha-256

# SPECIFIC NETWORK RANGES (보안 권장 설정 예시)
# Private network ranges (주석 처리됨 - 필요시 활성화)
host    all             all             10.0.0.0/8              scram-sha-256
host    all             all             172.16.0.0/12           scram-sha-256
host    all             all             192.168.0.0/16          scram-sha-256

# REPLICATION CONNECTIONS
# Replication user for streaming replication (필요시 활성화)
# host    replication     replicator      0.0.0.0/0               scram-sha-256
EOF

# 7. 네트워크 및 보안 설정
echo "[7/8] Configuring network and security..."

# Systemd override 설정
mkdir -p /etc/systemd/system/postgresql@.service.d/
cat > /etc/systemd/system/postgresql@.service.d/override.conf <<EOF
[Service]
Environment="PGDATA=/data/postgresql/16/main"
# Increase system limits for network connections
LimitNOFILE=65536
LimitNPROC=32768
EOF

# 시스템 네트워크 파라미터 최적화
cat >> /etc/sysctl.conf <<EOF

# PostgreSQL Network Optimization
# ================================
# Network buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 4194304

# TCP settings
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_syn_backlog = 4096

# Connection handling
net.core.somaxconn = 4096
net.ipv4.ip_local_port_range = 10000 65535
net.core.netdev_max_backlog = 5000

# File handles
fs.file-max = 65536
EOF

# 시스템 설정 적용
sysctl -p

# UFW 방화벽 설정
# echo "Configuring firewall..."
# ufw allow 22/tcp comment 'SSH'
# ufw allow 5432/tcp comment 'PostgreSQL'
# ufw --force enable

# AppArmor 설정 (Ubuntu)
if [ -f /etc/apparmor.d/usr.lib.postgresql.bin.postgres ]; then
    echo "/data/postgresql/ r," >> /etc/apparmor.d/local/usr.lib.postgresql.bin.postgres
    echo "/data/postgresql/** rwk," >> /etc/apparmor.d/local/usr.lib.postgresql.bin.postgres
    apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.bin.postgres 2>/dev/null || true
fi

# 8. 서비스 시작
echo "[8/8] Starting PostgreSQL service..."
systemctl daemon-reload
systemctl enable postgresql@16-main
systemctl start postgresql@16-main

# 설치 검증 및 초기 설정
sleep 3
if systemctl is-active --quiet postgresql@16-main; then
    echo ""
    echo "========================================="
    echo "Installation Complete!"
    echo "========================================="
    
    # 기본 사용자 생성 및 비밀번호 설정
    sudo -u postgres psql <<EOF
-- postgres 사용자 비밀번호 설정
ALTER USER postgres PASSWORD 'ChangeThisPassword123!';

-- 애플리케이션용 사용자 생성 예시
CREATE USER appuser WITH PASSWORD 'AppPassword123!';
CREATE DATABASE appdb OWNER appuser;
GRANT CONNECT ON DATABASE appdb TO appuser;
EOF

    echo ""
    echo "Database Information:"
    echo "===================="
    echo "Host: $SERVER_IP"
    echo "Port: 5432"
    echo "Admin User: postgres"
    echo "Admin Password: ChangeThisPassword123! (PLEASE CHANGE!)"
    echo ""
    echo "Test Connection:"
    echo "psql -h $SERVER_IP -U postgres -d postgres"
    echo ""
    echo "Firewall Status:"
    ufw status numbered | grep 5432
    echo ""
    echo "Network Listeners:"
    ss -tulpn | grep 5432
    echo ""
    echo "========================================="
    echo "IMPORTANT SECURITY NOTES:"
    echo "1. Change default passwords immediately!"
    echo "2. Consider restricting pg_hba.conf to specific IP ranges"
    echo "3. Enable SSL certificates for production"
    echo "4. Regular backups are essential"
    echo "========================================="
else
    echo "✗ PostgreSQL failed to start"
    echo "Check logs: journalctl -xe"
    exit 1
fi

#!/bin/bash
# pg_backup_setup_systemd-timer.sh - PostgreSQL 백업을 위한 Systemd Timer 설정

# 코드 목적: 기존 Crontab 설정을 제거하고, pg_backup_manager.sh 및 pg_backup_verify.sh 스크립트를
#            Systemd Timer를 사용하여 스케줄링. 일일/주간/월간/검증 작업을 분리하여 정의.
# 필요한 명령 패키지: systemctl, tee, mkdir, chmod

set -e # 에러 발생시 스크립트 중단

BACKUP_SCRIPT="/usr/local/bin/pg_backup_manager.sh"
VERIFY_SCRIPT="/usr/local/bin/pg_backup_verify.sh"
BACKUP_LOG_DIR="/data/backup/logs"
DB_USER="postgres"

echo "========================================="
echo "PostgreSQL Backup Systemd Timer Setup"
echo "========================================="

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# 기존 Crontab 엔트리 제거 (충돌 방지)
echo "Removing existing Crontab entry..."
rm -f /etc/cron.d/postgresql-backup || true

# 로그 디렉토리 생성 확인
mkdir -p "$BACKUP_LOG_DIR"
chown "$DB_USER":"$DB_USER" "$BACKUP_LOG_DIR" || true

# ----------------------------------------------------------------------
# 1. 일일 백업 (Daily Auto Backup)
# Crontab: 0 2 * * * (매일 새벽 2시)
# ----------------------------------------------------------------------
SERVICE_NAME="pg-daily-backup.service"
TIMER_NAME="pg-daily-backup.timer"

# Service Unit
cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=PostgreSQL Daily Backup (Auto Mode)
RequiresMountsFor=/data/backup

[Service]
Type=oneshot
User=$DB_USER
WorkingDirectory=/tmp
ExecStart=$BACKUP_SCRIPT auto
StandardOutput=append:$BACKUP_LOG_DIR/timer_daily.log
StandardError=append:$BACKUP_LOG_DIR/timer_daily.log
EOF

# Timer Unit (OnCalendar: 매일 새벽 2시)
cat <<EOF | sudo tee /etc/systemd/system/${TIMER_NAME}
[Unit]
Description=Runs PostgreSQL Daily Backup at 02:00 AM

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ----------------------------------------------------------------------
# 2. 주간 백업 (Weekly Full Backup)
# Crontab: 0 3 * * 0 (매주 일요일 새벽 3시)
# ----------------------------------------------------------------------
SERVICE_NAME="pg-weekly-full.service"
TIMER_NAME="pg-weekly-full.timer"

# Service Unit
cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=PostgreSQL Weekly Full Backup
RequiresMountsFor=/data/backup

[Service]
Type=oneshot
User=$DB_USER
WorkingDirectory=/tmp
ExecStart=$BACKUP_SCRIPT full
StandardOutput=append:$BACKUP_LOG_DIR/timer_weekly.log
StandardError=append:$BACKUP_LOG_DIR/timer_weekly.log
EOF

# Timer Unit (OnCalendar: 매주 일요일 새벽 3시)
cat <<EOF | sudo tee /etc/systemd/system/${TIMER_NAME}
[Unit]
Description=Runs PostgreSQL Weekly Full Backup at 03:00 AM on Sunday

[Timer]
OnCalendar=Sun *-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ----------------------------------------------------------------------
# 3. 월간 백업 (Monthly Physical Backup)
# Crontab: 0 4 1 * * (매월 1일 새벽 4시)
# ----------------------------------------------------------------------
SERVICE_NAME="pg-monthly-physical.service"
TIMER_NAME="pg-monthly-physical.timer"

# Service Unit
cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=PostgreSQL Monthly Physical Backup
RequiresMountsFor=/data/backup

[Service]
Type=oneshot
User=$DB_USER
WorkingDirectory=/tmp
ExecStart=$BACKUP_SCRIPT physical
StandardOutput=append:$BACKUP_LOG_DIR/timer_monthly.log
StandardError=append:$BACKUP_LOG_DIR/timer_monthly.log
EOF

# Timer Unit (OnCalendar: 매월 1일 새벽 4시)
cat <<EOF | sudo tee /etc/systemd/system/${TIMER_NAME}
[Unit]
Description=Runs PostgreSQL Monthly Physical Backup at 04:00 AM on the 1st

[Timer]
OnCalendar=*-*-1 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ----------------------------------------------------------------------
# 4. 일일 백업 검증 (Daily Verify)
# Crontab: 0 18 * * * (매일 오후 6시)
# ----------------------------------------------------------------------
SERVICE_NAME="pg-daily-verify.service"
TIMER_NAME="pg-daily-verify.timer"

# Service Unit
cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=PostgreSQL Daily Backup Verification
RequiresMountsFor=/data/backup

[Service]
Type=oneshot
User=$DB_USER
WorkingDirectory=/tmp
ExecStart=$VERIFY_SCRIPT
StandardOutput=append:$BACKUP_LOG_DIR/timer_verify.log
StandardError=append:$BACKUP_LOG_DIR/timer_verify.log
EOF

# Timer Unit (OnCalendar: 매일 오후 6시)
cat <<EOF | sudo tee /etc/systemd/system/${TIMER_NAME}
[Unit]
Description=Runs PostgreSQL Daily Backup Verification at 06:00 PM

[Timer]
OnCalendar=*-*-* 18:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ----------------------------------------------------------------------
# Timer 활성화 및 시작
# ----------------------------------------------------------------------

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling and starting all backup timers..."
sudo systemctl enable pg-daily-backup.timer
sudo systemctl start pg-daily-backup.timer

sudo systemctl enable pg-weekly-full.timer
sudo systemctl start pg-weekly-full.timer

sudo systemctl enable pg-monthly-physical.timer
sudo systemctl start pg-monthly-physical.timer

sudo systemctl enable pg-daily-verify.timer
sudo systemctl start pg-daily-verify.timer

echo "========================================="
echo "Systemd Timers configured successfully."
echo "Check status: systemctl list-timers | grep pg-"
echo "========================================="

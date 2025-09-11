#!/bin/bash
# install_backup_system.sh - 백업 시스템 설치

echo "Installing PostgreSQL Backup System..."

# 1. 디렉토리 생성
sudo mkdir -p /data/backup/{daily,weekly,monthly,logs,temp}
sudo chown -R postgres:postgres /data/backup
sudo chmod -R 750 /data/backup

# 2. 스크립트 설치
sudo cp pg_backup_manager.sh /usr/local/bin/
sudo cp pg_restore_manager.sh /usr/local/bin/
sudo cp pg_backup_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/pg_*.sh

# 3. 로그 로테이션 설정
cat <<EOF | sudo tee /etc/logrotate.d/postgresql-backup
/data/backup/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 postgres postgres
}
EOF

# 4. 초기 백업 실행
sudo -u postgres /usr/local/bin/pg_backup_manager.sh full

echo "Backup system installed successfully!"
echo ""
echo "Commands:"
echo "  pg_backup_manager.sh   - Run backups"
echo "  pg_restore_manager.sh  - Restore backups"  
echo "  pg_backup_monitor.sh   - Monitor backups"
echo ""
echo "Backup location: /data/backup/"

#!/bin/bash
# setup_backup_cron.sh - 백업 스케줄 설정

# Crontab 엔트리 추가
cat <<EOF | sudo tee /etc/cron.d/postgresql-backup
# PostgreSQL Backup Schedule
# 분 시 일 월 요일 사용자 명령

# 매일 새벽 2시 일일 백업
0 2 * * * postgres /usr/local/bin/pg_backup_manager.sh auto >> /data/backup/logs/cron.log 2>&1

# 매주 일요일 새벽 3시 주간 백업 (추가 확인)
0 3 * * 0 postgres /usr/local/bin/pg_backup_manager.sh full >> /data/backup/logs/cron.log 2>&1

# 매월 1일 새벽 4시 월간 백업 (추가 확인)
0 4 1 * * postgres /usr/local/bin/pg_backup_manager.sh physical >> /data/backup/logs/cron.log 2>&1

# 매일 오후 6시 백업 검증
0 18 * * * postgres /usr/local/bin/pg_backup_verify.sh >> /data/backup/logs/verify.log 2>&1
EOF

# 권한 설정
sudo chmod 644 /etc/cron.d/postgresql-backup

#!/bin/bash
# /usr/local/bin/pg_backup_monitor.sh
# 백업 상태 모니터링

BACKUP_BASE_DIR="/data/backup"

clear
echo "═══════════════════════════════════════════════════════════════"
echo "           PostgreSQL Backup Monitoring Dashboard              "
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 디스크 사용량
echo "📊 DISK USAGE"
echo "─────────────"
df -h "$BACKUP_BASE_DIR" | awk 'NR==1 || /backup/'
echo ""

# 백업 통계
echo "📁 BACKUP STATISTICS"
echo "────────────────────"
printf "%-15s %-10s %-15s %-20s\n" "Type" "Count" "Total Size" "Latest Backup"
echo "──────────────────────────────────────────────────────────────"

for type in daily weekly monthly; do
    dir="${BACKUP_BASE_DIR}/${type}"
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f \( -name "*.sql.gz" -o -name "*.dump" \) 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        latest=$(find "$dir" -type f \( -name "*.sql.gz" -o -name "*.dump" \) -printf '%T+\n' 2>/dev/null | sort | tail -1 | cut -d. -f1)
        printf "%-15s %-10s %-15s %-20s\n" "$type" "$count" "$size" "${latest:-N/A}"
    fi
done
echo ""

# 최근 백업 작업
echo "📝 RECENT BACKUP OPERATIONS"
echo "───────────────────────────"
if [ -d "${BACKUP_BASE_DIR}/logs" ]; then
    tail -10 "${BACKUP_BASE_DIR}/logs/backup_$(date +%Y%m%d).log" 2>/dev/null | grep -E "SUCCESS|ERROR|WARNING" || echo "No recent operations"
fi
echo ""

# 다음 스케줄
echo "⏰ NEXT SCHEDULED BACKUPS"
echo "─────────────────────────"
for job in /etc/cron.d/postgresql-backup; do
    if [ -f "$job" ]; then
        grep -E "^[0-9]" "$job" | while read line; do
            schedule=$(echo "$line" | awk '{print $1" "$2" "$3" "$4" "$5}')
            command=$(echo "$line" | awk '{for(i=7;i<=NF;i++) printf "%s ", $i; print ""}')
            echo "Schedule: $schedule"
            echo "Command: $(basename $command)"
            echo ""
        done
    fi
done

echo "═══════════════════════════════════════════════════════════════"
echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"

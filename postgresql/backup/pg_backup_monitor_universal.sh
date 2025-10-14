#!/bin/bash
# /usr/local/bin/pg_backup_monitor_universal.sh
# 백업 상태 모니터링 (버전 독립적)

set -euo pipefail

BACKUP_BASE_DIR="/data/backup"

clear
echo "==============================================================="
echo "             PostgreSQL Backup Monitoring Dashboard            "
echo "==============================================================="
echo ""

# 1. 디스크 사용량
echo "DISK USAGE"
echo "─────────────"
# $BACKUP_BASE_DIR가 마운트 포인트가 아닐 수 있으므로 NR==1 (헤더)와 $BACKUP_BASE_DIR가 포함된 라인 출력
df -h "$BACKUP_BASE_DIR" | awk 'NR==1 || $NF == "'"$BACKUP_BASE_DIR"'"'
echo ""

# 2. 백업 통계
echo "BACKUP STATISTICS"
echo "────────────────────"
printf "%-15s %-10s %-15s %-20s\n" "Type" "Count" "Total Size" "Latest Backup"
echo "──────────────────────────────────────────────────────────────"

for type in daily weekly monthly; do
    dir="${BACKUP_BASE_DIR}/${type}"
    
    if [ -d "$dir" ]; then
        # *.sql.gz, *.dump 파일은 물론, Directory 포맷인 *.dir 디렉토리도 백업으로 포함
        COUNT_FILES=$(find "$dir" -type f \( -name "*.sql.gz" -o -name "*.dump" \))
        COUNT_DIRS=$(find "$dir" -type d -name "*.dir")

        count=$(echo "$COUNT_FILES" "$COUNT_DIRS" | xargs -n1 | wc -l)
        
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        
        # 최신 백업 시간 추출 (파일과 디렉토리 모두에서 찾음)
        latest=$(find "$dir" -type f \( -name "*.sql.gz" -o -name "*.dump" \) -o -type d -name "*.dir" \
                 -printf '%T+\n' 2>/dev/null | sort -r | head -1 | cut -d. -f1) # sort -r을 사용하여 가장 최신 항목을 찾음
        
        printf "%-15s %-10s %-15s %-20s\n" "$type" "$count" "$size" "${latest:-N/A}"
    fi
done
echo ""

# 3. 최근 백업 작업
echo "RECENT BACKUP OPERATIONS"
echo "───────────────────────────"
LOG_FILE="${BACKUP_BASE_DIR}/logs/backup_$(date +%Y%m%d).log"

if [ -f "$LOG_FILE" ]; then
    # 로그 파일이 존재하는 경우, 성공/실패/경고 메시지 출력
    tail -10 "$LOG_FILE" 2>/dev/null | grep -E "SUCCESS|ERROR|WARNING" || echo "No recent SUCCESS/ERROR/WARNING entries in today's log."
else
    echo "Today's log file ($LOG_FILE) not found."
fi
echo ""

# 4. 다음 스케줄
echo "NEXT SCHEDULED BACKUPS"
echo "─────────────────────────"
# crontab 파일을 직접 검색하여 더 유연하게 스케줄을 찾습니다.
CRON_FILE_PATHS=("/etc/cron.d/*postgres*backup*" "/etc/cron.d/*pg_backup*" "/etc/crontab" "/var/spool/cron/crontabs/$USER" "/var/spool/cron/crontabs/root")
FOUND_SCHEDULE=false

for job_path in "${CRON_FILE_PATHS[@]}"; do
    if [ -f "$job_path" ] || [ -d "$job_path" ]; then
        # 파일 또는 디렉토리 내의 파일에서 백업 관련 명령어 검색
        grep -E "pg_backup|pg_dump|pg_basebackup|backup_manager" "$job_path" 2>/dev/null | while read line; do
            # 주석이 아닌 라인만 처리
            if [[ ! "$line" =~ ^# ]]; then
                schedule=$(echo "$line" | awk '{print $1" "$2" "$3" "$4" "$5}')
                command_raw=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | xargs) # 사용자, 명령 분리
                
                # cron.d 파일 형식 처리: 사용자 필드가 있는 경우 제외
                if [ -z "$schedule" ] || [ "$schedule" == "$(echo "$line" | awk '{print $1}')" ]; then
                    # crontab 파일 (사용자가 이미 지정된 경우)
                    schedule=$(echo "$line" | awk '{print $1" "$2" "$3" "$4" "$5}')
                    command_raw=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | xargs)
                fi

                # 명령에서 스크립트 파일 이름만 추출
                command_name=$(basename $(echo "$command_raw" | awk '{print $1}'))
                
                echo "File: $job_path"
                echo "Schedule: $schedule"
                echo "Command: $command_name"
                echo ""
                FOUND_SCHEDULE=true
            fi
        done
    fi
done

if [ "$FOUND_SCHEDULE" == "false" ]; then
    echo "No PostgreSQL backup schedule found in common cron paths."
fi

echo "==============================================================="
echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"

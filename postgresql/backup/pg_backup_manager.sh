#!/bin/bash
# /usr/local/bin/pg_backup_manager.sh
# PostgreSQL 16 Enterprise Backup Manager

set -euo pipefail

#=============================================================================
# 백업 정책 설정
#=============================================================================
# 백업 기본 경로
BACKUP_BASE_DIR="/data/backup"
BACKUP_DAILY_DIR="${BACKUP_BASE_DIR}/daily"
BACKUP_WEEKLY_DIR="${BACKUP_BASE_DIR}/weekly"
BACKUP_MONTHLY_DIR="${BACKUP_BASE_DIR}/monthly"
BACKUP_LOG_DIR="${BACKUP_BASE_DIR}/logs"
BACKUP_TEMP_DIR="${BACKUP_BASE_DIR}/temp"

# 보관 정책 (일 단위)
DAILY_RETENTION=7       # 일일 백업 7일 보관
WEEKLY_RETENTION=28      # 주간 백업 4주 보관
MONTHLY_RETENTION=365    # 월간 백업 12개월 보관

# 데이터베이스 연결 정보
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_USER="postgres"
export PGPASSWORD='asdf1234!!'

# 백업 옵션
COMPRESSION_LEVEL=9      # 압축 레벨 (1-9, 9가 최대 압축, pg_dump -Z 옵션)
PARALLEL_JOBS=4          # 병렬 처리 작업 수 (pg_dump -j 옵션)
# NOTE: 병렬(-j) 사용 시, pg_dump는 반드시 디렉토리 포맷(-Fd)을 사용해야 합니다.
BACKUP_FORMAT="directory" # directory(-Fd) 또는 custom(-Fc) 권장. (custom, plain, directory, tar)

# 알림 설정
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK_URL=""     # Slack 알림용 (선택사항)

# 타임스탬프
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TODAY=$(date +%Y%m%d)
DAY_OF_WEEK=$(date +%u)  # 1=월요일, 7=일요일
DAY_OF_MONTH=$(date +%d)

# PostgreSQL 버전 확인 (버전 독립성을 위해 동적 확인)
PG_VERSION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -t -c "SHOW server_version;" 2>/dev/null | cut -d' ' -f1 | xargs)
if [ -z "$PG_VERSION" ]; then
    echo "[ERROR] PostgreSQL 서버 버전을 확인할 수 없습니다. 연결 정보를 확인하세요." >&2
    # 연결 실패 시 강제 종료
    exit 1
fi

# -----------------------------------------------------------------------------
# 기능별 버전 호환성 체크
# -----------------------------------------------------------------------------

# 병렬 옵션(-j) 사용 가능 여부 (PostgreSQL 9.3+ 및 directory/tar 포맷)
# NOTE: 여기서는 BACKUP_FORMAT이 'directory'로 설정되어 있어야만 유효합니다.
is_parallel_supported() {
    # 예: 9.3보다 크거나 같으면 true (pg_dump -j는 9.3에서 도입)
    if echo "$PG_VERSION" | grep -qE '^(1[0-9]|9\.[3-9])'; then
        return 0 # true
    fi
    return 1 # false
}

# 압축 레벨(-Z) 옵션 사용 가능 여부 (PostgreSQL 9.5+)
is_compression_level_supported() {
    # 예: 9.5보다 크거나 같으면 true (pg_dump -Z는 9.5에서 도입)
    if echo "$PG_VERSION" | grep -qE '^(1[0-9]|9\.[5-9])'; then
        return 0 # true
    fi
    return 1 # false
}

# pg_basebackup의 타르 압축(-z) 및 --checkpoint=fast 옵션 (PostgreSQL 9.5+)
is_basebackup_advanced_supported() {
    # 예: 9.5보다 크거나 같으면 true
    if echo "$PG_VERSION" | grep -qE '^(1[0-9]|9\.[5-9])'; then
        return 0 # true
    fi
    return 1 # false
}


#=============================================================================
# 함수 정의
#=============================================================================

# 로깅 함수
log_message() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "${BACKUP_LOG_DIR}/backup_${TODAY}.log"
}

# 디렉토리 초기화
init_directories() {
    log_message "INFO" "Initializing backup directories..."
    for dir in "$BACKUP_DAILY_DIR" "$BACKUP_WEEKLY_DIR" "$BACKUP_MONTHLY_DIR" "$BACKUP_LOG_DIR" "$BACKUP_TEMP_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_message "INFO" "Created directory: $dir"
        fi
    done
    
    # 권한 설정
    chown -R postgres:postgres "$BACKUP_BASE_DIR"
    chmod -R 750 "$BACKUP_BASE_DIR"
}

# 디스크 공간 체크
check_disk_space() {
    local required_space=$1  # GB 단위
    local available_space=$(df -BG "$BACKUP_BASE_DIR" | awk 'NR==2 {print int($4)}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_message "ERROR" "Insufficient disk space. Required: ${required_space}GB, Available: ${available_space}GB"
        send_alert "ERROR" "Backup failed: Insufficient disk space"
        exit 1
    fi
    log_message "INFO" "Disk space check passed. Available: ${available_space}GB"
}

# 데이터베이스 크기 확인
get_database_size() {
    local db_name=$1
    local size=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -t -c \
        "SELECT pg_size_pretty(pg_database_size('$db_name'));" 2>/dev/null | xargs)
    echo "$size"
}


# 전체 백업 (pg_dumpall)
perform_full_backup() {
    local backup_type=$1  # daily, weekly, monthly
    local backup_dir=""
    
    case $backup_type in
        daily)   backup_dir="$BACKUP_DAILY_DIR" ;;
        weekly)  backup_dir="$BACKUP_WEEKLY_DIR" ;;
        monthly) backup_dir="$BACKUP_MONTHLY_DIR" ;;
    esac
    
    # pg_dumpall은 항상 Plain Text SQL로 출력되므로 gzip 압축을 사용
    local backup_file="${backup_dir}/full_backup_${TIMESTAMP}.sql.gz"
    
    log_message "INFO" "Starting $backup_type full backup..."
    log_message "INFO" "Backup file: $backup_file"
    
    # 백업 실행: pg_dumpall은 버전 독립성이 높음
    if pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        --clean --if-exists --verbose 2>>"${BACKUP_LOG_DIR}/backup_${TODAY}.log" | \
        gzip -${COMPRESSION_LEVEL} > "$backup_file"; then # gzip은 표준 유틸리티
        
        local file_size=$(du -h "$backup_file" | cut -f1)
        log_message "SUCCESS" "Full backup completed. Size: $file_size"
        verify_backup "$backup_file" "full"
        save_backup_metadata "$backup_file" "$backup_type" "full"
        return 0
    else
        log_message "ERROR" "Full backup failed!"
        send_alert "ERROR" "Full backup failed for $backup_type"
        return 1
    fi
}


# 개별 데이터베이스 백업
perform_database_backup() {
    local db_name=$1
    local backup_type=$2
    local backup_dir=""
    local dump_options="-Fc" # 기본: Custom Format
    
    case $backup_type in
        daily)   backup_dir="$BACKUP_DAILY_DIR" ;;
        weekly)  backup_dir="$BACKUP_WEEKLY_DIR" ;;
        monthly) backup_dir="$BACKUP_MONTHLY_DIR" ;;
    esac
    
    # NOTE: 병렬 작업 설정 시, 포맷을 디렉토리(-Fd)로 변경해야 합니다.
    if is_parallel_supported && [ "$BACKUP_FORMAT" == "directory" ]; then
        dump_options="-Fd -j $PARALLEL_JOBS"
    else
        # 병렬을 지원하지 않거나 custom 포맷이 지정된 경우
        # custom 포맷은 대부분의 버전에서 안정적입니다.
        dump_options="-Fc" 
    fi

    # 압축 레벨 옵션 추가 (9.5+ 지원)
    if is_compression_level_supported; then
        dump_options+=" -Z $COMPRESSION_LEVEL"
    fi

    # 디렉토리 포맷이면 폴더, 아니면 단일 파일.
    if [[ "$dump_options" == *"-Fd"* ]]; then
        local backup_file="${backup_dir}/${db_name}_${TIMESTAMP}.dir"
        mkdir -p "$backup_file"
    else
        local backup_file="${backup_dir}/${db_name}_${TIMESTAMP}.dump"
    fi
    
    log_message "INFO" "Starting backup of database: $db_name (Format: $dump_options)"
    
    # pg_dump 실행
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -d "$db_name" \
        $dump_options \
        --verbose \
        -f "$backup_file" 2>>"${BACKUP_LOG_DIR}/backup_${TODAY}.log"; then
        
        # ... (중략) 성공 로그 및 검증
        return 0
    else
        log_message "ERROR" "Database backup failed: $db_name. 옵션: $dump_options"
        return 1
    fi
}

# 물리적 백업 (pg_basebackup)
perform_physical_backup() {
    local backup_type=$1
    local backup_dir=""
    local basebackup_options="-Ft -Xs -P" # 기본 옵션 (9.1+ 지원)
    
    case $backup_type in
        daily)   backup_dir="$BACKUP_DAILY_DIR" ;;
        weekly)  backup_dir="$BACKUP_WEEKLY_DIR" ;;
        monthly) backup_dir="$BACKUP_MONTHLY_DIR" ;;
    esac
    
    local backup_path="${backup_dir}/physical_${TIMESTAMP}"
    
    log_message "INFO" "Starting physical backup..."
    
    # 고급 옵션 (타르 압축, 빠른 체크포인트) 추가 (9.5+ 지원)
    if is_basebackup_advanced_supported; then
        basebackup_options+=" -z --checkpoint=fast"
    fi
    
    if pg_basebackup -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -D "$backup_path" \
        $basebackup_options 2>>"${BACKUP_LOG_DIR}/backup_${TODAY}.log"; then
        
        # ... (중략) 성공 로그 및 메타데이터 저장
        return 0
    else
        log_message "ERROR" "Physical backup failed!"
        return 1
    fi
}

# 백업 검증
verify_backup() {
    local backup_file=$1
    local backup_mode=$2
    
    log_message "INFO" "Verifying backup: $backup_file"
    
    case $backup_mode in
        full)
            # SQL 백업 검증
            if gzip -t "$backup_file" 2>/dev/null; then
                log_message "SUCCESS" "Backup verification passed (gzip integrity)"
            else
                log_message "ERROR" "Backup verification failed!"
                return 1
            fi
            ;;
        database)
            # Custom format 백업 검증
            if pg_restore --list "$backup_file" >/dev/null 2>&1; then
                log_message "SUCCESS" "Backup verification passed (pg_restore check)"
            else
                log_message "ERROR" "Backup verification failed!"
                return 1
            fi
            ;;
    esac
}

# 백업 메타데이터 저장 (PostgreSQL 버전을 동적으로 기록)
save_backup_metadata() {
    local backup_path=$1
    local backup_type=$2
    local backup_mode=$3
    local db_name=${4:-"all"}
    
    local metadata_file="${BACKUP_BASE_DIR}/backup_metadata.json"
    local file_size=$(du -b "$backup_path" 2>/dev/null | cut -f1)
    local checksum=$(sha256sum "$backup_path" 2>/dev/null | cut -d' ' -f1 || echo "N/A") # sha256sum 에러 방지
    
    # JSON 형식으로 메타데이터 추가
    cat >> "$metadata_file" <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "backup_type": "$backup_type",
    "backup_mode": "$backup_mode",
    "database": "$db_name",
    "file_path": "$backup_path",
    "file_size_bytes": $file_size,
    "checksum_sha256": "$checksum",
    "postgresql_version": "$PG_VERSION",
    "retention_days": $(get_retention_days $backup_type)
}
EOF
}

# 보관 기간 가져오기
get_retention_days() {
    local backup_type=$1
    case $backup_type in
        daily)   echo "$DAILY_RETENTION" ;;
        weekly)  echo "$WEEKLY_RETENTION" ;;
        monthly) echo "$MONTHLY_RETENTION" ;;
    esac
}

# 오래된 백업 정리
cleanup_old_backups() {
    log_message "INFO" "Starting cleanup of old backups..."
    
    # 일일 백업 정리
    find "$BACKUP_DAILY_DIR" -type f -mtime +${DAILY_RETENTION} -name "*.sql.gz" -o -name "*.dump" | while read file; do
        log_message "INFO" "Removing old daily backup: $file"
        rm -f "$file"
    done
    
    # 주간 백업 정리
    find "$BACKUP_WEEKLY_DIR" -type f -mtime +${WEEKLY_RETENTION} -name "*.sql.gz" -o -name "*.dump" | while read file; do
        log_message "INFO" "Removing old weekly backup: $file"
        rm -f "$file"
    done
    
    # 월간 백업 정리
    find "$BACKUP_MONTHLY_DIR" -type f -mtime +${MONTHLY_RETENTION} -name "*.sql.gz" -o -name "*.dump" | while read file; do
        log_message "INFO" "Removing old monthly backup: $file"
        rm -f "$file"
    done
    
    # 오래된 로그 정리 (30일 이상)
    find "$BACKUP_LOG_DIR" -type f -mtime +30 -name "*.log" -delete
    
    log_message "INFO" "Cleanup completed"
}

# 백업 보고서 생성
generate_backup_report() {
    local report_file="${BACKUP_LOG_DIR}/backup_report_${TODAY}.html"
    
    cat > "$report_file" <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>PostgreSQL Backup Report - ${TODAY}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #336699; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #336699; color: white; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>PostgreSQL Backup Report</h1>
    <p>Date: $(date '+%Y-%m-%d %H:%M:%S')</p>
    
    <h2>Backup Summary</h2>
    <table>
        <tr><th>Type</th><th>Count</th><th>Total Size</th><th>Oldest</th><th>Newest</th></tr>
        <tr>
            <td>Daily</td>
            <td>$(find $BACKUP_DAILY_DIR -type f -name "*.sql.gz" -o -name "*.dump" 2>/dev/null | wc -l)</td>
            <td>$(du -sh $BACKUP_DAILY_DIR 2>/dev/null | cut -f1)</td>
            <td>$(find $BACKUP_DAILY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f1)</td>
            <td>$(find $BACKUP_DAILY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | tail -1 | cut -d' ' -f1)</td>
        </tr>
        <tr>
            <td>Weekly</td>
            <td>$(find $BACKUP_WEEKLY_DIR -type f -name "*.sql.gz" -o -name "*.dump" 2>/dev/null | wc -l)</td>
            <td>$(du -sh $BACKUP_WEEKLY_DIR 2>/dev/null | cut -f1)</td>
            <td>$(find $BACKUP_WEEKLY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f1)</td>
            <td>$(find $BACKUP_WEEKLY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | tail -1 | cut -d' ' -f1)</td>
        </tr>
        <tr>
            <td>Monthly</td>
            <td>$(find $BACKUP_MONTHLY_DIR -type f -name "*.sql.gz" -o -name "*.dump" 2>/dev/null | wc -l)</td>
            <td>$(du -sh $BACKUP_MONTHLY_DIR 2>/dev/null | cut -f1)</td>
            <td>$(find $BACKUP_MONTHLY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f1)</td>
            <td>$(find $BACKUP_MONTHLY_DIR -type f -printf '%T+ %p\n' 2>/dev/null | sort | tail -1 | cut -d' ' -f1)</td>
        </tr>
    </table>
    
    <h2>Disk Usage</h2>
    <pre>$(df -h $BACKUP_BASE_DIR)</pre>
    
    <h2>Recent Backup Operations</h2>
    <pre>$(tail -20 ${BACKUP_LOG_DIR}/backup_${TODAY}.log 2>/dev/null || echo "No logs available")</pre>
</body>
</html>
HTML
    
    log_message "INFO" "Backup report generated: $report_file"
}

# 알림 전송
send_alert() {
    local level=$1
    local message=$2
    
    # 이메일 알림 (mail 명령어가 설치되어 있어야 함)
    if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "[PostgreSQL Backup] $level: $message" "$ALERT_EMAIL"
    fi
    
    # Slack 알림
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[PostgreSQL Backup] $level: $message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null
    fi
}

# 백업 복구 테스트
test_backup_restore() {
    local backup_file=$1
    local test_db="test_restore_$(date +%s)"
    
    log_message "INFO" "Testing backup restore with file: $backup_file"
    
    # 테스트 데이터베이스 생성
    createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$test_db" 2>/dev/null
    
    # 복구 시도
    if pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$test_db" "$backup_file" 2>/dev/null; then
        log_message "SUCCESS" "Restore test passed"
        # 테스트 데이터베이스 삭제
        dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$test_db" 2>/dev/null
        return 0
    else
        log_message "WARNING" "Restore test failed or not applicable"
        dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$test_db" 2>/dev/null || true
        return 1
    fi
}

#=============================================================================
# 메인 실행 로직
#=============================================================================

main() {
    local backup_mode=${1:-auto}  # auto, manual, full, database
    
    log_message "INFO" "========================================="
    log_message "INFO" "PostgreSQL Backup Manager Started"
    log_message "INFO" "Mode: $backup_mode"
    log_message "INFO" "========================================="
    
    # 디렉토리 초기화
    init_directories
    
    # 디스크 공간 체크 (최소 10GB 필요)
    check_disk_space 10
    
    case $backup_mode in
        auto)
            # 자동 백업 (스케줄에 따라)
            # 일일 백업
            perform_full_backup "daily"
            
            # 일요일마다 주간 백업 (일요일 = 7)
            if [ "$DAY_OF_WEEK" -eq 7 ]; then
                log_message "INFO" "Performing weekly backup..."
                perform_full_backup "weekly"
            fi
            
            # 매월 1일 월간 백업
            if [ "$DAY_OF_MONTH" -eq 1 ]; then
                log_message "INFO" "Performing monthly backup..."
                perform_full_backup "monthly"
                
                # 물리적 백업도 수행
                perform_physical_backup "monthly"
            fi
            ;;
            
        full)
            # 전체 백업 수동 실행
            perform_full_backup "daily"
            ;;
            
        database)
            # 특정 데이터베이스 백업
            local db_name=${2:-postgres}
            perform_database_backup "$db_name" "daily"
            ;;
            
        physical)
            # 물리적 백업
            perform_physical_backup "daily"
            ;;
    esac
    
    # 오래된 백업 정리
    cleanup_old_backups
    
    # 백업 보고서 생성
    generate_backup_report
    
    # 디스크 사용량 체크
    local disk_usage=$(df -h "$BACKUP_BASE_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        log_message "WARNING" "Disk usage is above 80%: ${disk_usage}%"
        send_alert "WARNING" "Backup disk usage is ${disk_usage}%"
    fi
    
    log_message "INFO" "========================================="
    log_message "INFO" "Backup Manager Completed Successfully"
    log_message "INFO" "========================================="
}

# 스크립트 실행
main "$@"

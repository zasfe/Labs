#!/bin/bash
# /usr/local/bin/pg_restore_manager.sh
# PostgreSQL Restore Manager

set -euo pipefail

# 설정
BACKUP_BASE_DIR="/data/backup"
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_USER="postgres"
export PGPASSWORD='asdf1234!!' # 실제 환경에서는 보안을 위해 .pgpass 사용을 권장합니다.

# ----------------------------------------------------------------
# 복구 함수
# ----------------------------------------------------------------

# 전체 백업 복구 (pg_dumpall 또는 Plain Text SQL 파일용)
# Plain text SQL 파일은 psql을 통해 복구됩니다.
restore_full_backup() {
    local backup_file=$1
    
    echo "================================================"
    echo "PostgreSQL Full Restore (via psql)"
    echo "Backup File: $backup_file"
    echo "================================================"
    
    # 확인 프롬프트
    read -p "WARNING: This will overwrite ALL databases and global objects (roles, tablespaces). Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled."
        exit 1
    fi
    
    # 기존 연결 종료 (8.4+ 버전에서 사용 가능)
    echo "Terminating existing connections..."
    # -d postgres: 시스템 DB에 연결하여 모든 DB의 연결을 종료
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname IS NOT NULL AND pid <> pg_backend_pid();"
    
    # 복구 실행
    # Plain text SQL 백업 파일 복원 시에는 psql을 사용합니다.
    echo "Starting psql restore..."
    if [[ "$backup_file" == *.gz ]]; then
        # 압축된 SQL 파일 복원
        gunzip -c "$backup_file" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1
    else
        # 일반 SQL 파일 복원
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -f "$backup_file" -v ON_ERROR_STOP=1
    fi
    
    # $?를 통해 이전 명령어의 종료 상태 확인
    if [ $? -eq 0 ]; then
        echo "Restore completed successfully! 🚀"
    else
        echo "ERROR: Restore failed! Check log for details." >&2
        exit 1
    fi
}

# 개별 데이터베이스 백업 복구 (Custom/Directory/Tar 포맷 파일용)
# pg_dump -Fc, -Fd, -Ft로 생성된 파일은 pg_restore를 통해 복구됩니다.
restore_database_backup() {
    local backup_file=$1
    local target_db=$2
    
    echo "================================================"
    echo "PostgreSQL Database Restore (via pg_restore)"
    echo "Backup File: $backup_file"
    echo "Target Database: $target_db"
    echo "================================================"

    if [[ "$backup_file" == *.sql.gz || "$backup_file" == *.sql ]]; then
        echo "ERROR: This is likely a Plain Text SQL file. Use 'restore_full_backup' or Menu Option 5/2/3/4." >&2
        exit 1
    fi

    # 데이터베이스 재생성
    # dropdb --if-exists는 9.4부터 지원. 범용성을 위해 간단한 에러 처리를 추가.
    echo "Dropping and recreating database: $target_db"
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db" 2>/dev/null || true # 에러 무시
    createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db"

    # 복구 실행
    # -j (병렬 처리) 옵션은 9.3 미만에서 비호환성 문제 발생 가능성 때문에 제거
    # -v (--verbose) 옵션을 추가하여 복구 진행 상황을 상세히 출력
    # -c (--clean) 옵션을 추가하여 복원 전 객체를 제거하여 충돌 방지 (안전한 복구)
    echo "Starting pg_restore..."
    if pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -d "$target_db" \
        -c \
        -v \
        "$backup_file"; then
        
        echo "Database restore completed successfully! ✨"
    else
        echo "ERROR: pg_restore failed! Check the PostgreSQL log for connection, permission, or file format errors." >&2
        exit 1
    fi
}

# 최신 백업 찾기
find_latest_backup() {
    local backup_type=$1  # daily, weekly, monthly
    local backup_dir="${BACKUP_BASE_DIR}/${backup_type}"
    
    # 디렉토리 포맷(.dir)도 백업 파일로 간주하도록 find 조건 수정
    find "$backup_dir" -type f -name "*.sql.gz" -o -type f -name "*.dump" -o -type d -name "*.dir" -printf '%T@ %p\n' | \
        sort -n | tail -1 | cut -d' ' -f2
}

# 백업 목록 표시
list_backups() {
    echo "Available Backups:"
    echo "=================="
    
    for type in daily weekly monthly; do
        echo ""
        echo "[$type backups]"
        # 디렉토리 포맷도 표시하도록 grep 조건 수정
        ls -lh "${BACKUP_BASE_DIR}/${type}/" 2>/dev/null | grep -E "\.(sql\.gz|dump|dir)$" || echo "  No backups found"
    done
}

# 메인 메뉴
main_menu() {
    echo ""
    echo "PostgreSQL Restore Manager"
    echo "========================="
    echo "1. List all backups"
    echo "2. Restore latest daily backup"
    echo "3. Restore latest weekly backup"
    echo "4. Restore latest monthly backup"
    echo "5. Restore specific backup file"
    echo "6. Restore specific database"
    echo "0. Exit"
    echo ""
    read -p "Select option: " option
    
    case $option in
        1)
            list_backups
            main_menu
            ;;
        2)
            backup_file=$(find_latest_backup "daily")
            if [ -n "$backup_file" ]; then
                restore_full_backup "$backup_file"
            else
                echo "No daily backup found!"
            fi
            ;;
        3)
            backup_file=$(find_latest_backup "weekly")
            if [ -n "$backup_file" ]; then
                restore_full_backup "$backup_file"
            else
                echo "No weekly backup found!"
            fi
            ;;
        4)
            backup_file=$(find_latest_backup "monthly")
            if [ -n "$backup_file" ]; then
                restore_full_backup "$backup_file"
            else
                echo "No monthly backup found!"
            fi
            ;;
        5)
            read -p "Enter backup file path (SQL/GZ/DUMP/DIR): " backup_file
            if [ -d "$backup_file" ] || [ -f "$backup_file" ]; then
                # 파일 확장자 또는 디렉토리 이름으로 복원 방식 구분
                if [[ "$backup_file" == *.sql.gz || "$backup_file" == *.sql ]]; then
                    restore_full_backup "$backup_file" # Plain Text SQL은 psql로 복구
                else
                    # Custom, Directory, Tar 포맷은 pg_restore로 복구해야 함.
                    # 그러나 전체 복구 옵션은 '단일 데이터베이스' 백업 파일을 
                    # '단일 DB'로 복구하는 것이므로, Menu Option 6을 사용하도록 유도
                    echo "---"
                    echo "WARNING: This file is an archive format (.dump/.dir)."
                    echo "To restore an archive, you must specify the target database (Menu Option 6)."
                    echo "---"
                fi
            else
                echo "File or Directory not found!"
            fi
            main_menu
            ;;
        6)
            read -p "Enter archive backup path (.dump or .dir): " backup_file
            read -p "Enter target database name (e.g. new_db): " db_name
            if [ -d "$backup_file" ] || [ -f "$backup_file" ]; then
                restore_database_backup "$backup_file" "$db_name"
            else
                echo "File or Directory not found!"
            fi
            main_menu
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option!"
            main_menu
            ;;
    esac
}

# 실행
if [ $# -eq 0 ]; then
    main_menu
else
    case $1 in
        --list)
            list_backups
            ;;
        --restore-full) # 전체 복구는 명확히 지정하도록 옵션명 변경
            if [ -n "${2:-}" ]; then
                restore_full_backup "$2"
            else
                echo "Usage: $0 --restore-full <plain_text_sql_file>"
            fi
            ;;
        --restore-db) # 단일 DB 복구 옵션 추가
            if [ -n "${2:-}" ] && [ -n "${3:-}" ]; then
                restore_database_backup "$2" "$3"
            else
                echo "Usage: $0 --restore-db <archive_file_or_dir> <target_db>"
            fi
            ;;
        --help)
            echo "Usage: $0 [--list|--restore-full <sql_file>|--restore-db <archive_file_or_dir> <target_db>|--help]"
            ;;
        *)
            main_menu
            ;;
    esac
fi

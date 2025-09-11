#!/bin/bash
# /usr/local/bin/pg_restore_manager.sh
# PostgreSQL Restore Manager

set -euo pipefail

# 설정
BACKUP_BASE_DIR="/data/backup"
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_USER="postgres"
export PGPASSWORD='asdf1234!!'

# 복구 함수
restore_full_backup() {
    local backup_file=$1
    
    echo "================================================"
    echo "PostgreSQL Full Restore"
    echo "Backup File: $backup_file"
    echo "================================================"
    
    # 확인 프롬프트
    read -p "WARNING: This will overwrite all databases. Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled."
        exit 1
    fi
    
    # 기존 연결 종료
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid();"
    
    # 복구 실행
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -f "$backup_file"
    fi
    
    echo "Restore completed successfully!"
}

restore_database_backup() {
    local backup_file=$1
    local target_db=$2
    
    echo "================================================"
    echo "PostgreSQL Database Restore"
    echo "Backup File: $backup_file"
    echo "Target Database: $target_db"
    echo "================================================"
    
    # 데이터베이스 재생성
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --if-exists "$target_db"
    createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$target_db"
    
    # 복구 실행
    pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -d "$target_db" \
        -j 4 \
        --verbose \
        "$backup_file"
    
    echo "Database restore completed!"
}

# 최신 백업 찾기
find_latest_backup() {
    local backup_type=$1  # daily, weekly, monthly
    local backup_dir="${BACKUP_BASE_DIR}/${backup_type}"
    
    find "$backup_dir" -type f \( -name "*.sql.gz" -o -name "*.dump" \) -printf '%T@ %p\n' | \
        sort -n | tail -1 | cut -d' ' -f2
}

# 백업 목록 표시
list_backups() {
    echo "Available Backups:"
    echo "=================="
    
    for type in daily weekly monthly; do
        echo ""
        echo "[$type backups]"
        ls -lh "${BACKUP_BASE_DIR}/${type}/" 2>/dev/null | grep -E "\.(sql\.gz|dump)$" || echo "  No backups found"
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
            read -p "Enter backup file path: " backup_file
            if [ -f "$backup_file" ]; then
                restore_full_backup "$backup_file"
            else
                echo "File not found!"
            fi
            ;;
        6)
            read -p "Enter backup file path: " backup_file
            read -p "Enter target database name: " db_name
            if [ -f "$backup_file" ]; then
                restore_database_backup "$backup_file" "$db_name"
            else
                echo "File not found!"
            fi
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
        --restore)
            if [ -n "${2:-}" ]; then
                restore_full_backup "$2"
            else
                echo "Usage: $0 --restore <backup_file>"
            fi
            ;;
        --help)
            echo "Usage: $0 [--list|--restore <file>|--help]"
            ;;
        *)
            main_menu
            ;;
    esac
fi

#!/bin/bash
# pg_backup_verify.sh - PostgreSQL 당일 백업 무결성 검증 스크립트

# 코드 목적: PostgreSQL 버전에 상관없이 당일(오늘) 생성된 백업 파일들을 대상으로
#            pg_restore를 사용하여 무결성을 검사합니다.
#            버전, 데이터 경로, 포트 등은 실행 중인 프로세스에서 동적으로 감지합니다.
# 필요한 명령 패키지: pgrep, ps, awk, find, date, gzip, pg_restore (postgresql-client 패키지)

set -euo pipefail

# --- 환경 설정 ---
DB_USER="postgres"
BACKUP_BASE_DIR="/data/backup"
TODAY=$(date +%Y%m%d)

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==============================================================="
echo " PostgreSQL Backup Integrity Verification ($TODAY)"
echo "==============================================================="

# 1. 실행 중인 PostgreSQL 인스턴스 정보 추출
PG_PID=$(pgrep -u "$DB_USER" -f '^postgres: .*-D' | head -1 || echo '')

if [ -z "$PG_PID" ]; then
    echo -e "${RED}FATAL: No active PostgreSQL process found running as user '$DB_USER'. Aborting verification.${NC}"
    exit 1
fi

# 프로세스 명령줄에서 포트, 데이터 디렉토리, 바이너리 경로 추출
CMD_LINE=$(ps -p "$PG_PID" -o cmd --no-header)
PG_PORT=$(echo "$CMD_LINE" | grep -o '\-p [0-9]\+' | awk '{print $2}' || echo "5432")
PG_DATA_DIR=$(echo "$CMD_LINE" | grep -o '\-D [^[:space:]]\+' | awk '{print $2}' || echo "")
PG_BIN_PATH=$(readlink -f /proc/"$PG_PID"/exe)
PG_BIN_DIR=$(dirname "$PG_BIN_PATH")

if [ ! -d "$PG_DATA_DIR" ]; then
    echo -e "${RED}FATAL: Data directory ($PG_DATA_DIR) not found. Cannot proceed.${NC}"
    exit 1
fi

# pg_restore의 정확한 경로를 동적으로 찾거나, PATH 사용
PG_RESTORE_BIN=$(which pg_restore 2>/dev/null || echo "$PG_BIN_DIR/pg_restore")

if [ ! -x "$PG_RESTORE_BIN" ]; then
    echo -e "${RED}FATAL: pg_restore binary not found at $PG_RESTORE_BIN. Install postgresql-client.${NC}"
    exit 1
fi

echo -e " Running Instance Details:"
echo -e "   Port: ${PG_PORT}"
echo -e "   Binary Dir: ${PG_BIN_DIR}"
echo -e "   pg_restore: ${PG_RESTORE_BIN}"
echo "---------------------------------------------------------------"

# 2. 당일 백업 파일 목록 검색
echo -e "${YELLOW}Searching for today's backup files ($TODAY) in $BACKUP_BASE_DIR...${NC}"

# 백업 파일 패턴 (gz 압축 SQL, Custom 포맷, Directory 포맷)
BACKUP_PATTERNS=("*.sql.gz" "*.dump" "*.dir")
BACKUP_FILES=()

# find 명령을 사용하여 당일 생성된 파일을 찾음
for type in daily weekly monthly; do
    DIR="${BACKUP_BASE_DIR}/${type}"
    if [ -d "$DIR" ]; then
        # -mtime 0 대신 -newermt 를 사용하여 오늘 생성된 파일/디렉토리를 찾음
        # 이 명령어는 당일 00:00:00 이후에 수정된 항목을 찾습니다.
        while IFS= read -r FILE; do
            BACKUP_FILES+=("$FILE")
        done < <(find "$DIR" -newermt "$TODAY" -type f \( -name "*.sql.gz" -o -name "*.dump" \) 2>/dev/null)

        # Directory 포맷 백업 (.dir)도 검증 대상에 포함
        while IFS= read -r DIR_ENTRY; do
            BACKUP_FILES+=("$DIR_ENTRY")
        done < <(find "$DIR" -newermt "$TODAY" -type d -name "*.dir" 2>/dev/null)
    fi
done

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No backup files or directories found created on $TODAY. Skipping verification.${NC}"
    echo "==============================================================="
    exit 0
fi

echo -e " Found ${#BACKUP_FILES[@]} backup targets."

# 3. 각 백업 파일 무결성 검증
VERIFICATION_STATUS=0 # 0=SUCCESS, 1=FAILURE

for FILE_PATH in "${BACKUP_FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH")
    echo -e "\n${YELLOW}>> Verifying: $FILENAME${NC}"

    VERIFY_CMD=""
    IS_FILE=true

    if [[ "$FILENAME" == *.sql.gz ]]; then
        # .sql.gz 파일은 zcat으로 압축 해제 후 /dev/null로 리다이렉션 (SQL 문법 검사는 불가능, 압축 해제만 검증)
        echo "   (Type: SQL/Gzip) Checking Gzip integrity..."
        if gzip -t "$FILE_PATH" 2>/dev/null; then
            echo -e "   ${GREEN}SUCCESS: Gzip integrity check passed.${NC}"
        else
            echo -e "   ${RED}FAILURE: Gzip file is corrupted.${NC}"
            VERIFICATION_STATUS=1
            continue
        fi

    elif [[ "$FILENAME" == *.dump || "$FILE_PATH" == *.dir ]]; then
        # .dump 파일 (Custom/Tar 포맷) 또는 .dir 디렉토리 (Directory 포맷)는 pg_restore 사용
        FORMAT_TYPE="custom"
        if [ -d "$FILE_PATH" ]; then
            FORMAT_TYPE="directory"
            IS_FILE=false
        fi

        # -l 옵션으로 내용물 목록만 확인 (실제 복구 불필요)
        # -F 옵션으로 포맷 지정 (pg_restore는 디렉토리 포맷을 자동으로 인식)
        echo "   (Type: $FORMAT_TYPE) Checking $FILENAME structure using pg_restore..."
        
        if [ "$FORMAT_TYPE" == "directory" ]; then
             VERIFY_CMD="$PG_RESTORE_BIN --list --verbose -F d --dbname=postgres -p $PG_PORT --username=$DB_USER -d '$FILE_PATH' 2>&1"
        else
             VERIFY_CMD="$PG_RESTORE_BIN --list --verbose -F c --dbname=postgres -p $PG_PORT --username=$DB_USER '$FILE_PATH' 2>&1"
        fi
        
        # pg_restore --list 실행
        if [ "$FORMAT_TYPE" == "directory" ]; then
            # 디렉토리 포맷은 -F d 대신 -d (디렉토리) 옵션을 사용해야 함
            if sudo -u "$DB_USER" "$PG_RESTORE_BIN" --list -F d -d "$FILE_PATH" --jobs=1 --verbose 2>&1 | grep -iE "error|fatal|warning" | grep -vE "NOTICE|WARNING: (too many|could not be written)"; then
                echo -e "   ${RED}FAILURE: pg_restore list failed or showed critical errors.${NC}"
                VERIFICATION_STATUS=1
            else
                echo -e "   ${GREEN}SUCCESS: pg_restore structure check passed (Custom/Directory).${NC}"
            fi
        else
             # Custom/Tar 포맷은 -f 옵션을 사용
            if sudo -u "$DB_USER" "$PG_RESTORE_BIN" --list -F c "$FILE_PATH" --jobs=1 --verbose 2>&1 | grep -iE "error|fatal|warning" | grep -vE "NOTICE|WARNING: (too many|could not be written)"; then
                echo -e "   ${RED}FAILURE: pg_restore list failed or showed critical errors.${NC}"
                VERIFICATION_STATUS=1
            else
                echo -e "   ${GREEN}SUCCESS: pg_restore structure check passed (Custom/Tar).${NC}"
            fi
        fi
        
    else
        echo -e "   ${YELLOW}INFO: Unknown file type ($FILENAME). Skipping detailed verification.${NC}"
    fi
done

# 4. 최종 결과 요약
echo "==============================================================="
if [ $VERIFICATION_STATUS -eq 0 ]; then
    echo -e "${GREEN}VERIFICATION RESULT: SUCCESS. All checked backups appear intact.${NC}"
    exit 0
else
    echo -e "${RED}VERIFICATION RESULT: FAILURE. At least one backup file is corrupted or failed validation.${NC}"
    echo "Check the detailed log output above for specific errors."
    exit 1
fi

#!/usr/bin/env bash
LANG=C

# https://tmaxtibero.blog/9540/
# Archive Log File은 주기적/지속적으로 생성되는 파일이므로 불필요한 경우 삭제 또는 이동합니다.

export DB_ARCHIVE_LOG="/archive"
export DB_ARCHIVE_LOG_BACKUP="/backup"

# 3 Days old file move
find ${DB_ARCHIVE_LOG}/ -maxdepth 1 -type f -name "*" -mtime +14 -exec mv {} ${DB_ARCHIVE_LOG_BACKUP} \;

# 366 Days old file delete
find ${DB_ARCHIVE_LOG_BACKUP}/ -maxdepth 1 -type f -name "*" -mtime +366 -delete \;

exit 0

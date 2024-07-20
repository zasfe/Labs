#!/usr/bin/env bash
LANG=C

# https://tmaxtibero.blog/9540/
# Archive Log File은 주기적/지속적으로 생성되는 파일이므로 불필요한 경우 삭제 또는 이동합니다.

export DB_ARCHIVE_LOG="/archive"

find ${DB_ARCHIVE_LOG}/ -type f -name "*.arc" -mtime +30 -delete

exit 0

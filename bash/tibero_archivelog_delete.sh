#!/usr/bin/env bash
LANG=C

export DB_ARCHIVE_LOG="/archive"

find ${DB_ARCHIVE_LOG}/ -type f -name "*.arc" -mtime +30 -delete

exit 0

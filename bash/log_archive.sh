#!/bin/bash
# - log archive

folder_logs="/data/logs"
  
# 30 Days old file compressed
find ${folder_backup} -maxdepth 1 -type f -name "*" -and ! -name "*.gz" -mtime +30 -exec gzip -9 {} \;

exit 0

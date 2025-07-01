#!/bin/bash
# - log archive

folder_logs="/data/logs"
  
# 30 Days old file compressed
find ${folder_backup} -maxdepth 1 -type f -name "*" -and ! -name "*.gz" -mtime +30 -exec gzip -9 {} \;

# 360 Days old file deleted
find ${folder_backup} -maxdepth 1 -type f -name "*" -mtime +366 -print0 | xargs -0 rm -f
exit 0

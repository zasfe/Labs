#!/bin/bash
# - mysql binlog archive

# 7 Days old file copy
find /var/lib/mysql -maxdepth 1 -type f -name "binlog.*" -mtime +7 -exec cp -pa {} /NAS/backup/mysql_binlog/ \;

# 7 Days old binlog purge
mysql -uroot -p -e "PURGE MASTER LOGS BEFORE DATE_SUB( NOW( ), INTERVAL 7 DAY);"



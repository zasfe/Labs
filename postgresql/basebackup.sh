#!/bin/bash

basebackup_dir="/data/basebackup/basebackup`date +%Y%m%d`"
su - enterprisedb -c "pg_basebackup -D ${basebackup_dir} -Ft -z -Xs -P -v"
find /data/archive -mtime +20 -type f -ls -exec rm {} \;

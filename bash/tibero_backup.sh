#!/bin/bash

### Tibero RDBMS 6 ENV ###
export HOME=/home/tibero
export TB_HOME=/db/tibero7
export TB_SID=tibero
export TB_PROF_DIR=$TB_HOME/bin/prof
export LD_LIBRARY_PATH=$TB_HOME/lib:$TB_HOME/client/lib:$LD_LIBRARY_PATH
export JAVA_HOME=/usr/local/bin/java

export DB_BACKUP_DIR=/data/zasfe/db
export DB_BACKUP_BIN=$TB_HOME/client/bin
export DB_BACKUP_IP=127.0.0.1
export DB_BACKUP_PORT=8629
export DB_BACKUP_SID=tibero

export PATH=:$TB_HOME/bin:$TB_HOME/client/bin:$JAVA_HOME/bin:$PATH

# DB 백업 23시간 이전에 생성된 내역 삭제 및 30일 이후 내역 삭제
find ${DB_BACKUP_DIR}/ -type f -name "*.dat" -mmin -1380 -delete
find ${DB_BACKUP_DIR}/ -type f -name "*.log" -mmin -1380 -delete
find ${DB_BACKUP_DIR}/ -type f -name "*.dat" -mtime +30 -delete
find ${DB_BACKUP_DIR}/ -type f -name "*.log" -mtime +30 -delete

fileNm=`date '+%Y%m%d'`

cd ${DB_BACKUP_DIR}
tbexport USERNAME=ZASFE PASSWORD=Passw0rd#123 IP=${DB_BACKUP_IP} PORT=${DB_BACKUP_PORT} SID=${DB_BACKUP_SID} FILE=${DB_BACKUP_DIR}/${fileNm}_ZASFE.dat LOG=${DB_BACKUP_DIR}/${fileNm}_ZASFE.log USER=ZASFE ROWS=Y SCRIPT=Y

#!/bin/bash

# 초기 클라이언트 수
CLIENT=1000
LOOP_COUNT=10
# 오류 허용 임계치
ERROR_THRESHOLD=3
# 테스트 반복 횟수
REPEAT_COUNT=5
# SQL 스크립트 경로
SQL_DIR="/mysqlslap_tutorial"
SQL_FILE="$SQL_DIR/sample.sql"

# MySQL 접속 정보 (필요에 따라 수정)
HOST="localhost"
USER="testuser"
PASSWORD="testpassword"
PORT="3306"
DB="testdb"

# SSH 접속 정보
SSH_USER="root"
export SSHPASS=ft@x*ajhas

ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''
ssh-keygen -f ~/.ssh/known_hosts -R "$HOST"
sshpass -e ssh-copy-id -f -i ~/.ssh/id_rsa '$SSH_USER@$HOST'

###################################################################

exec > >(tee -a $LOG_FILE) 2>&1

# 결과 저장 파일
RESULT_FILE="mysqlslap_results.csv"
echo "timestamp,client,iteration,result,elapsed_time(s)" > $RESULT_FILE

# 무한 루프를 통한 client 수 증가 반복
while true; do
    echo "[INFO] 클라이언트 수: $CLIENT"
    ERROR_COUNT=0

    for i in $(seq 1 $REPEAT_COUNT); do
        echo "  - 테스트 #$i 실행 중..."
        
        ssh '$SSH_USER@$HOST' 'sync;sync;sync;systemctl stop mariadb;echo 3 > /proc/sys/vm/drop_caches;systemctl start mariadb;'
        sleep 10
        
        START_TIME=$(date +%s)
        RESULT_MYSQLSLAP=$(mysqlslap \
          --user=$USER \
          --password=$PASSWORD \
          --host=$HOST  \
          --port=$PORT \
          --concurrency=$CLIENT \
          --iterations=$LOOP_COUNT \
          --create-schema=$DB \
          --query="$SQL_FILE" \
          --delimiter=";" \
          --verbose \
          --pre-query="FLUSH QUERY CACHE; RESET QUERY CACHE; FLUSH TABLES;" \
          --csv) > /tmp/mysqlslap_output.log 2>&1

        END_TIME=$(date +%s)
        ELAPSED_TIME=$((END_TIME - START_TIME))
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

        if grep -qE "ERROR|Error|error" /tmp/mysqlslap_output.log; then
            echo "    -> 오류 발생"
            echo "$TIMESTAMP,$CLIENT,$i,error,$ELAPSED_TIME" >> $RESULT_FILE
            ((ERROR_COUNT++))
        else
            echo "    -> 성공"
            echo "$TIMESTAMP,$CLIENT,$i,success,$ELAPSED_TIME" >> $RESULT_FILE
        fi
    done

    if [ "$ERROR_COUNT" -ge "$ERROR_THRESHOLD" ]; then
        echo "[STOP] 오류가 $ERROR_COUNT회 발생하여 테스트 중단 (클라이언트 수: $CLIENT)"
        break
    fi

    ((CLIENT+=1000))
    echo "[NEXT] 다음 테스트로 클라이언트 수 증가: $CLIENT"
    echo "---------------------------------------------"
done

echo "[DONE] 부하 테스트 완료. 결과는 $RESULT_FILE 파일에 저장됨."

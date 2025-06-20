#!/bin/bash
# 특정 포트 TCP 상태 개수 확인
# - remote tcp/3306 : ss -tan | awk '$5 ~ /:3306$/ {print $1}'
# - local tcp/443   : ss -tan | awk '$4 ~ /:443$/ {print $1}'

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # 모든 상태 초기화
    declare -A states=(["ESTAB"]=0 ["TIME-WAIT"]=0 ["SYN-SENT"]=0 ["SYN-RECV"]=0 ["FIN-WAIT-1"]=0 ["FIN-WAIT-2"]=0 ["CLOSE-WAIT"]=0 ["LAST-ACK"]=0 ["CLOSING"]=0 ["CLOSED"]=0)

    # 현재 연결 상태 수집
    while read -r state; do
        ((states[$state]++))
    done < <(ss -tan | awk '$5 ~ /:3306$/ {print $1}')

    # 출력
    output="$timestamp TCP 3306 states:"
    for key in "${!states[@]}"; do
        output+=" $key:${states[$key]}"
    done
    echo "$output"

    # 5초마다 실행
    sleep 5
done

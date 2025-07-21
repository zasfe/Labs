#!/bin/bash

LOG_FILE="nf_conntrack_count.log"
COUNT_PATH="/proc/sys/net/netfilter/nf_conntrack_count"

# Rocky 8.10 호환 경로로 자동 대체
if [ ! -f "$COUNT_PATH" ]; then
    COUNT_PATH="/proc/sys/net/netfilter/nf_conntrack/count"
fi

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    COUNT=$(cat "$COUNT_PATH")
    OUTPUT="$TIMESTAMP - contrack count : $COUNT"
    echo "$OUTPUT" | tee -a "$LOG_FILE"
    sleep 1
done

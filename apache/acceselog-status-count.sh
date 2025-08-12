#!/bin/bash
# 사용법:
# ./log-status-count.sh /path/to/access.log "2025-08-12 01" "2025-08-12 05"
# → 2025-08-12 01:00 ~ 2025-08-12 05:59 사이 데이터만 집계

LOGFILE="$1"
START="$2"   # 시작 시간 (YYYY-MM-DD HH)
END="$3"     # 종료 시간 (YYYY-MM-DD HH)

if [[ ! -f "$LOGFILE" ]]; then
    echo "로그 파일을 찾을 수 없습니다: $LOGFILE"
    exit 1
fi

if [[ -z "$START" || -z "$END" ]]; then
    echo "시작/종료 시간을 입력하세요. 예: 2025-08-12 01  2025-08-12 05"
    exit 1
fi

# 시작/종료 시간을 epoch(초)로 변환
START_EPOCH=$(date -d "$START:00:00" +%s)
END_EPOCH=$(date -d "$END:59:59" +%s)

# 1. 전체 로그에서 등장하는 모든 상태코드 추출
CODES=$(awk '{print $9}' "$LOGFILE" | grep -E '^[0-9]{3}$' | sort -n | uniq)

# 2. CSV Header 출력
printf "time"
for code in $CODES; do
    printf ",%s" "$code"
done
printf "\n"

# 3. 집계
awk -v codes="$CODES" -v start="$START_EPOCH" -v end="$END_EPOCH" '
BEGIN {
    split(codes, arr_codes)
}
{
    # Apache 로그 날짜 예: [12/Aug/2025:09:15:32
    match($4, /\[([0-9]{2}\/[A-Za-z]+\/[0-9]{4}):([0-9]{2})/, t)
    date_str = t[1]
    hour_str = t[2]

    # YYYY-MM-DD HH 로 변환
    cmd = "date -d \"" date_str " " hour_str ":00:00\" +\"%Y-%m-%d %H %s\""
    cmd | getline formatted time_epoch
    close(cmd)

    split(formatted, parts, " ")
    ts = parts[1] " " parts[2]
    epoch = parts[3]

    status = $9

    # 범위 체크
    if (epoch >= start && epoch <= end && status ~ /^[0-9]{3}$/) {
        count[ts,status]++
        times[ts]=1
    }
}
END {
    n = split(codes, arr_codes)
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (t in times) {
        printf "%s", t
        for (i=1; i<=n; i++) {
            c = arr_codes[i]
            printf ",%d", count[t,c] ? count[t,c] : 0
        }
        printf "\n"
    }
}
' "$LOGFILE" | sort

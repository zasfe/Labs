#!/bin/bash
# 사용법:
# ./status_count_pivot_range_field.sh /path/to/access.log "2025-08-12 01" "2025-08-12 05" 9
# ./status_count_pivot_range_field.sh /path/to/access.log "2025-08-12 01" "2025-08-12 05" 10

LOGFILE="$1"
START="$2"   # 시작 시간 (YYYY-MM-DD HH)
END="$3"     # 종료 시간 (YYYY-MM-DD HH)
FIELD_POS="$4"  # 상태코드 필드 번호 (예: 9 또는 10)

if [[ ! -f "$LOGFILE" ]]; then
    echo "로그 파일을 찾을 수 없습니다: $LOGFILE"
    exit 1
fi

if [[ -z "$START" || -z "$END" || -z "$FIELD_POS" ]]; then
    echo "사용법: $0 /path/to/access.log \"YYYY-MM-DD HH\" \"YYYY-MM-DD HH\" field_position"
    echo "예: $0 access.log \"2025-08-12 01\" \"2025-08-12 05\" 10"
    exit 1
fi

# 시작/종료 시간을 epoch(초)로 변환
START_EPOCH=$(date -d "$START:00:00" +%s)
END_EPOCH=$(date -d "$END:59:59" +%s)

# 1. 전체 로그에서 등장하는 모든 상태코드 목록 추출 (숫자인 3자리만)
CODES=$(awk -v pos="$FIELD_POS" '{if ($pos ~ /^[0-9]{3}$/) print $pos}' "$LOGFILE" | sort -n | uniq)

# 2. CSV Header 출력
printf "time"
for code in $CODES; do
    printf ",%s" "$code"
done
printf "\n"

# 3. 범위 내 데이터 집계
awk -v codes="$CODES" -v start="$START_EPOCH" -v end="$END_EPOCH" -v pos="$FIELD_POS" '
BEGIN {
    split(codes, arr_codes)
}
{
    # 상태코드 숫자만 허용
    if ($pos !~ /^[0-9]{3}$/) next

    # Apache 로그 날짜 예시: [12/Aug/2025:09:15:32
    match($4, /\[([0-9]{2}\/[A-Za-z]+\/[0-9]{4}):([0-9]{2})/, t)
    date_str = t[1]
    hour_str = t[2]

    # 날짜와 시간을 YYYY-MM-DD HH 및 epoch(초)로 변환
    cmd = "date -d \"" date_str " " hour_str ":00:00\" +\"%Y-%m-%d %H %s\""
    cmd | getline line
    close(cmd)

    split(line, parts, " ")
    ts = parts[1] " " parts[2]
    epoch = parts[3]

    status = $pos

    # 범위 체크 후 카운트
    if (epoch >= start && epoch <= end) {
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

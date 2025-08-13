#!/bin/bash
# 사용법:
# ./status_count_grouped_fullrange.sh /path/to/access.log "2025-08-12 01" "2025-08-12 05" 9

LOGFILE="$1"
START="$2"   # 시작 시간 (YYYY-MM-DD HH)
END="$3"     # 종료 시간 (YYYY-MM-DD HH)
FIELD_POS="$4"  # 상태코드 필드 번호

if [[ ! -f "$LOGFILE" ]]; then
    echo "로그 파일을 찾을 수 없습니다: $LOGFILE"
    exit 1
fi

if [[ -z "$START" || -z "$END" || -z "$FIELD_POS" ]]; then
    echo "사용법: $0 /path/to/access.log \"YYYY-MM-DD HH\" \"YYYY-MM-DD HH\" field_position"
    exit 1
fi

# 시작/종료 시간을 epoch(초)로 변환
START_EPOCH=$(date -d "$START:00:00" +%s)
END_EPOCH=$(date -d "$END:00:00" +%s)  # 종료시간을 해당 시각 0분으로 설정

# 1. 로그 파싱하여 시간대별 그룹화 집계
awk -v start="$START_EPOCH" -v end="$END_EPOCH" -v pos="$FIELD_POS" '
function to_epoch(date_str, hour_str) {
    cmd = "date -d \"" date_str " " hour_str ":00:00\" +\"%Y-%m-%d %H:00 %s\""
    cmd | getline line
    close(cmd)
    split(line, parts, " ")
    ts_str = parts[1] " " parts[2]
    ts_epoch = parts[3]
    return ts_str " " ts_epoch
}
BEGIN {
    # 미리 상위 집계 category 이름 지정
    cats[1] = "20x"; cats[2] = "30x"; cats[3] = "40x"; cats[4] = "50x"
}
{
    # 상태코드가 3자리 숫자가 아니면 제외
    if ($pos !~ /^[0-9]{3}$/) next

    match($4, /\[([0-9]{2}\/[A-Za-z]+\/[0-9]{4}):([0-9]{2})/, t)
    date_str = t[1]
    hour_str = t[2]

    res = to_epoch(date_str, hour_str)
    split(res, parts, " ")
    ts = parts[1] " " parts[2]   # 예: 2025-08-13 00:00
    epoch = parts[3]

    # 범위 필터
    if (epoch < start || epoch > end) next

    code = $pos + 0
    if (code >= 200 && code <= 209) count[ts,"20x"]++
    else if (code >= 300 && code <= 309) count[ts,"30x"]++
    else if (code >= 400 && code <= 409) count[ts,"40x"]++
    else if (code >= 500 && code <= 509) count[ts,"50x"]++
}
END {
    print "time,20x,30x,40x,50x"

    # 시작부터 종료까지 1시간씩 증가시키며 출력 (없으면 0)
    for (t=start; t<=end; t+=3600) {
        cmd = "date -d @" t " +\"%Y-%m-%d %H:00\""
        cmd | getline ts_str
        close(cmd)

        printf "%s", ts_str
        printf ",%d", count[ts_str,"20x"] ? count[ts_str,"20x"] : 0
        printf ",%d", count[ts_str,"30x"] ? count[ts_str,"30x"] : 0
        printf ",%d", count[ts_str,"40x"] ? count[ts_str,"40x"] : 0
        printf ",%d", count[ts_str,"50x"] ? count[ts_str,"50x"] : 0
        printf "\n"
    }
}
' "$LOGFILE"

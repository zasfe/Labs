#!/bin/bash
# 사용법:
# ./accesslog-status-count-grouped.sh /path/to/access.log "2025-08-12 01" "2025-08-12 05" status_field_pos datetime_field_pos
# 예: ./accesslog-status-count-grouped.sh access.log "2025-08-13 00" "2025-08-13 03" 9 4
#     ./accesslog-status-count-grouped.sh access.log "2025-08-13 00" "2025-08-13 03" 10 5

LOGFILE="$1"
START="$2"    # 시작 시간 (YYYY-MM-DD HH)
END="$3"      # 종료 시간 (YYYY-MM-DD HH)
FIELD_POS="$4"    # 상태코드 필드 번호
TIME_POS="$5"     # 날짜/시간 필드 번호 (예: 4 또는 5)

if [[ ! -f "$LOGFILE" ]]; then
    echo "로그 파일을 찾을 수 없습니다: $LOGFILE"
    exit 1
fi

if [[ -z "$START" || -z "$END" || -z "$FIELD_POS" || -z "$TIME_POS" ]]; then
    echo "사용법: $0 /path/to/access.log \"YYYY-MM-DD HH\" \"YYYY-MM-DD HH\" status_field_pos datetime_field_pos"
    exit 1
fi

# 시작/종료 시간을 epoch(초)로 변환
START_EPOCH=$(date -d "$START:00:00" +%s)
END_EPOCH=$(date -d "$END:00:00" +%s)

# 집계
awk -v start="$START_EPOCH" -v end="$END_EPOCH" -v pos="$FIELD_POS" -v tpos="$TIME_POS" '
function to_epoch_field(datetime_str) {
    # Apache 로그 날짜/시간 예: [12/Aug/2025:09:15:32
    gsub(/^\[/, "", datetime_str)
    gsub(/\]$/, "", datetime_str)
    split(datetime_str, date_time, ":")
    date_part = date_time[1]      # 12/Aug/2025
    hour_part = date_time[2]      # 09
    cmd = "date -d \"" date_part " " hour_part ":00:00\" +\"%Y-%m-%d %H:00 %s\""
    cmd | getline line
    close(cmd)
    split(line, parts, " ")
    ts_str = parts[1] " " parts[2]
    ts_epoch = parts[3]
    return ts_str " " ts_epoch
}
BEGIN {
    print "time,20x,30x,40x,50x"
}
{
    # 상태코드가 3자리 숫자가 아니면 제외
    if ($pos !~ /^[0-9]{3}$/) next

    # 지정한 위치에서 날짜/시간 추출
    datetime_str = $tpos
    res = to_epoch_field(datetime_str)
    split(res, parts, " ")
    ts = parts[1] " " parts[2]   # YYYY-MM-DD HH:00
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

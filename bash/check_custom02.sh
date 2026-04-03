#!/bin/bash

# crontab
# * * * * * root /root/check.sh

set -u

LOG_DIR="/var/log/syslog"
LOG_FILE="${LOG_DIR}/$(date +%Y%m%d)"
LOCK_FILE="/var/run/check.sh.lock"

mkdir -p "${LOG_DIR}"

# 중복 실행 방지
exec 9>"${LOCK_FILE}"
flock -n 9 || exit 0

log() {
    echo "$*" >> "${LOG_FILE}"
}

run_section() {
    local name="$1"
    shift

    log ""
    log "==== ${name} BEGIN $(date '+%F %T') ===="

    if ! timeout 20s bash -c "$*" >> "${LOG_FILE}" 2>&1; then
        rc=$?
        log "[WARN] ${name} failed or timed out (rc=${rc}) at $(date '+%F %T')"
    fi

    log "==== ${name} END $(date '+%F %T') ===="
}

cleanup_old_logs() {
    find "${LOG_DIR}" -maxdepth 1 -type f -name '20*' -mtime +7 -delete 2>/dev/null
}

syscheck() {
    run_section "w" "w"
    run_section "free -m" "free -m"
    run_section "top" "top -b -n 1 -w"
    run_section "ps" "ps aufxww"
    run_section "pstree" '
        if command -v pstree >/dev/null 2>&1; then
            pstree --ascii --long
        else
            echo "Not Found pstree"
        fi
    '

    run_section "network" '
        if command -v ss >/dev/null 2>&1; then
            echo "[ss -s]"
            ss -s
            echo
            echo "[ss -nltp]"
            ss -nltp
            echo
            echo "[ESTABLISHED count]"
            ss -tan state established | wc -l
            echo
            echo "[TIME-WAIT count]"
            ss -tan state time-wait | wc -l
            echo
            echo "[ESTABLISHED top 200]"
            ss -tanop state established | head -n 200
            echo
            echo "[TIME-WAIT top 200]"
            ss -tanop state time-wait | head -n 200
        else
            echo "[netstat -nltp]"
            netstat -nltp
            echo
            echo "[ESTABLISHED]"
            netstat -anop | grep EST | head -n 200
            echo
            echo "[TIME_WAIT]"
            netstat -anop | grep TIME_WAIT | head -n 200
        fi
    '

    run_section "docker" '
        if command -v docker >/dev/null 2>&1; then
            docker ps -a
            echo
            docker stats --all --no-stream --no-trunc
        else
            echo "Not Found docker"
        fi
    '

    run_section "iotop" '
        if command -v iotop >/dev/null 2>&1; then
            iotop --batch --time --iter=1 | head -n 30
        else
            echo "Not Found iotop"
        fi
    '
}

cleanup_old_logs

log "===================== START $(date '+%F %T') ====================="
syscheck
log "===================== END   $(date '+%F %T') ====================="

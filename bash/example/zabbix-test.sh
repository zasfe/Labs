#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/usr/local/bin"
CONF_DIR="/etc/zabbix/zabbix_agent2.d"
AGENT_SERVICE="zabbix-agent2"

CACHE_DIR="/var/lib/zabbix/zbx_webhosting_top"
CACHE_TTL_SEC=20

CONF_FILE_TOP50="${CONF_DIR}/webhosting_top50.conf"

CONF_FILE_DOMAIN_TABLE="${CONF_DIR}/webhosting_domain_table.conf"
LIMIT=10

log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }
err(){ echo "[ERROR] $*" >&2; }

restart_agent2() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl restart "${AGENT_SERVICE}"
    systemctl --no-pager --full status "${AGENT_SERVICE}" || true
  elif command -v service >/dev/null 2>&1; then
    service "${AGENT_SERVICE}" restart || true
    service "${AGENT_SERVICE}" status || true
  else
    warn "systemctl/service 명령이 없어 agent2 재시작을 건너뜁니다."
  fi
}

if [[ "${EUID}" -ne 0 ]]; then
  err "root 권한으로 실행해주세요. 예) sudo bash ./install_webhosting_all.sh"
  exit 1
fi

log "디렉터리 생성: ${BIN_DIR}, ${CONF_DIR}, ${CACHE_DIR}"
mkdir -p "${BIN_DIR}" "${CONF_DIR}" "${CACHE_DIR}"
chmod 755 "${CACHE_DIR}"

log "캐시 디렉터리 권한 설정: ${CACHE_DIR} (zabbix:zabbix)"
if id zabbix >/dev/null 2>&1; then
  chown -R zabbix:zabbix "${CACHE_DIR}"
  chmod 2775 "${CACHE_DIR}"
else
  warn "zabbix 사용자가 없습니다. (zabbix-agent2 설치/계정 확인 필요) 권한 설정을 건너뜁니다."
fi

log "공통 helper 생성: FPM conf 탐색/매핑"
cat > "${BIN_DIR}/zbx_fpm_common.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

get_fpm_conf_dirs() {
  local d
  for d in /usr/local/php[0-9][0-9]/etc/fpm.d; do
    [[ -d "$d" ]] || continue
    echo "$d"
  done | sort -u
}

find_domain_by_user() {
  local user="${1:-}"
  local file=""
  local d

  [[ -n "${user}" ]] || { echo "NOT_FOUND"; return 0; }

  while IFS= read -r d; do
    [[ -d "$d" ]] || continue
    file="$(grep -RIl --include="*.conf" -E "^[[:space:]]*user[[:space:]]*=[[:space:]]*${user}\b" "$d" 2>/dev/null | head -1 || true)"
    if [[ -n "${file}" ]]; then
      basename "$file" .conf
      return 0
    fi
  done < <(get_fpm_conf_dirs)

  echo "NOT_FOUND"
}
EOF
chmod 755 "${BIN_DIR}/zbx_fpm_common.sh"

log "스크립트 생성: FPM CPU TOP5 (tsv, % 포함)"
cat > "${BIN_DIR}/zbx_fpm_cpu_top5.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ps aux \
| awk '/php-fpm: pool / && !/awk/ && !/grep/ { cpu[$NF] += $3 } END { for (p in cpu) printf "%.1f\t%s\n", cpu[p], p }' \
| sort -t $'\t' -k1,1nr \
| head -5
EOF

log "스크립트 생성: FPM COUNT TOP5 (tsv)"
cat > "${BIN_DIR}/zbx_fpm_count_top5.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ps aux \
| awk '/php-fpm: pool / && !/awk/ && !/grep/ { print $NF }' \
| sort | uniq -c \
| sort -rn \
| head -5 \
| awk '{printf "%d\t%s\n",$1,$2}'
EOF

log "스크립트 생성: PROC CPU TOP5 (tsv)"
cat > "${BIN_DIR}/zbx_proc_cpu_top5.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1)"

ps -eo pcpu,comm --no-headers 2>/dev/null \
| awk -v C="$CORES" '
  NF >= 2 {
    cpu[$2]+=$1
    cnt[$2]++
  }
  END{
    for(k in cpu){
      printf "%.1f\t%d\t%s\n", (cpu[k]/C), cnt[k], k
    }
  }' \
| sort -t $'\t' -k1,1nr \
| head -5
EOF

log "스크립트 생성: PROC MEM TOP5 (tsv)"
cat > "${BIN_DIR}/zbx_proc_mem_top5.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ps -eo pmem,comm --no-headers 2>/dev/null \
| awk '
  NF >= 2 {
    mem[$2]+=$1
    cnt[$2]++
  }
  END{
    for(k in mem) printf "%.1f\t%d\t%s\n", mem[k], cnt[k], k
  }' \
| sort -t $'\t' -k1,1nr \
| head -5
EOF

chmod 755 \
  "${BIN_DIR}/zbx_fpm_cpu_top5.sh" \
  "${BIN_DIR}/zbx_fpm_count_top5.sh" \
  "${BIN_DIR}/zbx_proc_cpu_top5.sh" \
  "${BIN_DIR}/zbx_proc_mem_top5.sh"

log "스크립트 생성: FPM CPU -> DOMAIN TOP5 (tsv: cpu% user domain)"
cat > "${BIN_DIR}/zbx_fpm_cpu_domain_top5.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMON="/usr/local/bin/zbx_fpm_common.sh"
[[ -x "${COMMON}" ]] || exit 0
source "${COMMON}"

ps aux \
| awk '/php-fpm: pool / && !/awk/ && !/grep/ { cpu[$NF] += $3 } END { for (p in cpu) printf "%.1f\t%s\n", cpu[p], p }' \
| sort -t $'\t' -k1,1nr \
| head -5 \
| while IFS=$'\t' read -r cpu user; do
    domain="$(find_domain_by_user "${user:-}")"
    printf "%s%%\t%s\t%s\n" "${cpu:-0.0}" "${user:-}" "${domain:-NOT_FOUND}"
  done
EOF
chmod 755 "${BIN_DIR}/zbx_fpm_cpu_domain_top5.sh"

log "스크립트 생성: cache updater (multi-kind)"
cat > "${BIN_DIR}/zbx_webhosting_top_cache.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
TTL="${CACHE_TTL_SEC}"

kind="\${1:-}"
case "\${kind}" in
  fpm_cpu)     gen="${BIN_DIR}/zbx_fpm_cpu_top5.sh"        ; file="\${CACHE_DIR}/fpm_cpu.tsv" ;;
  fpm_cpu_dom) gen="${BIN_DIR}/zbx_fpm_cpu_domain_top5.sh" ; file="\${CACHE_DIR}/fpm_cpu_dom.tsv" ;;
  fpm_cnt)     gen="${BIN_DIR}/zbx_fpm_count_top5.sh"      ; file="\${CACHE_DIR}/fpm_cnt.tsv" ;;
  proc_cpu)    gen="${BIN_DIR}/zbx_proc_cpu_top5.sh"       ; file="\${CACHE_DIR}/proc_cpu.tsv" ;;
  proc_mem)    gen="${BIN_DIR}/zbx_proc_mem_top5.sh"       ; file="\${CACHE_DIR}/proc_mem.tsv" ;;
  *) exit 0 ;;
esac

now=\$(date +%s)
mtime=0
if [[ -f "\${file}" ]]; then
  mtime=\$(stat -c %Y "\${file}" 2>/dev/null || echo 0)
fi
age=\$(( now - mtime ))

if [[ -f "\${file}" && "\${age}" -lt "\${TTL}" ]]; then
  exit 0
fi

tmp="\${file}.\$\$.tmp"
if "\${gen}" > "\${tmp}" 2>/dev/null; then
  if [[ -s "\${tmp}" ]]; then
    mv -f "\${tmp}" "\${file}"
    chmod 664 "\${file}" 2>/dev/null || true
  else
    rm -f "\${tmp}"
  fi
else
  rm -f "\${tmp}"
fi
EOF
chmod 755 "${BIN_DIR}/zbx_webhosting_top_cache.sh"

log "스크립트 생성: getters (top5 cached)"

cat > "${BIN_DIR}/zbx_get_fpm_cpu_top.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rank="${1:-1}"
field="${2:-pcpu}"
/usr/local/bin/zbx_webhosting_top_cache.sh fpm_cpu

file="/var/lib/zabbix/zbx_webhosting_top/fpm_cpu.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"

pcpu="$(echo "${line}" | awk -F'\t' '{print $1}')"
user="$(echo "${line}" | awk -F'\t' '{print $2}')"

case "${field}" in
  pcpu) echo "${pcpu:-0}" | sed 's/%//g' ;;
  user) echo "${user:-}" ;;
  *)    echo "" ;;
esac
EOF

cat > "${BIN_DIR}/zbx_get_fpm_cnt_top.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rank="${1:-1}"
field="${2:-count}"
/usr/local/bin/zbx_webhosting_top_cache.sh fpm_cnt

file="/var/lib/zabbix/zbx_webhosting_top/fpm_cnt.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"

count="$(echo "${line}" | awk -F'\t' '{print $1}')"
user="$(echo "${line}" | awk -F'\t' '{print $2}')"

case "${field}" in
  count) echo "${count:-0}" ;;
  user)  echo "${user:-}" ;;
  *)     echo "" ;;
esac
EOF

cat > "${BIN_DIR}/zbx_get_proc_cpu_top.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rank="${1:-1}"
field="${2:-pcpu}"
/usr/local/bin/zbx_webhosting_top_cache.sh proc_cpu

file="/var/lib/zabbix/zbx_webhosting_top/proc_cpu.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"

pcpu="$(echo "${line}" | awk -F'\t' '{print $1}')"
cnt="$(echo "${line}" | awk -F'\t' '{print $2}')"
name="$(echo "${line}" | awk -F'\t' '{print $3}')"

case "${field}" in
  pcpu) echo "${pcpu:-0}" ;;
  cnt)  echo "${cnt:-0}" ;;
  name) echo "${name:-}" ;;
  *)    echo "" ;;
esac
EOF

cat > "${BIN_DIR}/zbx_get_proc_mem_top.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rank="${1:-1}"
field="${2:-pmem}"
/usr/local/bin/zbx_webhosting_top_cache.sh proc_mem

file="/var/lib/zabbix/zbx_webhosting_top/proc_mem.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"

pmem="$(echo "${line}" | awk -F'\t' '{print $1}')"
cnt="$(echo "${line}" | awk -F'\t' '{print $2}')"
name="$(echo "${line}" | awk -F'\t' '{print $3}')"

case "${field}" in
  pmem) echo "${pmem:-0}" ;;
  cnt)  echo "${cnt:-0}" ;;
  name) echo "${name:-}" ;;
  *)    echo "" ;;
esac
EOF

cat > "${BIN_DIR}/zbx_get_fpm_cpu_domain_top.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rank="${1:-1}"

/usr/local/bin/zbx_webhosting_top_cache.sh fpm_cpu_dom

file="/var/lib/zabbix/zbx_webhosting_top/fpm_cpu_dom.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"
domain="$(echo "${line}" | awk -F'\t' '{print $3}')"

echo "${domain:-NOT_FOUND}"
EOF

chmod 755 \
  "${BIN_DIR}/zbx_get_fpm_cpu_top.sh" \
  "${BIN_DIR}/zbx_get_fpm_cnt_top.sh" \
  "${BIN_DIR}/zbx_get_proc_cpu_top.sh" \
  "${BIN_DIR}/zbx_get_proc_mem_top.sh" \
  "${BIN_DIR}/zbx_get_fpm_cpu_domain_top.sh"

log "UserParameter 설정 파일 생성: ${CONF_FILE_TOP50}"
cat > "${CONF_FILE_TOP50}" <<EOF
EOF

for n in 1 2 3 4 5; do
  echo "UserParameter=web.fpm.cpu.top${n}.pcpu,${BIN_DIR}/zbx_get_fpm_cpu_top.sh ${n} pcpu" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.fpm.cpu.top${n}.user,${BIN_DIR}/zbx_get_fpm_cpu_top.sh ${n} user" >> "${CONF_FILE_TOP50}"
done

for n in 1 2 3 4 5; do
  echo "UserParameter=web.fpm.cpu.dom.top${n}.domain,${BIN_DIR}/zbx_get_fpm_cpu_domain_top.sh ${n}" >> "${CONF_FILE_TOP50}"
done

for n in 1 2 3 4 5; do
  echo "UserParameter=web.fpm.cnt.top${n}.count,${BIN_DIR}/zbx_get_fpm_cnt_top.sh ${n} count" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.fpm.cnt.top${n}.user,${BIN_DIR}/zbx_get_fpm_cnt_top.sh ${n} user" >> "${CONF_FILE_TOP50}"
done

for n in 1 2 3 4 5; do
  echo "UserParameter=web.proc.cpu.top${n}.pcpu,${BIN_DIR}/zbx_get_proc_cpu_top.sh ${n} pcpu" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.proc.cpu.top${n}.cnt,${BIN_DIR}/zbx_get_proc_cpu_top.sh ${n} cnt" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.proc.cpu.top${n}.name,${BIN_DIR}/zbx_get_proc_cpu_top.sh ${n} name" >> "${CONF_FILE_TOP50}"
done

for n in 1 2 3 4 5; do
  echo "UserParameter=web.proc.mem.top${n}.pmem,${BIN_DIR}/zbx_get_proc_mem_top.sh ${n} pmem" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.proc.mem.top${n}.cnt,${BIN_DIR}/zbx_get_proc_mem_top.sh ${n} cnt" >> "${CONF_FILE_TOP50}"
  echo "UserParameter=web.proc.mem.top${n}.name,${BIN_DIR}/zbx_get_proc_mem_top.sh ${n} name" >> "${CONF_FILE_TOP50}"
done

chmod 644 "${CONF_FILE_TOP50}"

log "스크립트 생성: FPM DOMAIN TABLE ALL (tsv: domain cpu% mem% user)"
cat > "${BIN_DIR}/zbx_fpm_domain_table_all.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMON="/usr/local/bin/zbx_fpm_common.sh"
[[ -x "${COMMON}" ]] || exit 0
source "${COMMON}"

LIMIT="${1:-100}"

tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

ps aux \
| awk '/php-fpm: pool / && !/awk/ && !/grep/ { cpu[$NF]+=$3; mem[$NF]+=$4 }
       END { for (p in cpu) printf "%.1f\t%.1f\t%s\n", cpu[p], mem[p], p }' \
| sort -t $'\t' -k1,1nr > "$tmp_list"

n=0
while IFS=$'\t' read -r cpu mem user; do
  [[ -n "${user:-}" ]] || continue
  domain="$(find_domain_by_user "${user}")"
  printf "%s\t%.1f%%\t%.1f%%\t%s\n" "${domain}" "${cpu:-0.0}" "${mem:-0.0}" "${user}"
  n=$((n+1))
  if [[ "$LIMIT" != "0" && "$n" -ge "$LIMIT" ]]; then
    break
  fi
done < "$tmp_list"
EOF
chmod 755 "${BIN_DIR}/zbx_fpm_domain_table_all.sh"

log "스크립트 생성: cache updater (domain_table_all)"
cat > "${BIN_DIR}/zbx_domain_table_cache.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
TTL="${CACHE_TTL_SEC}"

file="\${CACHE_DIR}/domain_table_all.tsv"
gen="${BIN_DIR}/zbx_fpm_domain_table_all.sh ${LIMIT}"

now=\$(date +%s)
mtime=0
if [[ -f "\${file}" ]]; then
  mtime=\$(stat -c %Y "\${file}" 2>/dev/null || echo 0)
fi
age=\$(( now - mtime ))

if [[ -f "\${file}" && "\${age}" -lt "\${TTL}" ]]; then
  exit 0
fi

tmp="\${file}.\$\$.tmp"
if bash -lc "\${gen}" > "\${tmp}" 2>/dev/null; then
  if [[ -s "\${tmp}" ]]; then
    mv -f "\${tmp}" "\${file}"
    chmod 664 "\${file}" 2>/dev/null || true
  else
    rm -f "\${tmp}"
  fi
else
  rm -f "\${tmp}"
fi
EOF
chmod 755 "${BIN_DIR}/zbx_domain_table_cache.sh"

log "스크립트 생성: getter - domain table view (plain text)"
cat > "${BIN_DIR}/zbx_get_domain_table_view.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

/usr/local/bin/zbx_domain_table_cache.sh
file="/var/lib/zabbix/zbx_webhosting_top/domain_table_all.tsv"

echo "--------------------------------------------------------------------------------"

i=0
if [[ -s "${file}" ]]; then
  MAX=10
  while IFS=$'\t' read -r domain cpu mem user; do
    i=$((i+1))
    printf "TOP%-3d %-16s CPU: %-6s  Memory: %-6s  User: %s\n" \
      "${i}" "${domain}" "${cpu}" "${mem}" "${user}"
    [[ "$i" -ge "$MAX" ]] && break
  done < "${file}"
else
  echo "(no data)"
fi

echo "--------------------------------------------------------------------------------"
EOF
chmod 755 "${BIN_DIR}/zbx_get_domain_table_view.sh"

log "UserParameter 설정 파일 생성: ${CONF_FILE_DOMAIN_TABLE}"
cat > "${CONF_FILE_DOMAIN_TABLE}" <<EOF
UserParameter=web.domain.table.view,${BIN_DIR}/zbx_get_domain_table_view.sh
EOF
chmod 644 "${CONF_FILE_DOMAIN_TABLE}"

log "[ADD] 도메인 테이블 변경 이벤트용 getter 생성"
cat > "${BIN_DIR}/zbx_get_domain_table_view_changed.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="/usr/local/bin/zbx_get_domain_table_view.sh"
STATE_DIR="/var/lib/zabbix/zbx_webhosting_top"
STATE_FILE="${STATE_DIR}/domain_table_view.last"

mkdir -p "$STATE_DIR"

new="$("$BASE" 2>/dev/null || true)"

if [[ ! -f "$STATE_FILE" ]]; then
  printf "%s" "$new" > "$STATE_FILE"
  echo "$new"
  exit 0
fi

old="$(cat "$STATE_FILE" 2>/dev/null || true)"

if [[ "$new" == "$old" ]]; then
  echo "$new"
  exit 0
fi

printf "%s" "$new" > "$STATE_FILE"
echo "$new"
EOF
chmod 755 "${BIN_DIR}/zbx_get_domain_table_view_changed.sh"

if id zabbix >/dev/null 2>&1; then
  STATE_FILE="/var/lib/zabbix/zbx_webhosting_top/domain_table_view.last"

  mkdir -p "/var/lib/zabbix/zbx_webhosting_top"
  chown zabbix:zabbix "/var/lib/zabbix/zbx_webhosting_top" 2>/dev/null || true
  chmod 2775 "/var/lib/zabbix/zbx_webhosting_top" 2>/dev/null || true

  touch "$STATE_FILE" 2>/dev/null || true
  chown zabbix:zabbix "$STATE_FILE" 2>/dev/null || true
  chmod 664 "$STATE_FILE" 2>/dev/null || true
fi

echo "UserParameter=web.domain.table.view.changed,${BIN_DIR}/zbx_get_domain_table_view_changed.sh" >> "${CONF_FILE_DOMAIN_TABLE}"

if id zabbix >/dev/null 2>&1; then
  chown -R zabbix:zabbix "${CACHE_DIR}" 2>/dev/null || true
  chown -R zabbix:zabbix "/var/lib/zabbix/zbx_webhosting_top" 2>/dev/null || true
fi

log "[ADD] 스크립트 생성: FPM CPU -> DOMAIN TOP10 (tsv: cpu user domain)"
cat > "${BIN_DIR}/zbx_fpm_cpu_domain_top10.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMON="/usr/local/bin/zbx_fpm_common.sh"
[[ -x "${COMMON}" ]] || exit 0
source "${COMMON}"

ps aux \
| awk '/php-fpm: pool / && !/awk/ && !/grep/ { cpu[$NF] += $3 } END { for (p in cpu) printf "%.1f\t%s\n", cpu[p], p }' \
| sort -t $'\t' -k1,1nr \
| head -10 \
| while IFS=$'\t' read -r cpu user; do
    domain="$(find_domain_by_user "${user:-}")"
    printf "%s\t%s\t%s\n" "${cpu:-0.0}" "${user:-}" "${domain:-NOT_FOUND}"
  done
EOF
chmod 755 "${BIN_DIR}/zbx_fpm_cpu_domain_top10.sh"

log "[ADD] 스크립트 생성: TOP10 cache updater"
cat > "${BIN_DIR}/zbx_webhosting_top10_cache.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
TTL="${CACHE_TTL_SEC}"

file="\${CACHE_DIR}/fpm_cpu_dom10.tsv"
gen="${BIN_DIR}/zbx_fpm_cpu_domain_top10.sh"

now=\$(date +%s)
mtime=0
if [[ -f "\${file}" ]]; then
  mtime=\$(stat -c %Y "\${file}" 2>/dev/null || echo 0)
fi
age=\$(( now - mtime ))

if [[ -f "\${file}" && "\${age}" -lt "\${TTL}" ]]; then
  exit 0
fi

tmp="\${file}.\$\$.tmp"
if "\${gen}" > "\${tmp}" 2>/dev/null; then
  if [[ -s "\${tmp}" ]]; then
    mv -f "\${tmp}" "\${file}"
    chmod 664 "\${file}" 2>/dev/null || true
    if id zabbix >/dev/null 2>&1; then
      chown zabbix:zabbix "\${file}" 2>/dev/null || true
    fi
  else
    rm -f "\${tmp}"
  fi
else
  rm -f "\${tmp}"
fi
EOF
chmod 755 "${BIN_DIR}/zbx_webhosting_top10_cache.sh"

log "[ADD] 스크립트 생성: TOP10 현재값 getter"
cat > "${BIN_DIR}/zbx_get_fpm_cpu_domain_top10.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

rank="${1:-1}"       # 1~10
field="${2:-domain}" # cpu|user|domain

/usr/local/bin/zbx_webhosting_top10_cache.sh

file="/var/lib/zabbix/zbx_webhosting_top/fpm_cpu_dom10.tsv"
line="$(sed -n "${rank}p" "${file}" 2>/dev/null || true)"

cpu="$(echo "${line}" | awk -F'\t' '{print $1}')"
user="$(echo "${line}" | awk -F'\t' '{print $2}')"
domain="$(echo "${line}" | awk -F'\t' '{print $3}')"

case "${field}" in
  cpu)    echo "${cpu:-0}" ;;
  user)   echo "${user:-}" ;;
  domain) echo "${domain:-NOT_FOUND}" ;;
  *)      echo "" ;;
esac
EOF
chmod 755 "${BIN_DIR}/zbx_get_fpm_cpu_domain_top10.sh"

log "[ADD] 스크립트 생성: TOP10 history writer"
cat > "${BIN_DIR}/zbx_write_fpm_top10_history.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CACHE_FILE="/var/lib/zabbix/zbx_webhosting_top/fpm_cpu_dom10.tsv"
LOG_DIR="/var/log/zabbix"
LOG_FILE="${LOG_DIR}/fpm_top10_history.log"
LOCK_FILE="/var/lib/zabbix/zbx_webhosting_top/.fpm_top10_history.lock"

mkdir -p "${LOG_DIR}" "/var/lib/zabbix/zbx_webhosting_top"

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  exit 0
fi

/usr/local/bin/zbx_webhosting_top10_cache.sh

[[ -s "${CACHE_FILE}" ]] || exit 0

ts="$(date '+%F %T')"
host_fqdn="$(hostname -f 2>/dev/null || hostname)"

touch "${LOG_FILE}"

i=0
while IFS=$'\t' read -r cpu user domain; do
  i=$((i+1))
  [[ -n "${cpu:-}" || -n "${user:-}" || -n "${domain:-}" ]] || continue
  printf "%s\t%s\tTOP%d\t%s\t%s\t%s\n" \
    "${ts}" "${host_fqdn}" "${i}" "${domain:-NOT_FOUND}" "${cpu:-0}" "${user:-}" \
    >> "${LOG_FILE}"
  [[ "${i}" -ge 10 ]] && break
done < "${CACHE_FILE}"

chmod 640 "${LOG_FILE}" 2>/dev/null || true
if id zabbix >/dev/null 2>&1; then
  chown zabbix:zabbix "${LOG_FILE}" 2>/dev/null || true
fi
EOF
chmod 755 "${BIN_DIR}/zbx_write_fpm_top10_history.sh"

log "[ADD] 스크립트 생성: TOP10 history 조회 helper"
cat > "${BIN_DIR}/zbx_query_fpm_top10_history.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PATTERN="${1:-}"
LOG_DIR="/var/log/zabbix"
LOG_FILE="${LOG_DIR}/fpm_top10_history.log"

if [[ -z "${PATTERN}" ]]; then
  echo "usage: $0 'YYYY-MM-DD HH:MM'"
  echo "example: $0 '2026-03-11 21:29'"
  exit 1
fi

{
  [[ -f "${LOG_FILE}" ]] && grep -h "${PATTERN}" "${LOG_FILE}" 2>/dev/null || true
  ls -1 "${LOG_FILE}".* 2>/dev/null | while read -r f; do
    case "${f}" in
      *.gz) zgrep -h "${PATTERN}" "${f}" 2>/dev/null || true ;;
      *)    grep  -h "${PATTERN}" "${f}" 2>/dev/null || true ;;
    esac
  done
} | sort
EOF
chmod 755 "${BIN_DIR}/zbx_query_fpm_top10_history.sh"

log "[ADD] cron 설정 생성 (30초 주기)"
cat > /etc/cron.d/zbx-fpm-top10-history <<'EOF'
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

* * * * * root /usr/local/bin/zbx_write_fpm_top10_history.sh >/dev/null 2>&1
* * * * * root sleep 30; /usr/local/bin/zbx_write_fpm_top10_history.sh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/zbx-fpm-top10-history

log "[ADD] logrotate 설정 생성 (14일 보관)"
cat > /etc/logrotate.d/zbx-fpm-top10-history <<'EOF'
/var/log/zabbix/fpm_top10_history.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    create 0640 zabbix zabbix
}
EOF
chmod 644 /etc/logrotate.d/zbx-fpm-top10-history

log "[ADD] 권한 보정"
mkdir -p /var/log/zabbix /var/lib/zabbix/zbx_webhosting_top
if id zabbix >/dev/null 2>&1; then
  chown -R zabbix:zabbix /var/log/zabbix 2>/dev/null || true
  chown -R zabbix:zabbix /var/lib/zabbix/zbx_webhosting_top 2>/dev/null || true
  chmod 755 /var/log/zabbix 2>/dev/null || true
  chmod 2775 /var/lib/zabbix/zbx_webhosting_top 2>/dev/null || true
fi

if command -v service >/dev/null 2>&1; then
  service crond restart >/dev/null 2>&1 || true
fi

log "[ADD] history writer 1회 테스트 실행"
"${BIN_DIR}/zbx_write_fpm_top10_history.sh" || true

log "[ADD] 최근 TOP10 history 10줄 확인"
tail -n 10 /var/log/zabbix/fpm_top10_history.log 2>/dev/null || true

log "zabbix-agent2 Timeout=10 설정"
if [[ -f /etc/zabbix/zabbix_agent2.conf ]]; then
  if grep -Eq '^[[:space:]]*Timeout[[:space:]]*=' /etc/zabbix/zabbix_agent2.conf; then
    sed -i -E 's/^[[:space:]]*Timeout[[:space:]]*=.*/Timeout=10/' /etc/zabbix/zabbix_agent2.conf
  else
    echo "Timeout=10" >> /etc/zabbix/zabbix_agent2.conf
  fi
else
  warn "/etc/zabbix/zabbix_agent2.conf 파일이 없습니다. Timeout 설정을 건너뜁니다."
fi

log "Zabbix Agent2 재시작: ${AGENT_SERVICE}"
restart_agent2

if command -v zabbix_agent2 >/dev/null 2>&1; then
  log "샘플 키 테스트 (TOP50 일부 + DOMAIN TABLE)"
  zabbix_agent2 -t web.fpm.cpu.top1.pcpu || true
  zabbix_agent2 -t web.fpm.cpu.top1.user || true
  zabbix_agent2 -t web.fpm.cnt.top1.count || true
  zabbix_agent2 -t web.proc.cpu.top1.name || true
  zabbix_agent2 -t web.proc.mem.top1.pmem || true
  zabbix_agent2 -t web.fpm.cpu.dom.top1.domain || true
  zabbix_agent2 -t web.domain.table.view || true
  zabbix_agent2 -t web.domain.table.view.changed || true
fi

log "완료 ✅"
echo "[CONF] ${CONF_FILE_TOP50}"
echo "[CONF] ${CONF_FILE_DOMAIN_TABLE}"
echo "[CACHE] ${CACHE_DIR} (TTL=${CACHE_TTL_SEC}s, LIMIT=${LIMIT})"
echo "[FPM  ] /usr/local/php[0-9][0-9]/etc/fpm.d"

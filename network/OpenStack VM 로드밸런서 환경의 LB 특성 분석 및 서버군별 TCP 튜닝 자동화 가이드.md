아래 2개 파일로 분리.

1) LB 특성 분석 스크립트

cat > lb-analyze-client.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
LB_HOST=""
LB_PORT="443"
SERVER_SSH=""
SCHEME="https"
OUT="lb-analysis.json"
IDLE_MAX_SEC=900
usage() {
  echo "Usage: $0 --lb-host <host> --lb-port <port> --server-ssh <user@server> [--scheme http|https] [--out file]"
  exit 1
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lb-host) LB_HOST="$2"; shift 2 ;;
    --lb-port) LB_PORT="$2"; shift 2 ;;
    --server-ssh) SERVER_SSH="$2"; shift 2 ;;
    --scheme) SCHEME="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --idle-max-sec) IDLE_MAX_SEC="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -z "$LB_HOST" || -z "$LB_PORT" || -z "$SERVER_SSH" ]] && usage
json_escape() {
  sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '
}
run_remote() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$SERVER_SSH" "$1" 2>/dev/null || true
}
echo "[1] 클라이언트 -> LB 기본 접속 확인"
CLIENT_CURL="$(curl -k -sS -o /dev/null -w 'http_code=%{http_code} connect=%{time_connect} tls=%{time_appconnect} total=%{time_total} remote_ip=%{remote_ip}\n' "${SCHEME}://${LB_HOST}:${LB_PORT}/" 2>&1 || true)"
echo "[2] LB HTTP 헤더 확인"
HEADERS="$(curl -k -sSI --max-time 10 "${SCHEME}://${LB_HOST}:${LB_PORT}/" 2>&1 || true)"
echo "[3] LB Idle Timeout 추정"
START_TS="$(date +%s)"
IDLE_TIMEOUT="unknown"
# HTTP 포트면 curl raw keepalive 추정
# TCP 포트면 nc 연결 후 서버/LB가 먼저 끊는 시간 관찰
if command -v nc >/dev/null 2>&1; then
  {
    exec 3<>"/dev/tcp/${LB_HOST}/${LB_PORT}" || exit 0
    printf "GET / HTTP/1.1\r\nHost: %s\r\nConnection: keep-alive\r\n\r\n" "$LB_HOST" >&3 || true
    timeout "$IDLE_MAX_SEC" cat <&3 >/dev/null 2>&1 || true
  } >/tmp/lb_idle_probe.$$ 2>/dev/null || true
  END_TS="$(date +%s)"
  ELAPSED=$((END_TS - START_TS))
  if [[ "$ELAPSED" -lt "$IDLE_MAX_SEC" && "$ELAPSED" -gt 1 ]]; then
    IDLE_TIMEOUT="$ELAPSED"
  fi
fi
echo "[4] 서버 측 Established Source 확인"
SERVER_CONN="$(run_remote "ss -nt state established '( sport = :$LB_PORT or dport = :$LB_PORT )' | awk 'NR>1 {print \$5}' | sed 's/::ffff://g' | sed 's/:[0-9]*$//' | sort | uniq -c | sort -rn | head -20")"
echo "[5] 서버 측 Listen Queue 확인"
SERVER_LISTEN="$(run_remote "ss -lnt")"
echo "[6] 서버 측 TCP 통계 확인"
SERVER_NETSTAT="$(run_remote "netstat -s 2>/dev/null | egrep -i 'listen|overflow|drop|retrans|reset|time wait|segments retransmited|segments retransmitted' || true")"
echo "[7] 서버 측 Conntrack 확인"
SERVER_CONNTRACK="$(run_remote '
echo nf_conntrack_max=$(cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo NA)
echo nf_conntrack_count=$(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo NA)
')"
echo "[8] 서버 측 TIME_WAIT 확인"
SERVER_TIMEWAIT="$(run_remote "ss -ant state time-wait | wc -l")"
echo "[9] 서버 측 MTU 확인"
SERVER_MTU="$(run_remote "ip -o link show | awk -F': ' '{print \$2}' | while read i; do ip link show \"\$i\" | awk -v IF=\"\$i\" '/mtu/ {print IF\" mtu=\"\$5}'; done")"
echo "[10] 서버 측 sysctl 현재값 확인"
SERVER_SYSCTL="$(run_remote "sysctl \
net.core.somaxconn \
net.core.netdev_max_backlog \
net.ipv4.tcp_max_syn_backlog \
net.ipv4.tcp_fin_timeout \
net.ipv4.tcp_tw_reuse \
net.ipv4.tcp_keepalive_time \
net.ipv4.tcp_keepalive_intvl \
net.ipv4.tcp_keepalive_probes \
net.ipv4.tcp_rmem \
net.ipv4.tcp_wmem \
net.ipv4.ip_local_port_range 2>/dev/null")"
# LB 동작 추정
LB_MODE="unknown"
if echo "$HEADERS" | egrep -iq 'x-forwarded-for|x-real-ip|via|x-forwarded-proto|server:.*haproxy|server:.*nginx'; then
  LB_MODE="likely_l7_proxy"
elif echo "$SERVER_CONN" | grep -qE '^[[:space:]]*[0-9]+[[:space:]]+'; then
  LB_MODE="likely_l4_or_l7_snat"
fi
cat > "$OUT" <<JSON
{
  "target": {
    "lb_host": "$(printf '%s' "$LB_HOST" | json_escape)",
    "lb_port": "$(printf '%s' "$LB_PORT" | json_escape)",
    "scheme": "$(printf '%s' "$SCHEME" | json_escape)",
    "server_ssh": "$(printf '%s' "$SERVER_SSH" | json_escape)"
  },
  "inference": {
    "lb_mode": "$LB_MODE",
    "idle_timeout_sec": "$IDLE_TIMEOUT"
  },
  "client": {
    "curl_summary": "$(printf '%s' "$CLIENT_CURL" | json_escape)",
    "headers": "$(printf '%s' "$HEADERS" | json_escape)"
  },
  "server": {
    "connection_sources": "$(printf '%s' "$SERVER_CONN" | json_escape)",
    "listen_queue": "$(printf '%s' "$SERVER_LISTEN" | json_escape)",
    "tcp_stats": "$(printf '%s' "$SERVER_NETSTAT" | json_escape)",
    "conntrack": "$(printf '%s' "$SERVER_CONNTRACK" | json_escape)",
    "time_wait_count": "$(printf '%s' "$SERVER_TIMEWAIT" | json_escape)",
    "mtu": "$(printf '%s' "$SERVER_MTU" | json_escape)",
    "sysctl_current": "$(printf '%s' "$SERVER_SYSCTL" | json_escape)"
  }
}
JSON
echo "완료: $OUT"
BASH
chmod +x lb-analyze-client.sh

사용.

./lb-analyze-client.sh \
  --lb-host example.com \
  --lb-port 443 \
  --scheme https \
  --server-ssh user@10.10.10.20 \
  --out lb-analysis.json

⸻

2) 분석 결과 기반 TCP 튜닝 스크립트

cat > tcp-tune-by-lb-analysis.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
PROFILE=""
ANALYSIS=""
APPLY="false"
CONF="/etc/sysctl.d/99-openstack-lb-tcp-tuning.conf"
usage() {
  echo "Usage: $0 --profile web|was|db --analysis lb-analysis.json [--apply]"
  exit 1
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --analysis) ANALYSIS="$2"; shift 2 ;;
    --apply) APPLY="true"; shift ;;
    *) usage ;;
  esac
done
[[ -z "$PROFILE" || -z "$ANALYSIS" ]] && usage
[[ ! -f "$ANALYSIS" ]] && echo "analysis file not found" && exit 1
get_json_value() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$ANALYSIS" \
    | head -1 \
    | sed 's/.*: *"//; s/"$//'
}
IDLE_TIMEOUT="$(get_json_value idle_timeout_sec)"
LB_MODE="$(get_json_value lb_mode)"
# LB Idle Timeout 미확인 시 보수값
if [[ "$IDLE_TIMEOUT" == "unknown" || -z "$IDLE_TIMEOUT" ]]; then
  IDLE_TIMEOUT=60
fi
# Keepalive는 LB Idle Timeout보다 짧게 설정
# 단, 너무 낮으면 불필요한 probe 증가
if [[ "$IDLE_TIMEOUT" -le 60 ]]; then
  KA_TIME=30
elif [[ "$IDLE_TIMEOUT" -le 300 ]]; then
  KA_TIME=$((IDLE_TIMEOUT - 30))
else
  KA_TIME=300
fi
KA_INTVL=10
KA_PROBES=3
# OpenStack + LB 환경 기본값
SOMAXCONN=16384
SYN_BACKLOG=16384
NETDEV_BACKLOG=16384
FIN_TIMEOUT=15
RBUF="4096 262144 16777216"
WBUF="4096 262144 16777216"
RMEM_MAX=33554432
WMEM_MAX=33554432
RETRIES2=8
case "$PROFILE" in
  web)
    # WEB: 짧은 연결, TIME_WAIT 많음, LB 뒤단 Accept Queue 중요
    SOMAXCONN=32768
    SYN_BACKLOG=32768
    NETDEV_BACKLOG=32768
    FIN_TIMEOUT=10
    RBUF="4096 262144 16777216"
    WBUF="4096 262144 16777216"
    RMEM_MAX=33554432
    WMEM_MAX=33554432
    ;;
  was)
    # WAS: KeepAlive, Thread Pool, AJP/HTTP backend 연결 유지 중요
    SOMAXCONN=32768
    SYN_BACKLOG=16384
    NETDEV_BACKLOG=16384
    FIN_TIMEOUT=15
    RBUF="4096 524288 33554432"
    WBUF="4096 524288 33554432"
    RMEM_MAX=67108864
    WMEM_MAX=67108864
    ;;
  db)
    # DB: 장시간 연결, 대용량 ResultSet, 안정성 우선
    SOMAXCONN=8192
    SYN_BACKLOG=8192
    NETDEV_BACKLOG=8192
    FIN_TIMEOUT=30
    KA_TIME=300
    RBUF="4096 1048576 67108864"
    WBUF="4096 1048576 67108864"
    RMEM_MAX=67108864
    WMEM_MAX=67108864
    ;;
  *)
    usage
    ;;
esac
cat > /tmp/99-openstack-lb-tcp-tuning.conf <<EOF
###############################################################################
# OpenStack VM + Load Balancer TCP Tuning
#
# profile        : $PROFILE
# inferred_lb    : $LB_MODE
# lb_idle_timeout: ${IDLE_TIMEOUT}s
#
# 핵심 원칙
# - tcp_keepalive_time은 LB idle timeout보다 짧게 설정
# - WEB/WAS는 LB 뒤단 Accept Queue 확보
# - DB는 장시간 연결 안정성 우선
###############################################################################
###############################################################################
# Queue
###############################################################################
# accept queue 상한
# Apache/Nginx/Tomcat acceptCount/backlog보다 커야 의미 있음
net.core.somaxconn = $SOMAXCONN
# NIC 수신 backlog
# OpenStack vNIC, overlay, 순간 burst 대응
net.core.netdev_max_backlog = $NETDEV_BACKLOG
# SYN queue
# LB 뒤단이라도 backend burst가 발생할 수 있으므로 확보
net.ipv4.tcp_max_syn_backlog = $SYN_BACKLOG
# SYN flood 방어
net.ipv4.tcp_syncookies = 1
###############################################################################
# TIME_WAIT / FIN_WAIT
###############################################################################
# WEB은 짧게, DB는 길게
net.ipv4.tcp_fin_timeout = $FIN_TIMEOUT
# outbound 재사용
# Linux 4.12+ 기준 tcp_tw_recycle 제거됨
net.ipv4.tcp_tw_reuse = 1
###############################################################################
# Keepalive
###############################################################################
# LB가 idle connection을 먼저 끊기 전에 probe 발생
net.ipv4.tcp_keepalive_time = $KA_TIME
net.ipv4.tcp_keepalive_intvl = $KA_INTVL
net.ipv4.tcp_keepalive_probes = $KA_PROBES
###############################################################################
# Local Port
###############################################################################
# WEB/WAS outbound 연결 고갈 방지
net.ipv4.ip_local_port_range = 10240 65535
###############################################################################
# TCP Buffer
###############################################################################
# socket buffer 최대값
net.core.rmem_max = $RMEM_MAX
net.core.wmem_max = $WMEM_MAX
# socket buffer 기본값
net.core.rmem_default = 262144
net.core.wmem_default = 262144
# TCP autotuning buffer
net.ipv4.tcp_rmem = $RBUF
net.ipv4.tcp_wmem = $WBUF
###############################################################################
# Retransmission
###############################################################################
# DB는 장애 오탐 방지를 위해 과도하게 낮추지 않음
net.ipv4.tcp_retries2 = $RETRIES2
EOF
echo "생성된 튜닝 파일:"
echo "/tmp/99-openstack-lb-tcp-tuning.conf"
echo
cat /tmp/99-openstack-lb-tcp-tuning.conf
if [[ "$APPLY" == "true" ]]; then
  cp /tmp/99-openstack-lb-tcp-tuning.conf "$CONF"
  sysctl --system
  echo
  echo "적용 완료: $CONF"
else
  echo
  echo "미적용 상태. 적용하려면 --apply 추가"
fi
BASH
chmod +x tcp-tune-by-lb-analysis.sh

사용.

sudo ./tcp-tune-by-lb-analysis.sh \
  --profile web \
  --analysis lb-analysis.json \
  --apply
sudo ./tcp-tune-by-lb-analysis.sh \
  --profile was \
  --analysis lb-analysis.json \
  --apply
sudo ./tcp-tune-by-lb-analysis.sh \
  --profile db \
  --analysis lb-analysis.json \
  --apply

판단 기준

idle_timeout_sec <= 60  → tcp_keepalive_time=30
idle_timeout_sec <= 300 → tcp_keepalive_time=idle_timeout-30
idle_timeout_sec > 300  → tcp_keepalive_time=300
unknown                → tcp_keepalive_time=30

추가로 반드시 맞출 값

WEB: Apache MaxRequestWorkers / Nginx worker_connections
WAS: Tomcat maxThreads / acceptCount / connectionTimeout
DB : max_connections / wait_timeout / interactive_timeout

📄출처: [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 1~3편, 2017, https://meetup.nhncloud.com/posts/53], [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 2편, 2017, https://meetup.nhncloud.com/posts/54], [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 3편, 2017, https://meetup.nhncloud.com/posts/55], [Linux Kernel, IP Sysctl Documentation, 2026, https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html]

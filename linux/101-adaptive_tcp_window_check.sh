#!/bin/bash

# usage: sudo ./adaptive_tcp_window_check.sh [interface] [duration_seconds]
# example: sudo ./adaptive_tcp_window_check.sh ens3 15
# - interface: 캡처할 네트워크 인터페이스명 (기본값: eth0)
# - duration_seconds: tcpdump 캡처 지속 시간(초) (기본값: 10초)

IFACE=${1:-eth0}
DURATION=${2:-10}

echo "Capturing TCP SYN packets on interface $IFACE for $DURATION seconds..."
echo "Format: [timestamp] src_ip:src_port -> dst_ip:dst_port Window Size: win, Window Scale: wscale, Actual Receive Window (bytes)"
echo

MAX_ACTUAL_WIN=0
TMPCAP="/tmp/tcpdump_capture_$$.txt"

# 패킷 캡처 후 임시 파일 저장
sudo timeout $DURATION tcpdump -i "$IFACE" -nn -ttt '(tcp[tcpflags] & tcp-syn != 0)' -c 100 2>/dev/null > "$TMPCAP"

while IFS= read -r line; do
    TIMESTAMP=$(echo "$line" | awk '{print $1}')
    ADDRS=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}\.[0-9]+ > ([0-9]{1,3}\.){3}[0-9]{1,3}\.[0-9]+')
    SRC=$(echo "$ADDRS" | awk '{print $1}')
    DST=$(echo "$ADDRS" | awk '{print $3}')
    WIN=$(echo "$line" | grep -oE 'win [0-9]+' | awk '{print $2}')
    WSCALE=$(echo "$line" | grep -oE 'wscale [0-9]+' | awk '{print $2}')
    WSCALE=${WSCALE:-0}

    if [ -z "$WIN" ]; then
        continue
    fi
    ACTUAL_WIN=$((WIN * 2 ** WSCALE))

    echo "[$TIMESTAMP] $SRC -> $DST Window Size: $WIN, Window Scale: $WSCALE, Actual Receive Window: $ACTUAL_WIN bytes"

    if (( ACTUAL_WIN > MAX_ACTUAL_WIN )); then
        MAX_ACTUAL_WIN=$ACTUAL_WIN
    fi
done < "$TMPCAP"

rm -f "$TMPCAP"

echo
echo "=== 최대 측정된 실제 Receive Window 크기: $MAX_ACTUAL_WIN bytes ==="

if (( MAX_ACTUAL_WIN == 0 )); then
    echo "측정된 윈도우 크기 없음. 기본 권장값 적용 권고: 8MB"
    MAX_ACTUAL_WIN=8388608  # 8MB 기본값
fi

MIN_BUF=4194304    # 4MB
MAX_BUF_LIMIT=67108864  # 64MB

RECOMMENDED_BUF=$MAX_ACTUAL_WIN
if (( RECOMMENDED_BUF < MIN_BUF )); then
    RECOMMENDED_BUF=$MIN_BUF
elif (( RECOMMENDED_BUF > MAX_BUF_LIMIT )); then
    RECOMMENDED_BUF=$MAX_BUF_LIMIT
fi

echo
echo "=== 권장 커널 파라미터 설정 값 안내 ==="
echo "TCP Receive/Send buffer max size 권장: $RECOMMENDED_BUF bytes"
echo "윈도우 스케일링 활성화 필수: net.ipv4.tcp_window_scaling=1"
echo
echo "적용 예시:"
echo "sudo sysctl -w net.ipv4.tcp_window_scaling=1"
echo "sudo sysctl -w net.ipv4.tcp_rmem=\"4096 87380 $RECOMMENDED_BUF\""
echo "sudo sysctl -w net.ipv4.tcp_wmem=\"4096 16384 $RECOMMENDED_BUF\""
echo "sudo sysctl -w net.core.rmem_max=$RECOMMENDED_BUF"
echo "sudo sysctl -w net.core.wmem_max=$RECOMMENDED_BUF"
echo "sudo sysctl -w net.core.netdev_max_backlog=25000"
echo
echo "위 설정들은 tcpdump로 측정된 최대 윈도우 크기에 따른 추천값입니다."
echo "네트워크 상태에 맞게 최적의 TCP 성능을 위해 적용을 권장합니다."

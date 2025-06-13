#!/usr/bin/env bash

# ========================================================================================================
# 목적(Purpose):
# 이 스크립트는 service_list.txt 파일에서 IP와 포트, 서비스 명령 정보를 불러와 포트 연결 여부를 확인합니다.
# 포트는 쉼표(,)로 구분된 다중 포트 형식을 지원하며, 연결 결과 및 명령어 정보를 로그에 출력합니다.
# This script reads service connection information from service_list.txt (IP, comma-separated PORTS, DESC, etc.)
# and checks if each port is reachable. It logs results and displays service management commands if provided.
#
# 요청 파일 형식 (Request File Format):
# IP;PORT[,PORT2,...];DESCRIPTION;START_COMMAND;STOP_COMMAND;RESTART_COMMAND
# 예시 (Example):
# 127.0.0.1;80,443;WEB - httpd;sudo systemctl start httpd;sudo systemctl stop httpd;sudo systemctl restart httpd
# 192.168.1.10;8080;REMOTE WEB - nginx;;;
#
# 응답 예시 (Example Output):
# ==> 2025-06-13 11:00:00
# ------- [ Service Check ] ----------------------------------------------
# WEB - httpd
#   127.0.0.1:80/tcp : OK..
#   127.0.0.1:443/tcp : OK..
#   Start Command   : sudo systemctl start httpd
#   Stop Command    : sudo systemctl stop httpd
#   Restart Command : sudo systemctl restart httpd
# -------------------------------------------------------------------------
# ========================================================================================================

LANG=C

parent_path="$(dirname "${BASH_SOURCE[0]}")"
SERVICES_FILE="${parent_path}/service_list.txt"

if [ ! -f "$SERVICES_FILE" ]; then
  echo "Error: Service list file not found: $SERVICES_FILE"
  exit 1
fi

FILE=${parent_path}/serviceport_check.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}/serviceport_check.log

exec > >(tee -a $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

# IP 유효성 검사 / Validate IP address format
# 입력(Input): IP 문자열 (String)
# 출력(Output): 0 (유효함) 또는 1 (무효함)
function validate_ip {
  local ip="$1"
  local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
  if [[ $ip =~ $regex ]]; then
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
      if ((octet < 0 || octet > 255)); then
        return 1
      fi
    done
    return 0
  else
    return 1
  fi
}

# 포트 유효성 검사 / Validate port number
# 입력(Input): 포트 번호 (Number)
# 출력(Output): 0 (유효함) 또는 1 (무효함)
function validate_port {
  local port="$1"
  if [[ $port =~ ^[0-9]+$ ]] && ((port > 0 && port <= 65535)); then
    return 0
  else
    return 1
  fi
}

# 연결 결과 출력 포맷 / Format result with color
# 입력(Input): 결과 문자열 (O, X, -)
# 출력(Output): 컬러 문자열 (Colorized string)
function pretty_result {
  if [ "$1" == "O" ]; then
    echo -e "\033[32mOK..\033[0m"
  elif [ "$1" == "X" ]; then
    echo -e "\033[31mFail..\033[0m"
  else
    echo -e "\033[33m-\033[0m"
  fi
}

# 포트 연결 확인 / Check port connection
# 입력(Input): IP, 포트
# 출력(Output): "O" (성공), "X" (실패)
function portcheck_result {
  timeout 0.5 bash -c "cat < /dev/null >/dev/tcp/$1/$2" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "O"
  else
    echo "X"
  fi
}

# 포트 결과 출력 / Print check result per port
# 입력(Input): IP, 쉼표로 구분된 포트 리스트, 설명
# 출력(Output): 포트별 연결 결과 출력
function print_portcheck {
  local ip="$1"
  local ports_str="$2"
  local desc="$3"
  echo -e "\033[32m# ${desc}\033[0m"

  IFS=',' read -ra ports <<< "$ports_str"
  for port in "${ports[@]}"; do
    if [[ -n "$ip" && -n "$port" ]]; then
      if validate_ip "$ip" && validate_port "$port"; then
        echo "  ${ip}:${port}/tcp : $(pretty_result $(portcheck_result "$ip" "$port"))"
      else
        echo "  Invalid IP or Port ($port), skipping port check."
      fi
    else
      echo "  IP or Port is missing, skipping port check."
    fi
  done
}

echo " ------- [ Service Check ] ----------------------------------------------  "
# 서비스 목록 순회 / Read each line from service list
while IFS=';' read -r ip ports desc start_cmd stop_cmd restart_cmd; do
  [[ -z "$desc" || "$desc" =~ ^# ]] && continue
  [[ "$ip" =~ ^# ]] && continue

  print_portcheck "$ip" "$ports" "$desc"

  # 조건별로 명령어가 존재하는 경우에만 출력
  [[ -n "$start_cmd" ]] &&   echo "  Start Command   : $start_cmd"
  [[ -n "$stop_cmd" ]] &&    echo "  Stop Command    : $stop_cmd"
  [[ -n "$restart_cmd" ]] && echo "  Restart Command : $restart_cmd"
  
  echo ""
done < "$SERVICES_FILE"
echo " ------------------------------------------------------------------------- "

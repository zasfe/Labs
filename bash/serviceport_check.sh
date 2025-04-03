#!/usr/bin/env bash

# 이 스크립트는 리눅스 서버에서 특정 포트의 연결 가능 여부를 확인하며,
# 서비스 정보와 프로세스 기동, 중지, 재시작 명령어를 별도의 파일(service_list.txt)에서 불러옵니다.
#
# 서비스 정보 파일 형식 (세미콜론으로 구분):
# IP;PORT;DESCRIPTION;START_COMMAND;STOP_COMMAND;RESTART_COMMAND
# 예:
# 127.0.0.1;80;WEB - httpd;sudo systemctl start httpd;sudo systemctl stop httpd;sudo systemctl restart httpd
# 192.168.1.10;8080;REMOTE WEB - nginx;;;
# 원격 서버(명령어 없음) 예시: 192.168.1.10;8080;REMOTE WEB - nginx;;;

LANG=C

# 스크립트가 위치한 디렉토리 설정
parent_path="$(dirname "${BASH_SOURCE[0]}")"

# 서비스 정보가 담긴 파일 (예: service_list.txt)
SERVICES_FILE="${parent_path}/service_list.txt"
if [ ! -f "$SERVICES_FILE" ]; then
  echo "Error: Service list file not found: $SERVICES_FILE"
  exit 1
fi

###  Create .serviceport_check.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/serviceport_check.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/serviceport_check.log'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee -a $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

# IP 주소와 포트가 유효한지 검증하는 함수
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

function validate_port {
  local port="$1"
  if [[ $port =~ ^[0-9]+$ ]] && ((port > 0 && port <= 65535)); then
    return 0
  else
    return 1
  fi
}

# 결과를 색상으로 예쁘게 출력하는 함수 (O: 성공, X: 실패, 그 외: 미정)
function pretty_result {
  if [ "$1" == "O" ]; then
    echo -e "\033[32mOK..\033[0m";
  elif  [ "$1" == "X" ]; then
    echo -e "\033[31mFail..\033[0m";
  else
    echo -e "\033[33m-\033[0m";
  fi
}

# 지정된 IP와 포트에 대해 연결 시도를 수행하고 결과 반환하는 함수
function portcheck_result {
  timeout 0.5 bash -c "cat < /dev/null >/dev/tcp/$1/$2" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "O";
  else
    echo "X";
  fi
}

# 포트 체크 결과와 서비스 설명을 출력하는 함수
function print_portcheck {
  local ip="$1"
  local port="$2"
  local desc="$3"
  echo -e "\033[32m# ${desc}\033[0m"
  if validate_ip "$ip"; then
    echo "  ${ip}:${port}/tcp : $(pretty_result $(portcheck_result "$ip" "$port"))"
  fi
}

echo " ------- [ Service Check ] ----------------------------------------------  "
# service_list.txt 파일에서 각 줄을 읽어옴
while IFS=';' read -r ip port desc start_cmd stop_cmd restart_cmd; do
  # 빈 줄 또는 '#'으로 시작하는 주석은 건너뜁니다.
  [[ -z "$ip" || "$ip" =~ ^# ]] && continue

  # IP와 포트 값 검증
  if ! validate_ip "$ip"; then
    echo "Warning: Invalid IP format in service_list.txt -> $ip (Skipping entry)"
    continue
  fi
  if ! validate_port "$port"; then
    echo "Warning: Invalid port number in service_list.txt -> $port (Skipping entry)"
    continue
  fi

  # 포트 체크 결과 출력
  print_portcheck "$ip" "$port" "$desc"
  
  # 시작, 중지, 재시작 명령어가 있는 경우에만 출력 (즉, 로컬 서버의 경우만 출력)
  if [[ -n "$start_cmd" || -n "$stop_cmd" || -n "$restart_cmd" ]]; then
    echo "  Start Command   : $start_cmd"
    echo "  Stop Command    : $stop_cmd"
    echo "  Restart Command : $restart_cmd"
  fi
  echo ""
done < "$SERVICES_FILE"
echo " ------------------------------------------------------------------------- "

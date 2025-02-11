#!/usr/bin/env bash

# 이 스크립트는 리눅스 서버에서 특정 포트의 연결 가능 여부를 확인하며,
# 서버 IP, 포트, 그리고 설명(공백 포함)을 별도의 파일(service_list.txt)에서 불러옵니다.

## RESULT EXAMPLE
# # WEB - httpd
# 127.0.0.1:80/tcp : OK..
# 127.0.0.1:8080/tcp : Fail..

LANG=C

# 스크립트가 위치한 디렉토리 설정
parent_path="$(dirname "${BASH_SOURCE[0]}")"

# 서비스 정보가 담긴 파일 (예: service_list.txt)
SERVICES_FILE="${parent_path}/service_list.txt"
if [ ! -f "$SERVICES_FILE" ]; then
  echo "서비스 목록 파일을 찾을 수 없습니다: $SERVICES_FILE"
  echo "example)"
  echo "127.0.0.1 80 WEB - httpd"
  echo "127.0.0.1 8009 WAS - tomcat(ajp)"
  echo "127.0.0.1 3306 DB - mysql"
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

# 결과를 예쁘게 출력하는 함수 (O: 성공, X: 실패, 그 외: 미정)
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

# 포트 체크 결과를 출력하는 함수
function print_portcheck {
  if ! [[ "$1" == "" || "$2" == "" ]]; then
    echo -e "\033[32m  # $3 \033[0m "
    echo "  $1:$2/tcp : $(pretty_result $(portcheck_result $1 $2))"
  fi
}

echo " ------- [ Service Check ] ----------------------------------------------  "
# 서비스 정보 파일에서 각 줄마다 IP, 포트, 설명을 읽어와서 포트 체크 수행
while IFS= read -r line; do
  # 빈 줄 또는 '#'으로 시작하는 주석은 건너뜁니다.
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  
  # 첫 번째 단어는 IP, 두 번째 단어는 포트, 그 이후의 모든 단어는 설명으로 처리합니다.
  read -r ip port desc <<< "$line"
  
  print_portcheck "$ip" "$port" "$desc"
done < "$SERVICES_FILE"
echo " ------------------------------------------------------------------------- "



#!/usr/bin/env bash

## RESULT EXAMPLE
# # WEB - httpd
# 127.0.0.1:80/tcp : OK..
# 127.0.0.1:8080/tcp : Fail..

LANG=C

###  Create .serviceport_check.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/serviceport_check.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/serviceport_check.log'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"


function pretty_result {
  if [ "$1" == "O" ]; then
    echo -e "\033[32mOK..\033[0m";
  elif  [ "$1" == "X" ]; then
    echo -e "\033[31mFail..\033[0m";
  else
    echo -e "\033[33m-\033[0m";
  fi
}

function portcheck_result {
  if which curl >/dev/null; then
    curl --connect-timeout 2 -s -o /dev/null "http://$1:$2" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "O";
    else
      echo "X";
    fi
  else
    timeout 0.5 bash -c "cat < /dev/null >/dev/tcp/$1/$2" >/dev/null 2>&1
#    echo "Error! Can't Find curl command"
    if [ $? -eq 0 ]; then
      echo "O";
    else
      echo "X";
    fi
  fi
 }

function print_portcheck {
  if ! [[ "$1" == "" || "$2" == "" ]]; then
    echo -e "\033[32m  # $3 \033[0m "
    echo "  $1:$2/tcp : $(pretty_result $(portcheck_result $1 $2))"
  fi
}

echo " ------- [ Service Check ] ----------------------------------------------  "
echo " $(print_portcheck 127.0.0.1 80 'WEB - httpd')"
echo " $(print_portcheck 127.0.0.1 8009 'WAS - tomcat(ajp)')"
echo " $(print_portcheck 127.0.0.1 3306 'DB - mysql')"
echo " $(print_portcheck 127.0.0.1 5444 'DB - postgresql')"
echo " $(print_portcheck 127.0.0.1 6443 'master-api - k8s')"
echo " ------------------------------------------------------------------------- "



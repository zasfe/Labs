#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

LANG=C

function pretty_result {
  if [ "$1" == "O" ]; then
    echo -e "\033[32mOK..\033[0m";
  elif  [ "$1" == "X" ]; then
    echo -e "\033[31mFail..\033[0m";
  else
    echo -e "\033[33m-\033[0m";
  fi
  return;
}

function portcheck_result {
  if which nc >/dev/null; then
    nc -z -w 1 $1 $2
    if [ $? -eq 0 ]; then
      echo "O";
    else
      echo "X";
    fi
  else
    echo "-";
  fi
  return;
}

server1_ip_private=8.8.8.8
server1_port=53
server1_label="WEB - http"
server1_result="$(portcheck_result ${server1_ip_private} ${server1_port})"
server2_ip_private=127.0.0.1
server2_port=8009
server2_label="WAS - tomcat"
server2_result="$(portcheck_result ${server2_ip_private} ${server2_port})"
server3_ip_private=127.0.0.1
server3_port=5444
server3_label="DB - postgresql"
server3_result="$(portcheck_result ${server3_ip_private} ${server3_port})"


echo ""
echo " =========================================================================  "
if ! [[ "${server1_ip_private}" == "" || "${server1_port}" == "" ]]; then
  echo -e "\033[32m  # ${server1_label} \033[0m "
  echo -e " ${server1_ip_private}:${server1_port}/tcp : $(pretty_result ${server1_ip_private} ${server1_port}"
fi
if ! [[ "${server2_ip_private}" == "" || "${server2_port}" == "" ]]; then
  echo -e "\033[32m  # ${server2_label} \033[0m "
  echo -e " ${server2_ip_private}:${server2_port}/tcp : $(pretty_result ${server2_ip_private} ${server2_port}"
fi
if ! [[ "${server3_ip_private}" == "" || "${server3_port}" == "" ]]; then
  echo -e "\033[32m  # ${server3_label} \033[0m "
  echo -e " ${server3_ip_private}:${server3_port}/tcp : $(pretty_result ${server3_ip_private} ${server3_port}"
fi
echo " =========================================================================  "


#!/usr/bin/env bash
LANG=C

# yum install nc
# apt-get install netcat

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
  nc -zv $1 $2 >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "O";
  else
    echo "X";
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

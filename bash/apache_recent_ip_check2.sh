#!/usr/bin/env bash
LANG=C

function return_top10_most_ips_on_accesslog {
  FILE=$1
  if [ -f "$FILE" ]; then
    echo -e "\033[34m  ## Extract the top 10 most accessed IPs out of the last 1000 connections \033[0m";
    tail -n 10000 ${FILE} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
  else
    echo "$FILE does not exist.";
  fi
}

function return_top10_most_url_on_accesslog {
  FILE=$1
  if [ -f "$FILE" ]; then
    echo -e "\033[34m  ## Extract the top 10 most visited URLs \033[0m"
    column_url=`head -n 1 ${FILE} | awk -v b="\"GET" '{for (i=1;i<=NF;i++) { if ($i == b) { print i+1 } }}'`
    tail -n 10000 ${FILE} | awk -v col=${column_url} '{print $col}' | sort | uniq -c | sort -nr | head -n 10;
  else
    echo "$FILE does not exist.";
  fi
}

function return_top10_most_url_max10_ip_on_accesslog {
  FILE=$1
  if [ -f "$FILE" ]; then
    echo -e "\033[34m  ## Extract the most accessed URLs for each of the 5 maximum access IPs \033[0m";
    column_url=`head -n 1 ${FILE} | awk -v b="\"GET" '{for (i=1;i<=NF;i++) { if ($i == b) { print i+1 } }}'`
    tail -n 10000 ${FILE} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5 | while IFS= read LINE ; do
      log_ip=`echo $LINE | awk '{print$2}'`;
      log_count=`echo $LINE | awk '{print$1}'`;

      echo -e "\033[34m  ## IP: ${log_ip} / ${log_count} \033[0m";
      tail -n 10000 ${FILE} | grep ${log_ip} | awk -v col=${column_url} '{print $col}' | sort | uniq -c | sort -nr | head -n 5;
    done
  else
    echo "$FILE does not exist.";
  fi
}

function print_portcheck {
  if ! [[ "$1" == "" || "$2" == "" ]]; then
    echo -e "\033[32m  # $1 - $2 \033[0m ";
    echo "$(return_top10_most_ips_on_accesslog $2)";
    echo "$(return_top10_most_url_on_accesslog $2)";
    echo "$(return_top10_most_url_max10_ip_on_accesslog $2)";
    echo "";
  fi
}

date_log="$(date "+%Y%m%d").log"

echo " ------- [ Service Check ] ----------------------------------------------  "
# echo " $(print_portcheck 'localhost - http' /var/log/httpd/access-${date_log})"
echo " $(print_portcheck 'localhost - http' /var/log/httpd/access_log)"
echo " ------------------------------------------------------------------------- "

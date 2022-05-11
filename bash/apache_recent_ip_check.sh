#!/bin/bash

# Apache Log File
file_apachelog="/usr/local/apache/logs/ssl_custom_log"

echo -e "\033[34m # 최근 1000개 접속 중 최다 접근 IP 상위 10개 추출 \033[0m"
tail -n 10000 ${file_apachelog} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
echo ""

echo -e "\033[34m # 접속이 많은 URL 상위 10개 추출 \033[0m"
tail -n 10000 ${file_apachelog} | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 10
echo ""

echo -e "\033[34m # 최대 접근 IP 5개 별 최다 접근 URL 추출 \033[0m"
echo ""
tail -n 10000 ${file_apachelog} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5 | while IFS= read LINE ; do
   log_ip=`echo $LINE | awk '{print$2}'`;
   log_count=`echo $LINE | awk '{print$1}'`;
   
   echo -e "\033[34m # IP: ${log_ip} / ${log_count} \033[0m"
   tail -n 10000 ${file_apachelog} | grep ${log_ip} | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 5
   echo ""
done

#!/bin/bash

LANG=C

# Apache Log File
file_apachelog="/usr/local/apache/logs/access_log"

if [ $# -ne 1 ]; then
    if [ -f $1 ]; then
        file_apachelog=$1
        echo "";
        echo -e "\033[34m # Log file: ${file_apachelog} \033[0m";
        echo "";
    else
        echo "";
        echo -e "\033[34m # Log file Not Exists \033[0m";
        echo " $1";
        echo "";
        exit;
    fi
fi

unset $1

echo "";
echo -e "\033[34m # Extract the top 10 most accessed IPs out of the last 1000 connections \033[0m";
tail -n 10000 ${file_apachelog} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
echo "";

echo -e "\033[34m # Extract the top 10 most visited URLs \033[0m"
tail -n 10000 ${file_apachelog} | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 10
echo "";

echo -e "\033[34m # Extract the most accessed URLs for each of the 5 maximum access IPs \033[0m"
echo "";
tail -n 10000 ${file_apachelog} | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5 | while IFS= read LINE ; do
   log_ip=`echo $LINE | awk '{print$2}'`;
   log_count=`echo $LINE | awk '{print$1}'`;
   
   echo -e "\033[34m # IP: ${log_ip} / ${log_count} \033[0m";
   tail -n 10000 ${file_apachelog} | grep ${log_ip} | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 5
   echo "";
done

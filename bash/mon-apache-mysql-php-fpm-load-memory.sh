#!/bin/bash

LOG_FILE="monitor.log"

# Monitoring loop
while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "$TIMESTAMP - Apache Total threads : $(ps -eLf | grep httpd | grep -v grep | wc -l)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - Apache Connections80 : $(netstat -an | grep ':80 ' | grep ESTABLISHED | wc -l)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - Mysql Connections3306: $(netstat -an | grep ':3306 ' | grep ESTABLISHED | wc -l)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - Connections all      : $(netstat -an | grep ESTABLISHED | wc -l)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - PHP-FPM child proc.. : $(pgrep -P $(pgrep -o php-fpm) | wc -l)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - System Load          :$(uptime)" | tee -a "$LOG_FILE"
  echo "$TIMESTAMP - Memory/CPU Summary   : $(vmstat 1 2 | tail -1)" | tee -a "$LOG_FILE"

  sleep 1
done

#!/bin/bash

mkdir -p /var/log/systemlog/

#생성 파일
log_file="/var/log/systemlog/`date +%Y%m%d`"

#7일마다 삭제
dlog_file="/var/log/systemlog/`date +%Y%m%d --date '7 day ago'`"

function syscheck() {
        if [ ! -d "/var/log/systemlog" ]; then
                mkdir -p /var/log/systemlog
        fi
        if test -f $dlog_file
        then
                rm -f $dlog_file
        fi
        echo " " >> $log_file
        w >> $log_file

        echo "" >> $log_file
        echo "==== free -m ====" >> $log_file
        free -m >> $log_file

        echo "" >> $log_file
        echo "==== top ==== "  >> $log_file
        top -c -b -n 1 -w  >> $log_file

        echo "" >> $log_file
        echo "==== ps ====" >> $log_file
        ps aufxww >> $log_file

        echo "" >> $log_file
        echo "==== pstree ====" >> $log_file
        if command -v pstree &>/dev/null; then
          pstree --ascii --long   >> $log_file
        else
          echo "Not Found pstree" >> $log_file
        fi

        echo "" >> $log_file
        echo "==== netstat ====" >> $log_file
        netstat -nltp  >> $log_file
        netstat -anop |grep EST >> $log_file
        netstat -anop | grep TIME_WAIT  >> $log_file
        
        echo "" >> $log_file
        echo "==== docker ====" >> $log_file
        if command -v docker &>/dev/null; then
          docker ps -a   >> $log_file
          echo "" >> $log_file
          docker stats --all --no-stream --no-trunc  >> $log_file
        else
          echo "Not Found docker" >> $log_file
        fi

        echo "" >> $log_file
        echo "==== iotop ====" >> $log_file
        if command -v iotop &>/dev/null; then
          iotop --batch --time --iter=1  | head -n 30  >> $log_file
        else
          echo "Not Found iotop" >> $log_file
        fi
        
}

#function mysql_processlist() {
#        /usr/local/mariadb/bin/mysqladmin -u backup_user -p"backup_password"  processlist >> $log_file
#
#}
#
echo "===================== START `date +%Y-%m-%d-%H:%M` =====================" >> $log_file
syscheck
#mysql_processlist
echo "===================== END =====================" >> $log_file

#!/bin/bash

#생성 파일
log_file="/var/log/syslog/`date +%Y%m%d`"

#7일마다 삭제
dlog_file="/var/log/syslog/`date +%Y%m%d --date '7 day ago'`"

function syscheck() {
        if [ ! -d "/var/log/syslog" ]; then
                mkdir -p /var/log/syslog
        fi
        if test -f $dlog_file
        then
                rm -f $dlog_file
        fi
        echo " " >> $log_file
        date +%Y-%m-%d-%H:%M >> $log_file ;
#      w >> $log_file
        top -b -n 1 >> $log_file
        uptime >> $log_file
#       top -c >> $log_file
#      pstree |grep mysqld >> $log_file
        pstree |grep httpd >> $log_file
        ps awwux >> $log_file
        free -m >> $log_file
        netsat -nltp >> $log_file

}

function mysql_processlist() {
        /usr/local/mariadb/bin/mysqladmin -u backup_user -p"backup_password"  processlist >> $log_file

}

echo "===================== START  =====================" >> $log_file
syscheck
#mysql_processlist
echo "===================== END =====================" >> $log_file

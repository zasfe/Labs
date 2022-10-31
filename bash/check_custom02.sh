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
#        date +%Y-%m-%d-%H:%M >> $log_file ;
#      w >> $log_file
        uptime >> $log_file
#       top -c >> $log_file
#      pstree |grep mysqld >> $log_file
       echo "====ps tree====" >> $log_file
        pstree |grep httpd >> $log_file
#        ps awwux >> $log_file
       echo "====free -m====" >> $log_file
        free -m >> $log_file

        echo "====netstat countdown====" >> $log_file
        echo " - TCP/80: `netstat -ano |grep 80 |wc -l`" >> $log_file
        echo " - TCP/443: `netstat -ano |grep 443 |wc -l`" >> $log_file
        echo " - TCP/3306: `netstat -ano |grep 3306 |wc -l`" >> $log_file
        echo " "  >> $log_file
        echo " - ESTABLISHED: `netstat -ano | grep ESTABLISHED |wc -l`" >> $log_file
        echo " - TIME_WAIT: `netstat -ano | grep TIME_WAIT |wc -l`" >> $log_file
        echo " "  >> $log_file
        echo " - TCP/80(ESTABLISHED/TIME_WAIT): `netstat -ano |grep 80 | grep ESTABLISHED |wc -l` / `netstat -ano |grep 80 | grep TIME_WAIT |wc -l`" >> $log_file
        echo " - TCP/443(ESTABLISHED/TIME_WAIT): `netstat -ano |grep 443 | grep ESTABLISHED |wc -l` / `netstat -ano |grep 443 | grep TIME_WAIT |wc -l`" >> $log_file
        echo " - TCP/3306(ESTABLISHED/TIME_WAIT): `netstat -ano |grep 443 | grep ESTABLISHED |wc -l` / `netstat -ano |grep 443 | grep TIME_WAIT |wc -l`" >> $log_file

        echo " ==== top ==== "  >> $log_file
        top -b -n 1 >> $log_file
        
        echo "====netstat====" >> $log_file
        netstat -nltp  >> $log_file
        netstat -ano |grep EST >> $log_file
        netstat -ano| grep TIME_WAIT  >> $log_file

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

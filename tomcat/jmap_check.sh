#!/bin/bash

TOMCAT_PID=`ps -ef | grep tomcat | grep -vE 'grep|tail' | awk '{print $2}'`
DATE=`date "+%Y-%m-%d"`

echo "#########################################################" >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE
date >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE
echo "#########################################################" >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE
jmap -heap $TOMCAT_PID >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE
echo "#########################################################" >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE
pstree -s $TOMCAT_PID >> /root/tomcat_jmap_log/tomcat_jmap_log_$DATE


find /root/tomcat_jmap_log -name tomcat* -mtime +2 -exec rm -f {} \;

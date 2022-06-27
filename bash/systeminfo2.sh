#!/bin/bash

LANG=C
ARCH=`arch`

#Ven=`dmidecode | grep Vendor | awk -F: '{print $2}' | sed 's/ //g'`
Ven=`dmidecode | grep Vendor | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'  | awk '{gsub(/^[ \t]+/, "", $1);print $1}'`

Mod=`dmidecode | grep Name | head -n 1 | awk -F: '{print $2}'`

CPU_M=`cat /proc/cpuinfo | grep "model name" | awk -F: '{print $2}' | head -n 1`
CPU_P=`cat /proc/cpuinfo | grep "physical id" | sort | uniq  | wc -l`
CPU_V=`cat /proc/cpuinfo | grep "model name" | wc -l`

MEM_T=`cat /proc/meminfo | grep MemTotal | awk -F: '{print $2}'`
#DISK=`hpacucli ctrl all show config | grep -v Array | grep -v array`
#HP_DISK=`hpacucli ctrl all show config | grep -v Array | grep -v array`
OS_V=`cat /etc/issue | head -n 1 | awk -F\( '{print $1}'`

function disk_info() {
if [ "$Ven" == "HP" ]; then
  [ -f '/usr/sbin/hpssacli' ] && HP_CMD='/usr/sbin/hpssacli'
  [ -f '/usr/sbin/hpacucli' ] && HP_CMD='/usr/sbin/hpacucli'
  if [ "${HP_CMD}" == "" ]; then
    disk_raid="Unkonwn/HP";
    disk_raid_size="Unkonwn";
    echo "${disk_raid} ${disk_raid_size};"
  else
    hp_slot_no=`$HP_CMD ctrl all show status | grep -i slot | awk '{print$6}'`
    $HP_CMD ctrl slot=$hp_slot_no show config | grep . | sed -e "s/^[\t ]*//g" | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/array/\narray/g' | grep "^array" | while IFS= read line ; do
      disk_raid=`echo $line | awk '{gsub(",", "", $13);print$12" "$13}'`
      echo $line | sed -e 's/physicaldrive/\nphysicaldrive/g' | grep physicaldrive | awk '{gsub(",", "", $7);gsub(",", "", $9);print $7" "$8" "$9}' | while IFS= read disk_raid_size ; do
        echo "${disk_raid} ${disk_raid_size}"
      done
    done
  fi
elif [ "$Ven" == "IBM" ] || [ "$Ven" == "Dell" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${IBM_CMD}" == "" ]; then
    disk_raid="Unkonwn/IBM";
    disk_raid_size="Unkonwn";
    echo "${disk_raid} ${disk_raid_size}"
  else
    ${IBM_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD\ Type|^Raw\ Size" | sed -e 's/\,/\:/g' -e 's/\[/\:/g' |  awk -F':' '{gsub(/[ \t]+/, "", $2);print $1":"$2}' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/RAID/\nRAID/g' | grep .  | while IFS= read line ; do
      disk_raid=`echo $line | awk '{gsub(":Primary-", "", $3);print"RAID "$3}'`
      echo $line | sed -e 's/PD/\nPD/g' | grep PD | sed -e 's/\:/ /g' | awk '{gsub("GB", " GB", $6);gsub("TB", " TB", $6);print$3" "$6}' | while IFS= read disk_raid_size ; do
        echo "${disk_raid} ${disk_raid_size}"
      done
    done
  fi
else
  disk_raid="Unkonwn/$Ven";
  disk_raid_size="Unkonwn";
  echo "${disk_raid} ${disk_raid_size}"
fi
}


function install_type_httpd() {

#HTTP_RPM=`rpm -qa | grep httpd | grep -v tools | wc -l`
HTTP_PID_T=`ps axu | grep httpd | grep -v grep |  awk '{print $2}' | head -n 1`
HTTP_PATH_T=`ls -l /proc/$HTTP_PID_T | grep exe | cut -d \> -f2`
HTTP_RPM="/usr/sbin/httpd"
if [ $HTTP_RPM == $HTTP_PATH_T ]; then
echo "rpm"
else
echo "souce"
fi
}

function httpd_version() {
HTTP_USE=`ps axu | grep httpd | grep -v grep | awk '{print $2}' | head -n 1 | wc -l`

if [ $HTTP_USE -lt "1" ]; then
echo "X"
else
HTTP_PID=`ps axu | grep httpd | grep -v grep |  awk '{print $2}' | head -n 1`
HTTP_PATH=`ls -l /proc/$HTTP_PID | grep exe | cut -d \> -f2`
HTTP_VER=`exec $HTTP_PATH -v | awk '{print $3}' | head -n 1 | sed "s/Apache\///g"`
echo "apache $HTTP_VER"
fi
}

function install_type_mysqld() {

MYSQL_PID_T=`ps axu | grep mysql | head -n 1 | awk '{print $12}'`
MYSQL_RPM="/usr/bin/mysqld_safe"
if [ $MYSQL_RPM == $MYSQL_PID_T ]; then
echo "rpm"
else
echo "souce"
fi
}
function mysqld_version() {
MYSQL_USE=`ps axu | grep mysql | grep -v grep | grep -v bb | awk '{print $2}' | head -n 1 | wc -l`


if [ $MYSQL_USE -lt "1" ]; then
echo "X"
else
MYSQL_PATH=`ps axu | grep mysql | grep -v grep | grep -v bb | sed 's/\ /\n/g' | grep basedir | awk -F\= '{print $2}'`
#MYSQL_TXT=`sed "s/mysqld_safe/mysql --version/g" /home/gabia/mysql_ver.txt`
VER_CMD="/bin/mysql --version"
MYSQL_VER=`exec $MYSQL_PATH$VER_CMD | awk '{print $5}'`
echo "mysql $MYSQL_VER"
#rm -f /home/gabia/mysql_ver.txt
fi
}

function tomcat_version() {
TOMCAT_USE=`ps axu | grep tomcat | grep -v grep | awk '{print $2}' | head -n 1 | wc -l`

if [ $TOMCAT_USE -lt "1" ]; then
echo "X"
else
JAVA_PATH=`ps axu | grep java | grep -v grep | head -n 1 | awk '{print $11}'`
TOMCAT_PATH=`ps axu | grep java | grep -v grep | grep tomcat | head -n 1 | sed 's/\ /\n/g' | grep catalina.base | awk -F\= '{print$2}'`
VER_CMD="/lib/catalina.jar org.apache.catalina.util.ServerInfo"
TOMCAT_VER=`exec $JAVA_PATH  -cp $TOMCAT_PATH$VER_CMD | grep version | awk '{print $3, $4}' | sed "s/Apache Tomcat\///g"`
echo "tomcat $TOMCAT_VER"
fi
}

function php_version() {

PHP_USE=`ps axu | grep httpd | grep -v grep | awk '{print $2}' | head -n 1 | wc -l`

if [ $PHP_USE -lt "1" ]; then
echo "X"
else
ps aufx | grep "bin/httpd" | grep -v grep | awk '{print$11}' | grep -v '^\\_' | while read line; do(HTTPD_ROOT=`${line} -V | grep "HTTPD_ROOT" | cut -d "=" -f 2 | sed -e 's/\"//g'`;echo ${HTTPD_ROOT}; SERVER_CONFIG_FILE=`${line} -V | grep "SERVER_CONFIG_FILE" | cut -d "=" -f 2 | sed -e 's/\"//g'`; path_php_module=`grep -i php ${HTTPD_ROOT}/${SERVER_CONFIG_FILE} | grep LoadModule | awk '{print$3}'`; strings ${HTTPD_ROOT}/${path_php_module} | grep "X-Powered-By" | awk '{print$2}' ;  ) done | grep -v apache | sed "s/PHP\//php /g"
fi
}

UPTIME=`uptime | awk '{print $3}'`


function httpd_url() {

HTTP_USE=`ps axu | grep httpd | grep -v grep | awk '{print $2}' | head -n 1 | wc -l`

if [ $HTTP_USE -lt "1" ]; then
echo "X"
else
HTTP_PATH=`ps axu | grep httpd | head -n 1 | awk '{print $11}' | awk -F"bin" '{print $1}'`
HTTP_CONF=`echo $HTTP_PATH\conf`
#HTTP_URL=`cat $HTTP_CONF/*/*/*/*/* | grep -v "\#" | grep ServerName | grep -v 80 | grep -v example.com |awk '{print $2}' | head -n 1`
HTTP_URL=`grep -r "ServerName" $HTTP_CONF/* | grep -v "#" | awk '{print $3}' | grep -v example.com`
echo $HTTP_URL
fi
}

function monitoring_bb() {

BB_USE=`ps axu | grep runbb | grep -v grep | wc -l`

if [ $BB_USE -lt "1" ]; then
echo "X"
else
echo "BB"
fi
}


function monitoring_zenius() {

ZENIUS_USE=`ps axu | grep zagent | grep -v grep | wc -l`

if [ $ZENIUS_USE -lt "1" ]; then
echo "X"
else
echo "ZENIUS"
fi
}

echo "1 Vendor: $Ven"
echo "2 Model: $Mod"
echo "3 CPU: $CPU_M / $CPU_P / $CPU_V"
echo "4 MEM: $MEM_T"
echo "5 DISK:
`disk_info`"
echo "6 OS: $OS_V($ARCH)"
echo "7 HTTP_Ver: `httpd_version`"
echo "8 PHP_Ver: `php_version`"
echo "9 WAS: `tomcat_version`"
echo "10 MYSQL_Ver: `mysqld_version`"
echo "11 HTTP_url: `httpd_url`"
echo "12 Monitoring_BB: `monitoring_bb`"
echo "13 Monitoring_ZENIUS: `monitoring_zenius`"
echo "14 UPTIME: $UPTIME"






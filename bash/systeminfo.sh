#!/bin/bash

# sudo bash -c "curl -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo.sh | bash -"
# curl -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo.sh | bash -
LANG=C


function pretty_result {
  if [ "$1" == "O" ]; then
    echo -e "\033[32mO\033[0m";
  elif  [ "$1" == "X" ]; then
    echo -e "\033[31mX\033[0m";
  else
    echo -e "\033[33m-\033[0m";
  fi
  return;
}

echo ""
# system status
## Os - info
os_hostname=`hostname`
echo -e "  hostname: \033[32m${os_hostname}\033[0m";

## Hardware
hw_vendor=`dmidecode | grep Vendor | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'  | awk '{gsub(/^[ \t]+/, "", $1);print $1}'`
hw_model=`dmidecode | grep "Product\ Name" | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2);print $2} ' | sed -e 's/^IBM //g'`
echo -e "  hw: \033[32m${hw_vendor} ${hw_model}\033[0m";

## OS
if [ -f '/etc/os-release' ] ; then
  os_release=`cat /etc/os-release  | grep PRETTY_NAME | cut -d'"' -f2`
  os_namefile="/etc/os-release";
elif [ -f '/etc/redhat-release' ] ; then
  os_release=`cat /etc/redhat-release | head -n 1`
  os_namefile="/etc/redhat-release";
elif [ -f '/etc/issue' ] ; then
  os_release=`cat /etc/issue | head -n 1`
  os_namefile="/etc/issue";
else
  os_release="Unknown";
fi
[ "$os_release" == "" ] && os_release="Unknown";

os_arch=`arch`
echo -e "  os: \033[32m${os_release} (${os_arch})\033[0m";



## WEB - apache
apache_version="-";
apache_bin="-";
icheck=`ps aufx | egrep "(httpd|apache)" | grep -v "org.apache" | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  apachecheck="X";
  echo -e "  http_apache: $(pretty_result ${apachecheck}) ( ver: ${apache_version} , bin: ${apache_bin} )";
else
  apachecheck="O";
  ps aufx | egrep "(httpd|apache)" | grep -v '\\' | grep -v "org.apache" |  awk '{print$11" "$2}' | while IFS= read LINE ; do
    apache_bin=`echo $LINE | awk '{print$1}'`;
    apachectl_bin=`echo $LINE | awk '{print$1}' | sed -e 's/apache2/apachectl/g' -e 's/httpd/apachectl/g'`;
    apache_pid=`echo $LINE | awk '{print$2}'`;
  
    if [ -f "${apache_bin}" ]; then
      apache_version=`${apache_bin} -V 2>/dev/null | grep "^Server\ version" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo -e "  http_apache: $(pretty_result ${apachecheck}) ( ver: ${apache_version} , bin: ${apache_bin} )";
    fi
  done
fi

## WEB - nginx
nginxcheck="-";
nginx_version="-";
nginx_bin="-";
icheck=`ps aufx | egrep "(nginx)" | grep -v grep | grep master | wc -l`
if [ $icheck -eq "0" ]; then
  nginxcheck="X";
  echo -e "  http_nginx: $(pretty_result ${nginxcheck}) ( ver: ${nginx_version} , bin: ${nginx_bin} )";
else
  nginxcheck="O";
  ps aufx | egrep "(nginx)" | grep -v grep | grep master | while IFS= read LINE ; do
    nginx_bin=`echo $LINE | awk '{print$14}'`;
    if [ -f "${nginx_bin}" ]; then
      nginx_version=`${nginx_bin} -V 2>&1 | grep -i "^nginx version" | awk '{print$3}'`
      echo -e "  http_nginx: $(pretty_result ${nginxcheck}) ( ver: ${nginx_version} , bin: ${nginx_bin} )";
    fi
  done
fi


## WAS - tomcat
tomcat_version="-";
tomcat_bin="-";
icheck=`ps aufxww | grep "/java" | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  tomcatcheck="X";
  echo -e "  was_tomcat: $(pretty_result ${tomcatcheck}) ( ver: ${tomcat_version} , bin: ${tomcat_bin} )";
else
  tomcatcheck="O";
  ps aufxww | grep "/java" | grep -v grep | while read line; do
    java_bin=`echo "$line" | sed -e 's/\ /\n/g' | grep "java$"`;
    if [ -f "${java_bin}" ]; then
      tomcat_home=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.home" | awk -F\= '{print$2}'`
      tomcat_base=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.base" | awk -F\= '{print$2}'`
      if [ -n "${tomcat_home}" ]; then
        tomcat_version=`exec ${java_bin} -cp ${tomcat_home}/lib/catalina.jar org.apache.catalina.util.ServerInfo 2>/dev/null | grep "^Server\ version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
        echo -e "  was_tomcat: $(pretty_result ${tomcatcheck}) ( ver: ${tomcat_version} , home: ${tomcat_home}  , base: ${tomcat_base} )";
        java_version=`exec ${java_bin} -cp ${tomcat_home}/lib/catalina.jar org.apache.catalina.util.ServerInfo 2>/dev/null | grep "^JVM\ Version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
        echo -e "  -- java: java/${java_version} ( bin: ${java_bin} )";
      fi
    fi
  done
fi


## DBMS - general
dbms_exist="X";

## DBMS - mysql
mysql_version="-";
mysql_bin="-";
icheck=`ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | wc -l`
if [ $icheck -eq "0" ]; then
  mysqlcheck="X";
  echo -e "  dbms_mysql: $(pretty_result ${mysqlcheck}) ( ver: ${mysql_version} , bin: ${mysql_bin} )";
else
  mysqlcheck="O";
  dbms_exist="O";
  
  ps ax | grep mysqld | grep -v grep | grep -v mysqld_safe | awk '{print$5}' | uniq | while IFS= read mysql_bin ; do
    mysql_version_full=`${mysql_bin} -V 2>/dev/null`
    mysql_version=`echo ${mysql_version_full}| awk '{print $3}' | cut -d"-" -f1`
    echo -e "  dbms_mysql: $(pretty_result ${mysqlcheck}) ( ver: mysql/${mysql_version} , bin: ${mysql_bin} )";
  done
  
#  ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | awk '{print$12}' | uniq | while IFS= read mysql_bin ; do
#    mysql_version=`strings ${mysql_bin} | grep "^mysqld\-" | sed -e 's/\-/\//g'`
#    if [ `strings ${mysql_bin} | grep  "\-MariaDB$" | wc -l` -eq 1 ]; then
#      mysql_version=`strings ${mysql_bin} | grep  "\-MariaDB$" | awk -F'-' '{print "MariaDB/"$1}'`
#    fi
#    echo -e "  dbms_mysql: $(pretty_result ${mysqlcheck}) ( ver: ${mysql_version} , bin: ${mysql_bin} )";
#  done
fi


## DBMS - oracle
oracle_version="-";
oracle_bin="-";
icheck=`ps aufx | grep tnslsnr | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  oraclecheck="X";
  echo -e "  dbms_oracle: $(pretty_result ${oraclecheck}) ( ver: ${oracle_version} , home: ${oracle_home} )";
else
  oraclecheck="O";
  dbms_exist="O";
  ps aufx | grep tnslsnr | grep -v grep | awk '{print$11}' | uniq | while IFS= read tnslsnr_bin ; do
    oracle_home=`echo $tnslsnr_bin | sed -e 's/\/bin\/tnslsnr//g' | grep "^/"`;
  # https://docs.oracle.com/cd/E11857_01/em.111/e12255/oui2_manage_oracle_homes.htm
    oracle_inventory="${oracle_home}/inventory/ContentsXML/comps.xml";
    if [ -f "${oracle_inventory}" ]; then
      oracle_version=`cat ${oracle_home}/inventory/ContentsXML/comps.xml | grep oracle.server | head -n 1 | cut -d'"' -f4`;
    fi
    echo -e "  dbms_oracle: $(pretty_result ${oraclecheck}) ( ver: oracle/${oracle_version} , home: ${oracle_home} )";
  done
fi


## config - arp
ip_gateway=`ip r | grep "^default" | cut -d' ' -f3 | head -n 1`
icheck=`arp -an | grep "(${ip_gateway})" | grep PERM | wc -l`
arplog=`arp -an | grep "(${ip_gateway})"`
if [ $icheck -eq "0" ]; then
  arpcheck="X";
else
  arpcheck="O";
fi
echo -e "  cfg_arpstatic: $(pretty_result ${arpcheck}) ( gateway ip: ${ip_gateway} )";
if [ "${arpcheck}" == "X" ]; then
  echo -e "    - \033[31m${arplog}\033[0m"
fi

## Hardware - partition
icheck=`df -lh | awk '0+$5 >= 70 {print}' | wc -l`
if [ $icheck -eq "0" ]; then
  diskcheck="O";
else
  diskcheck="X";
fi
echo -e "  disk freesize: $(pretty_result ${diskcheck}) ( over 70% )";
if [ "${diskcheck}" != "O" ]; then
  echo -e "  \033[31m$(df -lh | awk '0+$5 >= 70 {print}') \033[0m"
fi


## Hardware - array
raidapp_exist="-";
raidresult="-";
raidlog="";
if [ "$(echo $hw_vendor| awk '{print tolower($0)}')" == "hp" ]; then
  [ -f '/usr/sbin/hpssacli' ] && HP_CMD='/usr/sbin/hpssacli'
  [ -f '/usr/sbin/hpacucli' ] && HP_CMD='/usr/sbin/hpacucli'
  if [ "${HP_CMD}" == "" ]; then
    raidapp_exist="X";
  else
    raidapp_exist="O";
    hp_slot_no=`$HP_CMD ctrl all show status | grep -i slot | awk -F'Slot' '{print$2}' | awk '{print$1}'`;
    if [ -n ${hp_slot_no} ]; then
      raidlog=`$HP_CMD ctrl slot=$hp_slot_no show config | grep . | egrep "(logical|physical)"`
      icheck=`$HP_CMD ctrl slot=$hp_slot_no show config | grep . | egrep "(logical|physical)" | grep -v "OK)" | wc -l`
      if [ $icheck -eq "0" ]; then
        raidresult="O";
      else
        raidresult="X";
      fi
    fi
  fi
elif [ "$(echo $hw_vendor| awk '{print tolower($0)}')" == "ibm" ] || [ "$(echo $hw_vendor| awk '{print tolower($0)}')" == "dell" ] || [ "$(echo $hw_vendor| awk '{print tolower($0)}')" == "lenovo" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && MEGACLI_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && MEGACLI_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${MEGACLI_CMD}" == "" ]; then
    raidapp_exist="X";
  else
    raidapp_exist="O";
    icheck=`${MEGACLI_CMD} -LDPDinfo -aALL -NoLog | grep "Count:" | awk '0+$4 > 0 {print}' | wc -l`
    raidlog=`${MEGACLI_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD|^Raw\ Size|^Media\ Error|^Other\ Error|^Predictive\ Failure"`
    if [ $icheck -eq "0" ]; then
      raidresult="O";
    else
      raidresult="X";
    fi
  fi
fi

echo -e "  disk_array: $(pretty_result ${raidresult}) ( app exist : $(pretty_result ${raidapp_exist}) ) ";
if [ "${raidresult}" != "O" ]; then
  echo -e "  \033[31m${raidlog}\033[0m";
fi


## Log - message
logcheck_message="-";
file_log="/var/log/message";
if [ -f "${file_log}" ]; then
  log_info=`egrep -i "(fail|error)" ${file_log}`
fi
icheck=`echo ${log_info} | wc -l`
if [ $icheck -eq "0" ]; then
  logcheck_message="X";
else
  logcheck_message="O";
fi
echo -e "  log_message: $(pretty_result ${logcheck_message}) ( find fail/error, file: ${file_log} )";
if [ "${logcheck_message}" != "O" ]; then
  echo -e "  \033[31m${log_info} \033[0m";
fi

## Log - secure
logcheck_sec="-";
file_log="/var/log/secure";
if [ -f "${file_log}" ]; then
  log_info=`egrep -i "(fail|error)" ${file_log}`
fi
icheck=`echo ${log_info} | wc -l`
if [ $icheck -eq "0" ]; then
  logcheck_sec="X";
else
  logcheck_sec="O";
fi
echo -e "  log_secure: $(pretty_result ${logcheck_sec}) ( find fail/error, file: ${file_log} )";
if [ "${logcheck_sec}" != "O" ]; then
  echo -e "  \033[31m${log_info} \033[0m";
fi


## DBMS - backup Exist

dbms_backup_check="-";
dbms_backup_cron="-";
icheck=`cat /etc/crontab | egrep "(mysql|backup)" | wc -l`
if [ $icheck -eq "0" ]; then
  dbms_backup_cron="X";
else
  dbms_backup_cron="O";
fi

if [ "${dbms_exist}" == "O" ] && [ "${dbms_backup_cron}" == "O" ]; then
  dbms_backup_check="O";
else
  dbms_backup_check="X";
fi

echo -e "  dbms_backup: $(pretty_result ${dbms_backup_check}) ( dbms exist: $(pretty_result ${dbms_exist}), cron exist: $(pretty_result ${dbms_backup_cron}) )";
echo -e "  ================================================================== ";
echo -e "    - /etc/crontab, find mysql/backup";
echo -e "  $(cat /etc/crontab | egrep "(mysql|backup)" 2>/dev/null )";
echo -e "    - each user crontab, find mysql/backup";
echo -e "  $(egrep -Ri "(mysql|backup)" /var/spool 2>/dev/null )";
echo -e "  ================================================================== ";

echo "";


## Monitoring - BB
icheck=`ps aufx | grep runbb | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  bbcheck="X";
  bbproc="X";
  bbname="X";
else
  bbexist="X";
  if [ -f '/home/bb/bb17b4/runbb.sh' ]; then
    bbexist="O";
  fi
  pcheck=0;
  if [ -f '/home/bb/bb17b4/etc/bb-proctab' ]; then
    pcheck=`cat /home/bb/bb17b4/etc/bb-proctab | grep -v "^#" | wc -l`
  fi
  if [ $pcheck -eq "0" ]; then
    bbproc="X";
  else
    bbproc="O";
  fi
  bbname=`hostname`
  if [ -f '/home/bb/bb17b4/etc/bbaliasname' ]; then
    bbname=`cat /home/bb/bb17b4/etc/bbaliasname | head -n 1`
  fi
fi

if [ "${bbexist}" == "X" ] || [ "${bbproc}" == "X" ] ; then
  bbcheck="X";
else
  bbcheck="O";
fi
echo -e "  monitoring_bb: $(pretty_result ${bbcheck}) ( exist:$(pretty_result ${bbexist}) ,proc config: $(pretty_result ${bbproc}) , bbhostname: ${bbname} )";
if [ "${bbcheck}" != "O" ]; then
  echo -e "    - /home/bb/bb17b4/runbb.sh exist: $(pretty_result ${bbexist})"
  echo -e "    - /home/bb/bb17b4/etc/bb-proctab config: $(pretty_result ${bbproc})"
fi

## Monitoring - zenius
icheck=`ps aufxww | grep zagent | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  zeniuscheck="X";
else
  zeniuscheck="O";
fi
echo -e "  monitoring_zenius: $(pretty_result ${zeniuscheck})";


## Monitoring - consignClient
icheck=`cat /etc/crontab | grep -i consignClient | wc -l`
cronlog=`cat /etc/crontab | grep -i consignClient`
if [ $icheck -eq "0" ]; then
  consigncron="X";
else
  consigncron="O";
fi
if [ -f /home/gabia/src/consignClient ]; then
  consignexist="O";
else
  consignexist="X";
fi
if [ "${consigncron}" == "O" ] && [ "${consignexist}" == "O" ]; then
  consigncheck="O";
else
  consigncheck="X";
  icheck=`echo ${os_release} |egrep -i "(centos|redhat)" | egrep "(4|5|6)"| wc -l`
  osverlog="${os_release}"
  if [ $icheck -eq "0" ]; then
    consigncheck="-";
  fi
fi
echo -e "  monitoring_consign: $(pretty_result ${consigncheck}) ( cron: $(pretty_result ${consigncron}), exist: $(pretty_result ${consignexist}) )";
if [ "${consigncheck}" != "O" ]; then
  echo -e "    - /etc/crontab, find consign: $(pretty_result ${consigncron})"
  echo -e "      \033[31m${cronlog}\033[0m"
  echo -e "    - file exist : $(pretty_result ${consignexist})"
  echo -e "    - CentOS4/5/6 only support: \033[31m${osverlog}\033[0m"
fi
echo "";



## app - netbackup
netbackupcheck="X";
netbackup_path="/usr/openv/netbackup";
netbackup_policyexist="-";
netbackup_appexist="-";

icheck=`ls -al ${netbackup_path} 2>/dev/null | wc -l`
if [ $icheck -eq "0" ]; then
  netbackup_appexist="X";
else
  netbackup_appexist="O";
  icheck=`ls -al ${netbackup_path}/exclude* 2>/dev/null | wc -l`
  if [ $icheck -eq "0" ]; then
    netbackup_policyexist="X";
  else
    netbackup_policyexist="O";
  fi
fi

if [ "${netbackup_appexist}" == "O" ] && [ "${netbackup_policyexist}" == "O" ]; then
  netbackupcheck="O";
else
  netbackupcheck="X";
fi

echo -e "  app_netbackup: $(pretty_result ${netbackupcheck}) ( app exist: $(pretty_result ${netbackupcheck}) , policy exist : $(pretty_result ${netbackupcheck}) )";
echo -e "  ================================================================== ";
echo -e "    - path list only netbackup policy  ";
echo -e "    $(cat ${netbackup_path}/exclude* 2>/dev/null | sort | uniq)";
echo -e "  ================================================================== ";

echo "";

# vi all delete
## gg    첫줄로 이동
## dG    현재 줄부터 마지막 줄 까지 삭제

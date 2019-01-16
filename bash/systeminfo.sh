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
hw_model=`dmidecode | grep "Product\ Name" | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2);print $2} '`
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
  os_release="Unknown"
fi
[ "$os_release" == "" ] && os_release="Unknown"
os_arch=`arch`
echo -e "  os: \033[32m${os_release} (${os_arch})\033[0m";



## WEB - apache
apache_version="-"
apache_bin="-"
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
      apache_version=`${apache_bin} -V | grep "^Server\ version" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo -e "  http_apache: $(pretty_result ${apachecheck}) ( ver: ${apache_version} , bin: ${apache_bin} )";
    fi
  done
fi

## WAS - tomcat
tomcat_version="-"
tomcat_bin="-"
icheck=`ps aufxww | grep java | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  tomcatcheck="X";
  echo -e "  was_tomcat: $(pretty_result ${tomcatcheck}) ( ver: ${apache_version} , bin: ${apache_bin} )";
else
  tomcatcheck="O";
  ps aufxww | grep java | grep -v grep | while read line; do
    java_bin=`echo "$line" | sed -e 's/\ /\n/g' | grep "java$"`;
    if [ -f "${java_bin}" ]; then
      tomcat_base=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.base" | awk -F\= '{print$2}'`
      if [ -n "${tomcat_base}" ]; then
        tomcat_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^Server\ version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
        echo -e "  was_tomcat: $(pretty_result ${tomcatcheck}) ( ver: ${tomcat_version} , base: ${tomcat_base} )";
        java_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^JVM\ Version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
        echo -e "  -- java: java/${java_version} ( bin: ${java_bin} )";
      fi
    fi
  done
fi


## DBMS - mysql
mysql_version="-"
mysql_bin="-"
icheck=`ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | wc -l`
if [ $icheck -eq "0" ]; then
  mysqlcheck="X";
  echo -e "  dbms_mysql: $(pretty_result ${mysqlcheck}) ( ver: ${mysql_version} , bin: ${mysql_bin} )";
else
  mysqlcheck="O";
  ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | awk '{print$12}' | uniq | while IFS= read mysql_bin ; do
    mysql_version=`strings ${mysql_bin} | grep "^mysqld\-" | sed -e 's/\-/\//g'`
    if [ `strings ${mysql_bin} | grep  "\-MariaDB$" | wc -l` -eq 1 ]; then
      mysql_version=`strings ${mysql_bin} | grep  "\-MariaDB$" | awk -F'-' '{print "MariaDB/"$1}'`
    fi
    echo -e "  dbms_mysql: $(pretty_result ${mysqlcheck}) ( ver: ${mysql_version} , bin: ${mysql_bin} )";
  done
fi


## DBMS - oracle
oracle_version="-"
oracle_bin="-"
icheck=`ps aufx | grep tnslsnr | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  oraclecheck="X";
  echo -e "  dbms_oracle: $(pretty_result ${oraclecheck}) ( ver: ${oracle_version} , home: ${oracle_home} )";
else
  oraclecheck="O";
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

## Monitoring - BB
icheck=`ps aufx | grep runbb | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  bbcheck="X";
  bbproc="X";
  bbname="X";
else
  bbcheck="O";
  pcheck=`cat /home/bb/bb17b4/etc/bb-proctab | grep -v "^#" | wc -l`
  if [ $icheck -eq "0" ]; then
    bbproc="X";
  else
    bbproc="O";
  fi
  bbname=`hostname`
  if [ -f '/home/bb/bb17b4/etc/bbaliasname' ]; then
    bbname=`cat /home/bb/bb17b4/etc/bbaliasname | head -n 1`
  fi
fi
echo -e "  monitoring_bb: $(pretty_result ${bbcheck}) ( proc config: $(pretty_result ${bbproc}) , bbhostname: ${bbname} )";


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
  icheck=`cat ${os_namefile}  | grep PRETTY_NAME | cut -d'"' -f2 | egrep -i "(centos|redhat)" | egrep "(4|5|6)"| wc -l`
  if [ $icheck -eq "0" ]; then
    consigncheck="-";
  fi
fi

echo -e "  monitoring_consign: $(pretty_result ${consigncheck}) ( cron: $(pretty_result ${consigncron}), exist: $(pretty_result ${consignexist}), CentOS4/5/6 only install )";

## config - arp
ip_gateway=`ip r | grep default | cut -d' ' -f3 | head -n 1`
icheck=`arp -a | grep "(${ip_gateway})" | wc -l`
if [ $icheck -eq "0" ]; then
  arpcheck="X";
else
  arpcheck="O";
fi
echo -e "  cfg_arpstatic: $(pretty_result ${arpcheck}) ( gateway ip: ${ip_gateway} )";


## Hardware - partition
disk_partition=`df -lh | awk '0+$5 >= 70 {print}'`
icheck=`echo ${disk_partition} | wc -l`
if [ $icheck -eq "0" ]; then
  diskcheck="X";
else
  diskcheck="O";
fi
echo -e "  disk freesize: $(pretty_result ${diskcheck}) ( over 70% )";
if [ "${diskcheck}" == "X" ]; then
  echo -e "  \033[31m$(df -lh | awk '0+$5 >= 70 {print}') \033[0m"
fi


## Hardware - array
raidapp_exist="-";
raidresult="-";
raidlog="";
if [ "$hw_vendor" == "HP" ]; then
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
elif [ "$hw_vendor" == "IBM" ] || [ "$hw_vendor" == "Dell" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${IBM_CMD}" == "" ]; then
    raidapp_exist="X";
  else
    raidapp_exist="O";
    icheck=`${IBM_CMD} -LDPDinfo -aALL -NoLog | grep "Count:" | awk '0+$4 > 0 {print}' | wc -l`
    raidlog=`${IBM_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD|^Raw\ Size|^Media\ Error|^Other\ Error|^Predictive\ Failure"`
    if [ $icheck -eq "0" ]; then
      raidresult="O";
    else
      raidresult="X";
    fi
  fi
fi

echo -e "  disk_array: $(pretty_result ${raidresult}) ( app exist : $(pretty_result ${raidapp_exist}) ) ";
if [ "${raidresult}" == "X" ]; then
  echo -e "  \033[31m${raidlog}\033[0m"
fi

## DBMS - backup Exist

dbms_backup_check="-";
dbms_backup_cron="-";
dbms_backup_log="-";
icheck=`cat /etc/crontab | egrep "(mysql|backup)" | wc -l`
if [ $icheck -eq "0" ]; then
  dbms_backup_check="X";
  dbms_backup_cron="X";
else
  dbms_backup_check="O";
  dbms_backup_cron="O";
  dbms_backup_log =`cat /etc/crontab | egrep "(mysql|backup)"`
fi
echo -e "  dbms_backup: $(pretty_result ${dbms_backup_check}) ( cron exist: $(pretty_result ${dbms_backup_cron}) )";
if [ "${dbms_backup_check}" == "X" ]; then
  echo -e "  ${dbms_backup_log}"
fi

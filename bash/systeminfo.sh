#!/bin/bash

# sudo bash -c "curl -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo.sh | bash -"
LANG=C


# system status
## Os - info
os_hostname=`hostname`
echo -e "hostname: \033[32m${os_hostname}\033[0m";

## Hardware
hw_vendor=`dmidecode | grep Vendor | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'  | awk '{gsub(/^[ \t]+/, "", $1);print $1}'`
hw_model=`dmidecode | grep "Product\ Name" | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2);print $2} '`
echo -e "hw: \033[32m${hw_vendor} ${hw_model}\033[0m";

## OS
if [ -f '/etc/os-release' ] ; then
  os_release=`cat /etc/os-release  | grep PRETTY_NAME | cut -d'"' -f2`
elif [ -f '/etc/redhat-release' ] ; then
  os_release=`cat /etc/redhat-release | head -n 1`
elif [ -f '/etc/issue' ] ; then
  os_release=`cat /etc/issue | head -n 1`
else
  os_release="Unknown"
fi
[ "$os_release" == "" ] && os_release="Unknown"
os_arch=`arch`
echo -e "os: \033[32m${os_release} (${os_arch})\033[0m";



## WEB - apache
#ps aufx | egrep "(httpd|apache)" | grep -v grep | awk '{print$11" "$2}' | grep -v '^\\_' | while IFS= read LINE ; do
ps aufx | egrep "(httpd|apache)" | grep -v '\\' | grep -v "org.apache" |  awk '{print$11" "$2}' | while IFS= read LINE ; do
  apache_bin=`echo $LINE | awk '{print$1}'`;
  apachectl_bin=`echo $LINE | awk '{print$1}' | sed -e 's/apache2/apachectl/g' -e 's/httpd/apachectl/g'`;
  apache_pid=`echo $LINE | awk '{print$2}'`;

  if [ -f "${apache_bin}" ]; then
    apache_version=`${apache_bin} -V | grep "^Server\ version" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
    echo -e "apache: \033[32m${apache_version}\033[0m";
  fi
done
    
    
## WAS - tomcat
ps aufxww | grep java | grep -v grep | while read line; do
  java_bin=`echo "$line" | sed -e 's/\ /\n/g' | grep "java$"`;
  if [ -f "${java_bin}" ]; then
    tomcat_base=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.base" | awk -F\= '{print$2}'`
    if [ -n "${tomcat_base}" ]; then
      tomcat_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^Server\ version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo -e "tomcat: \033[32mtomcat/${tomcat_version}\033[0m ( ${tomcat_base} )";
      
      java_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^JVM\ Version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo -e "java: \033[32mjava/${java_version}\033[0m ( ${java_bin} )";
    fi
  fi
done

## DBMS - mysql
ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | awk '{print$12}' | uniq | while IFS= read mysql_bin ; do
  mysql_version=`strings ${mysql_bin} | grep "^mysqld\-" | sed -e 's/\-/\//g'`
  if [ `strings ${mysql_bin} | grep  "\-MariaDB$" | wc -l` -eq 1 ]; then
    mysql_version=`strings ${mysql_bin} | grep  "\-MariaDB$" | awk -F'-' '{print "MariaDB/"$1}'`
  fi
  echo -e "mysql: \033[32m${mysql_version}\033[0m ( ${mysql_bin} )";
done

## DBMS - oracle
ps aufx | grep tnslsnr | grep -v grep | awk '{print$11}' | uniq | while IFS= read tnslsnr_bin ; do
  oracle_home=`echo $tnslsnr_bin | sed -e 's/\/bin\/tnslsnr//g' | grep "^/"`;
  
# https://docs.oracle.com/cd/E11857_01/em.111/e12255/oui2_manage_oracle_homes.htm
  oracle_inventory="${oracle_home}/inventory/ContentsXML/comps.xml";
  if [ -f "${oracle_inventory}" ]; then
    oracle_version=`cat ${oracle_home}/inventory/ContentsXML/comps.xml | grep oracle.server | head -n 1 | cut -d'"' -f4`;
  fi
  echo -e "oracle: \033[32moracle/${oracle_version}\033[0m ( ${oracle_home} )";
done



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
echo -e "monitoring_bb: \033[32m${bbcheck}\033[0m ( proc config: \033[32m${bbproc}\033[0m , bbhostname: ${bbname} )";

## Monitoring - zenius
icheck=`ps aufxww | grep zagent | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  zeniuscheck="X";
else
  zeniuscheck="O";
fi
echo -e "monitoring_zenius: \033[32m${zeniuscheck}\033[0m";


## Monitoring - consignClient
icheck=`cat /etc/crontab | grep -i consignClient | wc -l`
if [ $icheck -eq "0" ]; then
  consigncheck="X";
else
  consigncheck="O";
fi
echo -e "monitoring_consign: 033[32m${consigncheck}\033[0m";

## config - arp
ip_gateway=`ip r | grep default | cut -d' ' -f3 | head -n 1`
icheck=`arp -a | grep "(${ip_gateway})" | wc -l`
if [ $icheck -eq "0" ]; then
  arpcheck="X";
else
  arpcheck="O";
fi
echo -e "cfg_arpstatic: 033[32m${arpcheck}\033[0m ( gateway ip: ${ip_gateway} )";



## Hardware - disk
if [ "$hw_vendor" == "HP" ]; then
  [ -f '/usr/sbin/hpssacli' ] && HP_CMD='/usr/sbin/hpssacli'
  [ -f '/usr/sbin/hpacucli' ] && HP_CMD='/usr/sbin/hpacucli'
  if [ "${HP_CMD}" == "" ]; then
    raidcheck="-";
  else
    hp_slot_no=`$HP_CMD ctrl all show status | grep -i slot | awk -F'Slot' '{print$2}' | awk '{print$1}'`;
    if [ -n ${hp_slot_no} ]; then
      icheck=`$HP_CMD ctrl slot=$hp_slot_no show config | grep . | egrep "(logical|physical)" | grep -v "OK)" | wc -l`
      if [ $icheck -eq "0" ]; then
        raidcheck="O";
      else
        raidcheck="X";
      fi
    else
      raidcheck="-";
    fi
  fi
elif [ "$hw_vendor" == "IBM" ] || [ "$hw_vendor" == "Dell" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${IBM_CMD}" == "" ]; then
    raidcheck="-";
  else
    ${IBM_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD|^Raw\ Size" | sed -e 's/\,/\:/g' -e 's/\[/\:/g' |  awk -F':' '{gsub(/[ \t]+/, "", $2);print $1":"$2}' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/RAID/\nRAID/g' | grep .
  fi
else
  raidcheck="-";

fi
echo -e "disk_array: 033[32m${raidcheck}\033[0m"


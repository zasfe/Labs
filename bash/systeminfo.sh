#!/bin/bash

# sudo bash -c "curl -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo.sh | bash -"
LANG=C


# system status
## Os - info
os_hostname=`hostname`
echo "type=os_name;value=${os_hostname}";

## Hardware - model
hw_vendor=`dmidecode | grep Vendor | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'  | awk '{gsub(/^[ \t]+/, "", $1);print $1}'`
echo "type=hw_vendor;value=${hw_vendor};";
hw_model=`dmidecode | grep "Product\ Name" | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2);print $2} '`
echo "type=hw_model;value=${hw_model};";


if [ -f '/etc/os-release' ] ; then
  os_release=`cat /etc/os-release  | grep PRETTY_NAME | cut -d'"' -f2`
elif [ -f '/etc/redhat-release' ] ; then
  os_release=`cat /etc/redhat-release | head -n 1`
else
  os_release=`cat /etc/issue | head -n 1`
fi
[ "$os_release" == "" ] && os_release="Unknown"
os_arch=`arch`
echo "type=os;value=${os_release} (${os_arch});";



## WEB - apache
#ps aufx | egrep "(httpd|apache)" | grep -v grep | awk '{print$11" "$2}' | grep -v '^\\_' | while IFS= read LINE ; do
ps aufx | egrep "(httpd|apache)" | grep -v '\\' | grep -v "org.apache" |  awk '{print$11" "$2}' | while IFS= read LINE ; do
  apache_bin=`echo $LINE | awk '{print$1}'`;
  apachectl_bin=`echo $LINE | awk '{print$1}' | sed -e 's/apache2/apachectl/g' -e 's/httpd/apachectl/g'`;
  apache_pid=`echo $LINE | awk '{print$2}'`;

  if [ -f "${apache_bin}" ]; then
    apache_version=`${apache_bin} -V | grep "^Server\ version" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
    echo "type=apache_version;value=${apache_version}"
  fi
done
    
    
## WAS - tomcat
ps aufxww | grep java | grep -v grep | while read line; do
  java_bin=`echo "$line" | sed -e 's/\ /\n/g' | grep "java$"`;
  if [ -f "${java_bin}" ]; then
    tomcat_base=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.base" | awk -F\= '{print$2}'`
    if [ -n "${tomcat_base}" ]; then
      tomcat_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^Server\ version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo "type=tomcat_version;value=${tomcat_version};value2=${tomcat_base};";
      
      java_version=`exec ${java_bin} -cp ${tomcat_base}/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "^JVM\ Version\:" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
      echo "type=java_version;value=java/${java_version};value2=${java_bin};";
    fi
  fi
done

## DBMS - mysql
ps aufx | grep mysqld | grep -v grep | grep -v mysqld_safe | awk '{print$12}' | uniq | while IFS= read mysql_bin ; do
  mysql_version=`strings ${mysql_bin} | grep "^mysqld\-" | sed -e 's/\-/\//g'`
  if [ `strings ${mysql_bin} | grep  "\-MariaDB$" | wc -l` -eq 1 ]; then
    mysql_version=`strings ${mysql_bin} | grep  "\-MariaDB$" | awk -F'-' '{print "MariaDB/"$1}'`
  fi
  echo "type=mysql_version;value=${mysql_version};value2=${mysql_bin};";
done

## DBMS - oracle
ps aufx | grep tnslsnr | grep -v grep | awk '{print$11}' | uniq | while IFS= read tnslsnr_bin ; do
  oracle_home=`echo $tnslsnr_bin | sed -e 's/\/bin\/tnslsnr//g' | grep "^/"`;
  oracle_lib="${oracle_home}/lib/libclntsh.so";
  if [ -f "${oracle_lib}" ]; then
#    oracle_version=`${oracle_opatch} lsinventory | head -n 1 | awk '{print$3}'`
    oracle_version=`strings ${oracle_lib} | grep '^Version [0-9]' | awk '{print$2}'`;
    echo "type=oracle_version;value=oracle/${oracle_version};value2=${oracle_home};";
  fi
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

echo "type=monitoring_bb;value=${bbcheck};value2=${bbproc};value3=${bbname}";

## Monitoring - zenius
icheck=`ps aufxww | grep zagent | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  zeniuscheck="X";
else
  zeniuscheck="O";
fi
echo "type=monitoring_zenius;value=${zeniuscheck};";


icheck=`cat /etc/crontab | grep -i consignClient | wc -l`
if [ $icheck -eq "0" ]; then
  consigncheck="X";
else
  consigncheck="O";
fi
echo "type=monitoring_consign;value=${consigncheck};";


ip_gateway=`ip r | grep default | cut -d' ' -f3 | head -n 1`
icheck=`arp -a | grep " ${ip_gateway} " | wc -l`
if [ $icheck -eq "0" ]; then
  arpcheck="X";
else
  arpcheck="O";
fi
echo "type=arp_static;value=${arpcheck};value2=${ip_gateway}";

## Hardware - disk
if [ "$hw_vendor" == "HP" ]; then
  [ -f '/usr/sbin/hpssacli' ] && HP_CMD='/usr/sbin/hpssacli'
  [ -f '/usr/sbin/hpacucli' ] && HP_CMD='/usr/sbin/hpacucli'
  if [ "${HP_CMD}" == "" ]; then
    disk_raid="Unkonwn/HP";
    disk_raid_size="Unkonwn";
    echo "type=disk_array;value=${disk_raid};value2=${disk_raid_size};"
  else
    hp_slot_no=`$HP_CMD ctrl all show status | grep -i slot | awk -F'Slot' '{print$2}' | awk '{print$1}'`;
    $HP_CMD ctrl slot=$hp_slot_no show config | grep .
  fi
elif [ "$hw_vendor" == "IBM" ] || [ "$hw_vendor" == "Dell" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${IBM_CMD}" == "" ]; then
    disk_raid="Unkonwn/IBM";
    disk_raid_size="Unkonwn";
    echo "type=disk_array;value=${disk_raid};value2=${disk_raid_size};"
  else
    ${IBM_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD|^Raw\ Size" | sed -e 's/\,/\:/g' -e 's/\[/\:/g' |  awk -F':' '{gsub(/[ \t]+/, "", $2);print $1":"$2}' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/RAID/\nRAID/g' | grep .
  fi
else
  disk_raid="Unkonwn/$hw_vendor";
  disk_raid_size="Unkonwn";
  echo "type=disk_array;value=${disk_raid};value2=${disk_raid_size};"
fi


T_TERMINAL_PORT=`cat /etc/ssh/sshd_config | grep -v "^#" | grep Port | grep -v GatewayPorts | awk '{print$2}'`
if [ "${T_TERMINAL_PORT}" == "" ]; then
  T_TERMINAL_PORT="22"
fi
echo "type=sshd;value=${T_TERMINAL_PORT};";

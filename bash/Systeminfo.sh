#!/bin/bash

LANG=C


function get_ip_byping {
#  result_ping=`timeout 1 ping -c 1 -i 1000 "$1" | grep "^PING"`;
  result_ping=`timeout 1 dig "$1" +short`;
  result_check=`echo ${result_ping} | grep "^PING" | wc -l`;
  if [ "${result_check}" == "1" ]; then
    result_ip=`echo ${result_ping} | sed -e 's/(/ /g' -e 's/)/ /g' | awk '{print$3}'`;
    echo ${result_ip};
  else
    echo "unknown";
  fi
  return;
}

function get_ip_bydig {
  result_ip=`timeout 1 dig "$1" +short`;
  if [ `echo ${result_ip} | grep "\." | wc -l` -eq 1 ]; then
    echo ${result_ip};
  else
    echo "unknown";
  fi
  return;
}



function check_localip {
  result_check=`ifconfig | grep inet | sed -e 's/:/ /g' | awk '{print" "$3}' | grep $1 | awk '{gsub(/^[ ]+/, "", $1);print $1}' | wc -l`
  if [ "${result_check}" == "1" ]; then
    echo "O";
  else
    echo "X";
  fi
  return;
}





## Hardware - model
hw_vendor=`dmidecode | grep Vendor | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'  | awk '{gsub(/^[ \t]+/, "", $1);print $1}'`
echo "type=hw_vendor;value=${hw_vendor};";
hw_model=`dmidecode | grep "Product\ Name" | head -n 1 | awk -F':' '{gsub(/^[ \t]+/, "", $2); gsub(/[ \t]+$/, "", $2);print $2} '`
echo "type=hw_model;value=${hw_model};";

## Hardware - CPU
cpu_model=`grep "model name" /proc/cpuinfo | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}' | head -n 1 | sed -e 's/\ \ /\ /g' -e 's/\ \ /\ /g' -e 's/\ \ /\ /g' -e 's/\ \ /\ /g'`
echo "type=cpu_model;value=${cpu_model};";
cpu_count_p=`grep "physical id" /proc/cpuinfo | sort | uniq  | wc -l`
echo "type=cpu_count_p;value=${cpu_count_p};";
cpu_count_v=`grep "processor" /proc/cpuinfo | sort | uniq  | wc -l`
echo "type=cpu_count_v;value=${cpu_count_v};";

## Hardware - Memory
memory_total=`grep "MemTotal" /proc/meminfo | awk -F':' '{gsub(/[ \t]+/, "", $2);gsub(/kB/, "", $2); print $2}'`
echo "type=memory_total;value=${memory_total};";
memory_total_g=`grep "MemTotal" /proc/meminfo | awk -F':' '{gsub(/[ \t]+/, "", $2);gsub(/kB/, "", $2); $2=$2/(1024^2); printf "%.0f",$2}'`
echo "type=memory_total_g;value=${memory_total_g};";

if [ -f `which dmidecode` ]
then
  `which dmidecode`  -t 17 | egrep "(Size:|Locator:|Type:|Manufacturer:|Number:)" | grep -v Bank | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/Size:/\nSize:/g' -e 's/Locator:/:Locator:/g' -e 's/Type:/:Type:/g' -e 's/Manufacturer:/:Manufacturer:/g' -e 's/Serial Number:/:Serial Number:/g' -e 's/Part Number:/:Part Number:/g' -e "s/\t//g" -e "s/  / /g" -e "s/  / /g"  -e "s/  / /g" -e 's/: /:/g' -e 's/ :/:/g'  | grep -v Installed | while IFS= read line ; do
    awk -F':' '{print"type=memory_list;value="$2";value2="$4";value3="$6";value4="$8";value5="$10";value6="$12}'
  done
fi


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
    $HP_CMD ctrl slot=$hp_slot_no show config | grep . | sed -e "s/^[\t ]*//g" | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/array/\narray/g' | grep "^array" | while IFS= read line ; do
      disk_raid=`echo $line | awk '{gsub(",", "", $13);print$12" "$13}'`;
      disk_raid_no=`echo $line | awk '{gsub(",", "", $2);print$2}'`;
      echo $line | sed -e 's/physicaldrive/\nphysicaldrive/g' | grep physicaldrive | awk '{gsub(",", "", $7);gsub(",", "", $9);print $7" "$8" "$9}' | while IFS= read disk_raid_size ; do
        echo "type=disk_array;value=${disk_raid}/${disk_raid_no};value2=${disk_raid_size};"
      done
    done
  fi
elif [ "$hw_vendor" == "IBM" ] || [ "$hw_vendor" == "Dell" ]; then
  [ -f '/opt/MegaRAID/MegaCli/MegaCli' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli'
  [ -f '/opt/MegaRAID/MegaCli/MegaCli64' ] && IBM_CMD='/opt/MegaRAID/MegaCli/MegaCli64'

  if [ "${IBM_CMD}" == "" ]; then
    disk_raid="Unkonwn/IBM";
    disk_raid_size="Unkonwn";
    echo "type=disk_array;value=${disk_raid};value2=${disk_raid_size};"
  else
    ${IBM_CMD} -LDPDinfo -aALL -NoLog | grep . | sed -e "s/^[\t ]*//g" | egrep "^RAID\ Level|^PD|^Raw\ Size" | sed -e 's/\,/\:/g' -e 's/\[/\:/g' |  awk -F':' '{gsub(/[ \t]+/, "", $2);print $1":"$2}' | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/RAID/\nRAID/g' | grep .  | while IFS= read line ; do
      disk_raid=`echo $line | awk -F':' '{gsub(/Primary-/, "", $2);print$2}' | awk '{print"RAID "$1}'`;
      disk_raid_no="";
      echo $line | sed -e 's/PD/\nPD/g' | grep PD | sed -e 's/\:/ /g' | grep -i size | while IFS= read line2 ; do
        disk_raid_size=`echo ${line2} | tr "[a-z]" "[A-Z]" | awk -F'SIZE' '{gsub(/[ \t]+/, "", $2);gsub("MB", " MB", $2);gsub("GB", " GB", $2);gsub("TB", " TB", $2);print$2}'`;
        if [ "`echo ${line2} | grep -i type | wc -l`" -eq "0" ]; then
          disk_raid_type="unknown";
        else
          disk_raid_type=`echo ${line2} | awk '{print$3}'`;
        fi
        echo "type=disk_array;value=${disk_raid};value2=${disk_raid_type} ${disk_raid_size};"
      done
    done
  fi
else
  disk_raid="Unkonwn/$hw_vendor";
  disk_raid_size="Unkonwn";
  echo "type=disk_array;value=${disk_raid};value2=${disk_raid_size};"
fi

if [ -f "/sbin/parted" ]; then
  icheck=`/sbin/parted -h | grep "\-l" | wc -l`;
  if [ "${icheck}" -eq "1" ]; then
    /sbin/parted -l print | egrep "^Model|^Disk" | sed ':a;N;$!ba;s/\n/ /g' | sed -e 's/Model/\nModel/g' -e 's/Disk/\:Disk/g' | grep . | while IFS= read line ; do
      disk_model=`echo ${line} | awk -F':' '{gsub(/^[ \t]+/, "", $2);gsub(/[ \t]+$/, "", $2); print $2}'`
      disk_model_size=`echo ${line} | awk -F':' '{gsub(/^[ \t]+/, "", $4);gsub(/[ \t]+$/, "", $4); print $4}'`
      echo "type=disk_noarray;value=${disk_model};value2=${disk_model_size};"
    done
  fi
else
  disk_model="Unkonwn";
  disk_model_size="Unkonwn";
  echo "type=disk_noarray;value=${disk_model};value2=${disk_model_size};"
fi

## OS - info
if [ -f '/etc/redhat-release' ] ; then
  os_release=`cat /etc/redhat-release | head -n 1`
else
  os_release=`cat /etc/issue | head -n 1`
fi
[ "$os_release" == "" ] && os_release="Unknown"
os_arch=`arch`
echo "type=os;value=${os_release} (${os_arch});";

## WEB - apache + php + url
#ps aufx | egrep "(httpd|apache)" | grep -v grep | awk '{print$11" "$2}' | grep -v '^\\_' | while IFS= read LINE ; do
ps aufx | egrep "(httpd|apache)" | grep -v '\\' | grep -v "org.apache" |  awk '{print$11" "$2}' | while IFS= read LINE ; do
  apache_bin=`echo $LINE | awk '{print$1}'`;
  apachectl_bin=`echo $LINE | awk '{print$1}' | sed -e 's/apache2/apachectl/g' -e 's/httpd/apachectl/g'`;
  apache_pid=`echo $LINE | awk '{print$2}'`;

  if [ -f "${apache_bin}" ]; then
#   apache_version=`strings ${apache_bin} | grep "^Apache\/" | head -n 1`;
#   if [ -n "${apache_version}" ]; then
      # Apache 1.x
      apache_version=`${apache_bin} -V | grep "^Server\ version" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
#  fi

    HTTPD_ROOT=`${apache_bin} -V | grep "HTTPD_ROOT" | awk -F'=' '{gsub(/^[ \t]+/, "", $2); print $2}' | sed -e 's/\"//g'`;
    SERVER_CONFIG_FILE=`${apache_bin} -V | grep "SERVER_CONFIG_FILE" | cut -d "=" -f 2 | sed -e 's/\"//g'`;

    echo "type=apache_version;value=${apache_version};value2=${apache_bin};value3=${HTTPD_ROOT}/${SERVER_CONFIG_FILE};"
  
    path_php_module=`grep -i php ${HTTPD_ROOT}/${SERVER_CONFIG_FILE} | grep LoadModule  | awk -F'#' '{gsub(/^[ \t]+/, "", $1); print $1}'  | awk '{print$3}'`;
    if [ "${path_php_module}" == "" ]; then
      if [ "${HTTPD_ROOT}" == "/etc/httpd" ]; then
        path_php_module=`grep -i php ${HTTPD_ROOT}/conf.d/*.conf | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}' | grep LoadModule  | awk -F'#' '{gsub(/^[ \t]+/, "", $1); print $1}'  | awk '{print$3}'`; 
      elif [ "${HTTPD_ROOT}" == "/etc/apache2" ]; then
        path_php_module=`grep -i php ${HTTPD_ROOT}/mods-enabled/*.* | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}' | grep LoadModule  | awk -F'#' '{gsub(/^[ \t]+/, "", $1); print $1}'  | awk '{print$3}'`;
      else
        path_php_module=`grep -i php ${HTTPD_ROOT}/${SERVER_CONFIG_FILE} | grep LoadModule | awk -F'#' '{gsub(/^[ \t]+/, "", $1); print $1}' | awk '{print$3}'`; 
      fi
    fi

    if [ -n "${path_php_module}" ]; then
      echo "${path_php_module}" | while IFS= read php_module ; do
        if [ -f "${HTTPD_ROOT}/${php_module}" ]; then
          php_version=`strings ${HTTPD_ROOT}/${php_module} | grep "X-Powered-By" | awk '{gsub(/^[ \t]+/, "", $2); print $2}'`;
          php_bin=`strings ${HTTPD_ROOT}/${php_module} | grep "\.\/configure" | sed -e 's/\ /\n/g' -e "s/'//g" | grep "\-\-prefix\=" | awk -F'=' '{gsub(/^[ \t]+/, "", $2); print $2"/bin/php"}'`;
          php_ini=`${php_bin} --ini 2>nul | grep "^Loaded" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
          echo "type=php_version;value=${php_version};value2=${php_bin};value3=${php_ini}"
        elif [ -f "${php_module}" ]; then
          php_version=`strings ${php_module} | grep "X-Powered-By" | awk '{gsub(/^[ \t]+/, "", $2); print $2}'`;
          php_bin=`strings ${php_module} | grep "\.\/configure" | sed -e 's/\ /\n/g' -e "s/'//g" | grep "\-\-prefix\=" | awk -F'=' '{gsub(/^[ \t]+/, "", $2); print $2"/bin/php"}'`;
          php_ini=`${php_bin} --ini 2>nul | grep "^Loaded" | awk -F':' '{gsub(/^[ \t]+/, "", $2); print $2}'`;
          echo "type=php_version;value=${php_version};value2=${php_bin};value3=${php_ini}"
        fi
      done
    fi
 
    if [ `${apache_bin} -t -D DUMP_VHOSTS 2>&1 | grep ")$" | sed -e 's/:/ /g' | grep -v "default\ server"| awk '{print$2":"$3":"$4}' | grep ":" | wc -l` -eq 0 ]
    then
      echo "type=apache_url;value=unknown;"
    else
      ${apache_bin} -t -D DUMP_VHOSTS 2>&1 | grep ")$" | sed -e 's/:/ /g' | grep -v "default\ server" | awk '{print$2":"$3":"$4}' | while IFS= read APACHEURL ; do
        if [ `echo ${APACHEURL} | grep ":" | wc -l` -eq 1 ]
        then
          if [ `echo ${APACHEURL} | grep ":namevhost:" | wc -l` -eq 0 ]
          then
            apache_url=`echo ${APACHEURL} | awk -F':' '{print $2}'`
          else
            apache_url=`echo ${APACHEURL} | awk -F':' '{print $3}'`
          fi
#          apache_url_ip=`get_ip_byping ${apache_url}`;
	  apache_url_ip=`get_ip_bydig ${apache_url}`;
          apache_url_check=`check_localip ${apache_url_ip}`;
          echo "type=apache_url;value=${apache_url};value1=${apache_url_ip};value2=${apache_url_check}";
        fi
      done
    fi

  fi
done


## WAS - tomcat
ps aufxww | grep java | grep -v grep | while read line; do
  java_bin=`echo "$line" | sed -e 's/\ /\n/g' | grep "java$"`;
#  java_pid=`echo "$line" | awk '{print$2}'`;
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
icheck=`ps aufxww | grep runbb | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  bbcheck="X";
else
  bbcheck="O";
fi
echo "type=monitoring_bb;value=${bbcheck};";

## Monitoring - zenius
icheck=`ps aufxww | grep zagent | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  zeniuscheck="X";
else
  zeniuscheck="O";
fi
echo "type=monitoring_zenius;value=${zeniuscheck};";

# WEB - webcon
icheck=`ps aufxww | grep -i webcon | grep -v grep | wc -l`
if [ $icheck -eq "0" ]; then
  if [ $(ps aufxww | grep java | grep -v grep | wc -l) -eq "0" ]; then
    # No tomcat
    webconcheck="X";
    webcontype="none";
    echo "type=webcon;value=${webconcheck};value2=${webcontype};";
  else
    ps aufxww | grep java | grep -v grep | while read line; do
      java_pid=`echo "$line" | awk '{print$2}'`;
      tomcat_base=`echo "$line" | sed -e 's/\ /\n/g' | grep "^-Dcatalina.base" | awk -F\= '{print$2}'`
      if [ -n "${tomcat_base}" ] && [ -n "${java_pid}" ]; then
        icheck2=`lsof -p ${java_pid} | grep -i webcon | grep -i jar | wc -l`;
        if [ "$icheck2" -eq "0" ]; then
          webconcheck="X";
          webcontype="tomcat";
        else
          webconcheck="O";
          webcontype="tomcat";
        fi
        echo "type=webcon;value=${webconcheck};value2=${webcontype};";
      else
        webconcheck="X";
        webcontype="none";
        echo "type=webcon;value=${webconcheck};value2=${webcontype};";
      fi
    done
  fi
else
  webconcheck="O";
  webcontype="apache";
  echo "type=webcon;value=${webconcheck};value2=${webcontype};";
fi

# OS - uptime
os_uptime=`uptime | awk '{print $3}'`
echo "type=os_uptime;value=${os_uptime};";

T_TERMINAL_PORT=`cat /etc/ssh/sshd_config | grep -v "^#" | grep Port | grep -v GatewayPorts | awk '{print$2}'`
if [ "${T_TERMINAL_PORT}" == "" ]; then
  T_TERMINAL_PORT="22"
fi
echo "type=sshd;value=${T_TERMINAL_PORT};";

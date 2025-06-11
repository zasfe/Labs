#!/usr/bin/env bash
LANG=C

Hostname=`hostname`
uptime=`uptime | awk -F " " 'sub(",","",$4) {print $3,$4}'`
if which ip >/dev/null; then
    interface=$(ip route get 1.1.1.1 | awk '/dev/ { print $5 }')
    ip=$(ip -o -4 addr show ${interface} scope global | awk '{print $4;}' | cut -d/ -f 1)
else
    interface=$(route get 1.1.1.1 | awk '/interface:/ { print $2 }')
    ip=$(ifconfig ${interface} | grep 'inet ' | awk '{print $2}')
fi
Ipaddr="${ip} (${interface})"
gatewayip=`ip route list | egrep "^default" | awk '{print$3" ("$5")"}'`
PTotmem=`free -m | grep Mem | awk '{print $2}'`
PUsemem=`free -m | grep Mem | awk '{print $3}'`
PMemper=`expr \( ${PUsemem} \* 100 \/ ${PTotmem} \)`
STotmem=`free -m | grep Swap | awk '{print $2}'`
SUsemem=`free -m | grep Swap | awk '{print $3}'`
SMemper="-"
if (("${STotmem}" > 0 ))
then
    SMemper=`expr \( ${SUsemem} \* 100 \/ ${STotmem} \)`
fi
echo "                                                           "
echo -e "\033[34m ========================================================================= \033[0m    "
echo "                                                           "
echo -e "\033[32m     [ $Hostname ]                       \033[0m"
echo "                                                           "
echo -e "\033[0m - IP Address : \033[32m $Ipaddr                 "
# echo -e "\033[0m - Gateway IP : \033[32m $gatewayip                 "
echo -e "\033[0m - System Uptime : \033[32m $uptime              "
echo -e "\033[0m - Phys Memory usage : \033[32m${PUsemem}M / ${PTotmem}M (\033[31m${PMemper}%\033[32m) "
echo -e "\033[0m - Swap Memory usage : \033[32m${SUsemem}M / ${STotmem}M (\033[31m${SMemper}%\033[32m) "
echo -e "\033[0m - File System usage (Over 70%)                  "
echo -e "\033[31m"
Fsyslist=`df -h | awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -ie ":" -e "^/" | grep -v "/dev/loop" | grep -e "[7-9][0-9]%" -e "100%" | wc -l`
if (( "${Fsyslist}" > 0 ))
then
    df -h | awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -ie ":" -e "^/" -e "Filesystem" | grep -v "/dev/loop" | grep -e "[7-9][0-9]%" -e "100%" -e "Filesystem"
    echo ""
fi

if [ -f ${HOME}/managed ]; then
        echo -e "\033[32m # Important execute command \033[0m"
        echo ""
        cat ${HOME}/managed
        echo ""
fi

if [ -f ${HOME}/serviceport_check.sh ] && [ -x ${HOME}/serviceport_check.sh ]; then
        /bin/bash ${HOME}/serviceport_check.sh
fi
echo -e "\033[34m ========================================================================= \033[0m    "
echo ""

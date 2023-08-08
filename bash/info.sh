#!/bin/sh
Hostname=`hostname`
uptime=`uptime | awk -F " " 'sub(",","",$4) {print $3,$4}'`
Ipaddr=`ip addr show | grep "inet " | grep global | awk '{print$2 " (" $7 ")"}'`
gatewayip=`ip route list | egrep "^default" | awk '{print$3" ("$5")"}'`
PTotmem=`free -m | grep Mem | awk '{print $2}'`
PUsemem=`free -m | grep Mem | awk '{print $3}'`
PMemper=`expr \( ${PUsemem} \* 100 \/ ${PTotmem} \)`
STotmem=`free -m | grep Swap | awk '{print $2}'`
SUsemem=`free -m | grep Swap | awk '{print $3}'`
SMemper=`expr \( ${SUsemem} \* 100 \/ ${STotmem} \)`
echo "                                                           "
echo -e "\033[34m ========================================================================= \033[0m    "
echo "                                                           "
echo -e "\033[32m     [ $Hostname ]                       \033[0m"
echo "                                                           "
echo -e "\033[0m - IP Address : \033[32m $Ipaddr                 "
echo -e "\033[0m - Gateway IP : \033[32m $gatewayip                 "
echo -e "\033[0m - System Uptime : \033[32m $uptime              "
echo -e "\033[0m - Phys Memory usage : \033[32m${PUsemem}M / ${PTotmem}M (\033[31m${PMemper}%\033[32m) "
echo -e "\033[0m - Swap Memory usage : \033[32m${SUsemem}M / ${STotmem}M (\033[31m${SMemper}%\033[32m) "
echo -e "\033[0m - File System usage (Over 70%)                  "
echo -e "\033[31m"
Fsyslist=`df -h | awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -ie ":" -e "^/:" | awk  '{print $6}'`
if ((`echo $Fsyslist | wc -l` > 0))
then
        df -h | head -n 1
fi
for LIST in $Fsyslist
do
        SPACE=`df -h $LIST |awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -v "Filesystem" | grep -ie ":" -e "^/:"  | awk  '{print $5}'| awk -F'%' '{print $1}'`
        if (("$SPACE" > 70))
        then
                df -h $LIST |awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -v "Filesystem"
        fi
done
echo "                                                           "
echo -e "\033[32m # Important execute command \033[0m"
echo ""
if [ -f ${HOME}/managed ]; then
        cat ${HOME}/managed
fi
echo ""
echo -e "\033[34m ========================================================================= \033[0m    "
echo "                                                           "

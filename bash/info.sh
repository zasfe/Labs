##/bin/sh
Hostname=`hostname`
uptime=`uptime | awk -F " " '{print $3,$4}'`
Ipaddr=`ip addr show |grep "inet " |awk -F" " '{print $2}' | grep -v "127.0.0.1" | paste -sd ","`
PTotmem=`free -m | grep Mem | awk '{print $2}'`
PUsemem=`free -m | grep Mem | awk '{print $3}'`
PMemper=`expr \( ${PUsemem} \* 100 \/ ${PTotmem} \)`
STotmem=`free -m | grep Swap | awk '{print $2}'`
SUsemem=`free -m | grep Swap | awk '{print $3}'`
SMemper=`expr \( ${SUsemem} \* 100 \/ ${STotmem} \)`
cat /dev/null > /home/gabia/diskuse
Fsyslist=`df -h | awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' |grep '^/'| awk  '{print $6}'`
for LIST in $Fsyslist
do
        SPACE=`df -h $LIST |awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -v "Filesystem" | grep '^/'| awk  '{print $5}'| awk -F'%' '{print $1}'`
        WHERE=`df -h $LIST |awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' | grep -v "Filesystem" | grep '^/'| awk  '{print $6}'`
        if (("$SPACE" > 70))
        then
                df -h $LIST |awk '{if (NF>1) {print $0} else {printf ("%s ", $1)}}' >> /home/gabia/diskuse
        fi
done
echo "                                                           "
echo -e "\033[34m ========================================================================= \033[0m    "
echo "                                                           "
echo -e "\033[32m     [ $Hostname ]                       \033[0m"
echo "                                                           "
echo -e "\033[0m - IP Address : \033[32m $Ipaddr                 "
echo -e "\033[0m - System Uptime : \033[32m $uptime              "
echo -e "\033[0m - Phys Memory usage : \033[32m${PUsemem}M / ${PTotmem}M (\033[31m${PMemper}%\033[32m) "
echo -e "\033[0m - Swap Memory usage : \033[32m${SUsemem}M / ${STotmem}M (\033[31m${SMemper}%\033[32m) "
echo -e "\033[0m - File System usage (Over 70%)                  "
echo -e "\033[31m`cat /home/gabia/diskuse | sort -r | uniq`"
echo "                                                           "
echo -e "\033[34m ========================================================================= \033[0m    "
echo "                                                           "

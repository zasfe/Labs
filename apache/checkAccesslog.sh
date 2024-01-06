#!/bin/sh


if [ -f "$1"  ] ; then
        logfile="$1"
else
        echo " Log File Is not Exist! "
        exit;
fi

if [ -n "$2"  ] ; then
        ipaddress="$2"
else
        echo " Ipaddress add plz!";
        exit;
fi


echo "";
echo "# File Name : $logfile / $ipaddress ";
echo "";
echo "- Url List ( Max 10 )";
cat $logfile | grep "$2" | awk -F\" '{print $2}' | sort | uniq -c | sort -r | head -n 10
echo "";
echo "- User Agent ( Max 10 )";
cat $logfile | grep "$2" | awk -F\" '{print $6}' | sort | uniq -c | sort -r | head -n 10

echo "";

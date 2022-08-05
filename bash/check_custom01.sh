while true; 
	do sleep 1;
	head -v -n 8 /proc/meminfo; 
	head -v -n 2 /proc/stat /proc/version /proc/uptime /proc/loadavg /proc/sys/fs/file-nr /proc/sys/kernel/hostname; 
	tail -v -n 16 /proc/net/dev;
	echo '==> /proc/df <==';
	df -l;
	echo '==> /proc/netstat <==';
	netstat -tpan | grep -Ev ' [a-fA-F:]*([0-9.]+):[0-9]+ +[a-fA-F:]*(?):[0-9]+ | TIME_WAIT| CLOSING';
	echo '==> /proc/who <==';
	who;
	echo '==> /proc/end <==';

done

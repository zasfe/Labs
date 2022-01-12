# https://m.clien.net/service/board/lecture/13838341

mkdir /tmp/asus_jffs
mount -t jffs2 /dev/mtdblock5 /tmp/asus_jffs
rm -rf /tmp/asus_jffs/*
sync && umount /tmp/asus_jffs
rm -rf /jffs/.sys/RT-AC68U
nvram unset fw_check && nvram commit && reboot

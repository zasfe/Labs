#1. edit cmdline.txt 
#dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
#ip=192.168.219.129



sudo umount /dev/sda
sudo mkfs.ext4 /dev/sda
sudo mkdir -p /Tdown
sudo mount /dev/sda /Tdown
echo -e "/dev/sda /Tdown ext4 defaults 0 0" >> /etc/fstab

sudo useradd -d /Tdown Tdown
sudo echo -e "Tdown" | passwd Tdown
sudo chmod 777 /Tdown
sudo chown -R Tdown /Tdown

sudo apt-get install transmission-daemon
sudo /etc/init.d/transmission-daemon stop

# /etc/transmission-daemon/settings.json
if [ -e /etc/transmission-daemon/settings.json ]; then
  sudo sed -i 's/"download-dir": "\/var\/lib\/transmission-daemon\/downloads",/"download-dir": "\/Tdown",/' /etc/transmission-daemon/settings.json
  sudo sed -i 's/"incomplete-dir": "\/root\/Downloads",/"incomplete-dir": "\/Tdown",/' /etc/transmission-daemon/settings.json

  sudo sed -i 's/"rpc-username": "transmission",/"rpc-username": "tr",/' /etc/transmission-daemon/settings.json
  sudo sed -i 's/"rpc-password": "{df6efdd717bc8c718674956b985f86fec3d36b16VeqGhBy.",/"rpc-password": "mi",/' /etc/transmission-daemon/settings.json

  sudo sed -i 's/"rpc-whitelist-enabled": true,/"rpc-whitelist-enabled": false,/' /etc/transmission-daemon/settings.json
fi


# /var/lib/transmission-daemon/info/settings.json
if [ -e /var/lib/transmission-daemon/info/settings.json ]; then
  sudo sed -i 's/"download-dir": "\/var\/lib\/transmission-daemon\/downloads",/"download-dir": "\/Tdown",/' /var/lib/transmission-daemon/info/settings.json
  sudo sed -i 's/"incomplete-dir": "\/root\/Downloads",/"incomplete-dir": "\/Tdown",/' /var/lib/transmission-daemon/info/settings.json

  sudo sed -i 's/"rpc-username": "transmission",/"rpc-username": "tr",/' /var/lib/transmission-daemon/info/settings.json
  sudo sed -i 's/"rpc-password": "{df6efdd717bc8c718674956b985f86fec3d36b16VeqGhBy.",/"rpc-password": "mi",/' /var/lib/transmission-daemon/info/settings.json

  sudo sed -i 's/"rpc-whitelist-enabled": true,/"rpc-whitelist-enabled": false,/' /var/lib/transmission-daemon/info/settings.json
fi


# /root/.config/transmission-daemon/settings.json
if [ -e /root/.config/transmission-daemon/settings.json ]; then
  sudo sed -i 's/"download-dir": "\/var\/lib\/transmission-daemon\/downloads",/"download-dir": "\/Tdown",/' /root/.config/transmission-daemon/settings.json
  sudo sed -i 's/"incomplete-dir": "\/root\/Downloads",/"incomplete-dir": "\/Tdown",/' /root/.config/transmission-daemon/settings.json

  sudo sed -i 's/"rpc-username": "transmission",/"rpc-username": "tr",/' /root/.config/transmission-daemon/settings.json
  sudo sed -i 's/"rpc-password": "{df6efdd717bc8c718674956b985f86fec3d36b16VeqGhBy.",/"rpc-password": "mi",/' /root/.config/transmission-daemon/settings.json

  sudo sed -i 's/"rpc-whitelist-enabled": true,/"rpc-whitelist-enabled": false,/' /root/.config/transmission-daemon/settings.json
fi

chown -R debian-transmission /Tdown/
chgrp -R debian-transmission /Tdown/
chmod -R 770 /Tdown/
addgroup pi debian-transmission

sudo /etc/init.d/transmission-daemon start

echo "http://192.168.219.219:9091/transmission/web/"


## vsftp
apt-get install vsftpd

/etc/init.d/vsftpd stop

# /etc/vsftpd.conf

sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
sed -i 's/^#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#ascii_upload_enable=YES/ascii_upload_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#ascii_download_enable=YES/ascii_download_enable=YES/' /etc/vsftpd.conf
sed -i 's/^#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf

/etc/init.d/vsftpd start

useradd -d /Tdisk/download -G debian-transmission tr
echo -e "mi\nmi\n" | passwd tr

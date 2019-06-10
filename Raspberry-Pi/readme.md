
# sd card write image after..

1. 고정 ip 설정
  - /boot/cmdline.txt 설정 추가
  - 문구: ip=192.168.29.171

2. ssh enable
  - /boot/ssh 파일생성
  - 확장자 없이 빈 파일로 만들것

3. WiFi, Bluetooth 비활성 설정
  - /boot/config.txt 설정 추가
```bash
# Disable WiFi and Bluetooth
dtoverlay=pi3-disable-wifi
dtoverlay=pi3-disable-bt
```

4. 설치후 
```bash
# package update
apt-get update && apt-get -y upgrade

# default package install
apt-get -y install vim rdate htop

# timezone change
cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# Time Sync
 rdate -s time.bora.net


# Unused Service disable

## - WiFi -
systemctl stop wpa_supplicant
systemctl disable wpa_supplicant

## - bluetooth -
systemctl stop bluetooth
systemctl disable bluetooth

## - hciuart -     // 블루투스 모뎀 구성 관련
systemctl stop hciuart.servie
systemctl disable hciuart.service


# Vim Config

[ -f "~/.vimrc" ] && mv ~/.vimrc ~/.vimrc_old

echo "set ic" >> ~/.vimrc
echo "set nu" >> ~/.vimrc
echo "set hlsearch" >> ~/.vimrc
echo "syntax off" >> ~/.vimrc

# /etc/crontab edit Time Server Sync

echo "" >> /etc/crontab
echo "# TimeServer Sync" >> /etc/crontab
echo " * 00,12 * * * /usr/bin/rdate -s time.bora.net" >> /etc/crontab

```






https://raspberrypicloud.wordpress.com/2013/03/12/building-an-lxc-friendly-kernel-for-the-raspberry-pi/

https://raspberrypicloud.wordpress.com/2013/03/12/creating-an-lxc-container-on-the-raspberry-pi/


# http://blog.kugelfish.com/2013/05/raspberry-pi-internet-access-monitor.html

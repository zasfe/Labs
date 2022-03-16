
# How to Install Single Node OpenStack on CentOS 7
## https://www.linuxtechi.com/single-node-openstack-liberty-installation-centos-7/

> * Hostname = openstack.gabia.local
> * IP Address = 10.17.10.172
> * OS = CentOS 7.x
> * DNS = 8.8.8.8


# Step:1 Update the nodes using below command.
echo 'net.ipv4.ip_forward=1 ' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_recycle=1 ' >>/etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse=1 ' >>/etc/sysctl.conf
sysctl -p

systemctl stop iptables.service
systemctl stop ip6tables.service
systemctl disable iptables.service
systemctl disable ip6tables.service

yum install -y mlocate lrzsz tree vim nc nmap wget bash-completion bash-completion-extras cowsay sl htop iotop iftop lsof net-tools sysstat unzip bc psmisc ntpdate wc telnet-server bind-utils sshpass
yum -y update ; reboot

# Step:2 Update /etc/hosts file and Hostname
hostnamectl set-hostname openstack
echo "10.17.10.172 openstack.gabia.local openstack" | sudo tee --append /etc/hosts


# Step:3 Disable SELinux and Network Manager on all three nodes.
setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config

systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network


# Step:4 Enable RDO repository and install packstack utility

yum -y install https://www.rdoproject.org/repos/rdo-release.rpm
yum -y install openstack-packstack


# Step:5 Generate and customize answer file
packstack --gen-answer-file=/root/answer.txt

sed -i s/^CONFIG_NTP_SERVERS=.*$/CONFIG_NTP_SERVERS=time\.windows\.com/ /root/answer.txt
sed -i s/^CONFIG_PROVISION_DEMO=.*$/CONFIG_PROVISION_DEMO=n/ /root/answer.txt
sed -i s/^CONFIG_KEYSTONE_ADMIN_PW=.*$/CONFIG_KEYSTONE_ADMIN_PW=gabia1234/ /root/answer.txt
sed -i s/^CONFIG_HORIZON_SSL=.*$/CONFIG_HORIZON_SSL=y/ /root/answer.txt
sed -i s/^CONFIG_NEUTRON_L2_AGENT=.*$/CONFIG_NEUTRON_L2_AGENT=openvswitch/ /root/answer.txt

> vi /root/answer.txt
> ........................................
> CONFIG_PROVISION_DEMO=n
> CONFIG_CEILOMETER_INSTALL=n
> CONFIG_HORIZON_SSL=y
> CONFIG_NTP_SERVERS=time.windows.com
> CONFIG_KEYSTONE_ADMIN_PW=gabia1234 <-- 오픈스택 패스워드
> ..........................................

# Step:6 Start Installation using packstack command.

packstack --answer-file=/root/answer.txt



# Step:7 Start Config Default Network

openstack network create provider --external --provider-network-type flat --provider-physical-network datacentre --share
openstack subnet create provider-subnet --network  provider --dhcp --allocation-pool start=10.9.101.50,end=10.9.101.100 --gateway 10.9.101.254 --subnet-range 10.9.101.0/24
openstack router create external
openstack router set --external-gateway provider external


# 문제 해결

## 이미지 추가할 때 URL 연결 옵션이 보이지 않는다.
https://jaturaprom.medium.com/how-to-url-upload-image-in-dashboard-horizon-on-openstack-ocata-318036093cfc




## 재부팅후 확인해야할 서비스

systemctl status memcached.service // 세션, 토큰
systemctl status rabbitmq-server.service // 메시지
systemctl status chronyd.service // 시간 서버

# 참고

* https://www.linuxtechi.com/single-node-openstack-liberty-installation-centos-7/
* https://zetawiki.com/wiki/Packstack%EC%9D%84_%EC%9D%B4%EC%9A%A9%ED%95%9C_openstack_%EC%84%A4%EC%B9%98



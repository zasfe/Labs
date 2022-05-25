######################################################## 
# controller node - 기본 구성
# - controller node: 
#   * OS: CentOS7.9 minimal
#   * App: 
#   * public nic(eno1): 10.17.10.173
#   * cummunity nic(eno2): 192.168.10.173
########################################################

echo "LANG=en_US.utf-8" | sudo tee --append /etc/environment
echo "LC_ALL=en_US.utf-8" | sudo tee --append /etc/environment
echo "IP_controller_public=10.17.10.173" | sudo tee --append /etc/environment
echo "IP_public_devname=eno1" | sudo tee --append /etc/environment
echo "IP_controller_internal=192.168.10.173" | sudo tee --append /etc/environment
echo "IP_internal_devname=eno2" | sudo tee --append /etc/environment
echo "HOST_controller=controller" | sudo tee --append /etc/environment

echo 'root hard nofile 65535' >> /etc/security/limits.conf
echo 'root soft nofile 65535' >> /etc/security/limits.conf

echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf  
echo 'net.ipv4.tcp_tw_recycle=1' >>/etc/sysctl.conf  
echo 'net.ipv4.tcp_tw_reuse=1' >>/etc/sysctl.conf  
echo 'fs.file-max = 10240' >>/etc/sysctl.conf  
echo 'vm.vfs_cache_pressure = 10000' >>/etc/sysctl.conf  
echo 'vm.swappiness = 0' >>/etc/sysctl.conf  
sysctl -p  

setenforce 0  
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config  
  

systemctl stop firewalld.service
systemctl stop iptables.service  
systemctl stop ip6tables.service  
systemctl disable firewalld.service
systemctl disable iptables.service  
systemctl disable ip6tables.service  

systemctl disable firewalld  
systemctl stop firewalld  
systemctl disable NetworkManager  
systemctl disable NetworkManager  
systemctl disable NetworkManager  
systemctl disable NetworkManager  
systemctl disable NetworkManager  
systemctl stop NetworkManager  
systemctl enable network  
systemctl start network  



yum -y install mlocate lrzsz tree vim nc nmap wget bash-completion bash-completion-extras cowsay sl htop iotop iftop lsof net-tools sysstat unzip bc psmisc ntpdate wc telnet-server bind-utils sshpass  
yum -y update

hostnamectl set-hostname controller  
echo "$IP_controller_internal controller controller.gabia.local" | sudo tee --append /etc/hosts  
reboot  


######################################################## 
# controller node - 오픈스택 기본 패키지 설치
# - controller node: 
#   * App: 
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################


yum -y install centos-release-openstack-stein 
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-OpenStack-stein.repo 

yum --enablerepo=centos-openstack-stein -y install mariadb-server

sed -i 's/\[mysqld\]/\[mysqld\]\ncharacter-set-server=utf8/' /etc/my.cnf

systemctl start mariadb 
systemctl enable mariadb

# mysql_secure_installation 

yum --enablerepo=centos-openstack-stein -y install rabbitmq-server memcached python-memcached

sed -i 's/\[mysqld\]/\[mysqld\]\ncharacter-set-server=utf8\nmax_connections=500/' /etc/my.cnf.d/mariadb-server.cnf

cat <<EOF > /etc/sysconfig/memcached
PORT="11211"
USER="memcached"
# max connection 2048
MAXCONN="2048"
# set ram size to 2048 - 2GiB
CACHESIZE="4096"
OPTIONS="-l 0.0.0.0"
EOF

systemctl restart mariadb rabbitmq-server memcached 
systemctl enable mariadb rabbitmq-server memcached 

rabbitmqctl add_user openstack password 
rabbitmqctl set_permissions openstack ".*" ".*" ".*" 


######################################################## 
# controller node - 인증 서비스 (Keystone) 설치 및 구성  
# - controller node: 
#   * App: mariadb-server, rabbitmq-server memcached
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################

cat <<EOF > /root/keystone_mysql_query.sql
create database keystone; 
grant all privileges on keystone.* to keystone@'localhost' identified by 'password'; 
grant all privileges on keystone.* to keystone@'%' identified by 'password'; 
flush privileges; 
EOF
mysql -u root < /root/keystone_mysql_query.sql
mysql -u root -e "show databases like 'keystone%'"

yum --enablerepo=centos-openstack-stein,epel -y install openstack-keystone openstack-utils python-openstackclient httpd mod_wsgi


cp -pa /etc/keystone/keystone.conf /root/keystone.conf.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/keystone/keystone.conf
[DEFAULT]
[access_rules_config]
[application_credential]
[assignment]
[auth]
[cache]
memcache_servers = $IP_controller_internal:11211
[catalog]
[cors]
[credential]
[database]
connection = mysql+pymysql://keystone:password@$IP_controller_internal/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[federation]
[fernet_receipts]
[fernet_tokens]
[healthcheck]
[identity]
[identity_mapping]
[jwt_tokens]
[ldap]
[memcache]
[oauth1]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[policy]
[profiler]
[receipt]
[resource]
[revoke]
[role]
[saml]
[security_compliance]
[shadow_users]
[signing]
[token]
provider = fernet
[tokenless_auth]
[trust]
[unified_limit]
[wsgi]
EOF

su -s /bin/bash keystone -c "keystone-manage db_sync"

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password adminpassword \
  --bootstrap-admin-url http://$IP_controller_internal:5000/v3/ \
  --bootstrap-internal-url http://$IP_controller_internal:5000/v3/ \
  --bootstrap-public-url http://$IP_controller_internal:5000/v3/ \
  --bootstrap-region-id RegionOn

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/ 
systemctl restart httpd 
systemctl enable httpd 


cat <<EOF > ~/admin
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=adminpassword
export OS_AUTH_URL=http://$IP_controller_internal:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

chmod 600 ~/admin 
source ~/admin 

. admin
openstack project create --domain default --description "Service Project" service 
openstack project list 

######################################################## 
# controller node - 이미지 서비스 (Glance) 설치 및 구성
# - controller node: keystone
#   * App: mariadb-server, rabbitmq-server memcached
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################


# 사용자로서 glance를 추가합니다. servicepassword 부분은 본인이 원하는 패스워드로 변경.
openstack user create --domain default --project service --password servicepassword glance 

# 방금 추가한 사용자 glance에 관리자(admin)역할을 부여합니다.s
openstack role add --project service --user glance admin

# 사용자 glance를 서비스 엔트리에 저장합니다.
openstack service create --name glance --description "OpenStack Image service" image 

# glance 서비스의 endpoint를 추가합니다. (public)
openstack endpoint create --region RegionOne image public http://$IP_controller_internal:9292 

# glance 서비스의 endpoint를 추가합니다. (internal)
openstack endpoint create --region RegionOne image internal http://$IP_controller_internal:9292 

# glance 서비스의 endpoint를 추가합니다. (admin)
openstack endpoint create --region RegionOne image admin http://$IP_controller_internal:9292 

openstack service list
openstack endpoint list --region RegionOne --service image



cat <<EOF > /root/glance_mysql_query.sql
create database glance; 
grant all privileges on glance.* to glance@'localhost' identified by 'password'; 
grant all privileges on glance.* to glance@'%' identified by 'password';
flush privileges; 
EOF
mysql -u root < /root/glance_mysql_query.sql
mysql -u root -e "show databases like 'glance%'"



# Stein 레포지토리로부터 glance 서비스를 설치합니다.
yum --enablerepo=centos-openstack-stein,epel -y install openstack-glance

cp -pa /etc/glance/glance-api.conf /etc/glance/glance-api.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/glance/glance-api.conf
[DEFAULT]
bind_host = 0.0.0.0

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[database]
connection = mysql+pymysql://glance:password@$IP_controller_internal/glance

[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = servicepassword

[paste_deploy]
flavor = keystone
EOF

# 서비스를 재시작 합니다.
su -s /bin/bash glance -c "glance-manage db_sync" 
systemctl restart openstack-glance-api 
systemctl enable openstack-glance-api 

. admin

wget http://mirror.kakao.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
openstack image create "CentOS7.9(Minimal)" --file CentOS-7-x86_64-Minimal-2009.iso --disk-format iso
openstack image list



######################################################## 
# controller node - 컴퓨트 서비스 (Nova) 설치 및 구성  
# - controller node: keystone, glance
#   * App: mariadb-server, rabbitmq-server memcached
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################

# 사용자로서 nova를 추가합니다. servicepassword 부분은 본인이 원하는 패스워드로 변경.
openstack user create --domain default --project service --password servicepassword nova 

# 방금 추가한 사용자 nova에 관리자(admin)역할을 부여합니다.
openstack role add --project service --user nova admin

# 사용자 nova를 서비스 엔트리에 저장합니다.
openstack service create --name nova --description "OpenStack Compute service" compute 

# nova 서비스의 endpoint를 추가합니다. (public)
openstack endpoint create --region RegionOne compute public http://$IP_controller_internal:8774/v2.1/%\(tenant_id\)s 

# nova 서비스의 endpoint를 추가합니다. (internal)
openstack endpoint create --region RegionOne compute internal http://$IP_controller_internal:8774/v2.1/%\(tenant_id\)s 

# nova 서비스의 endpoint를 추가합니다. (admin)
openstack endpoint create --region RegionOne compute admin http://$IP_controller_internal:8774/v2.1/%\(tenant_id\)s 

openstack service list
openstack endpoint list --region RegionOne --service compute


# 사용자로서 placement를 추가합니다. servicepassword 부분은 본인이 원하는 패스워드로 변경.
openstack user create --domain default --project service --password servicepassword placement 

# 방금 추가한 사용자 placement에 관리자(admin)역할을 부여합니다.
openstack role add --project service --user placement admin

# 사용자 placement를 서비스 엔트리에 저장합니다.
openstack service create --name placement --description "OpenStack Compute Placement service" placement 

# placement 서비스의 endpoint를 추가합니다. (public)
openstack endpoint create --region RegionOne placement public http://$IP_controller_internal:8778 

# placement 서비스의 endpoint를 추가합니다. (internal)
openstack endpoint create --region RegionOne placement internal http://$IP_controller_internal:8778 

# placement 서비스의 endpoint를 추가합니다. (admin)
openstack endpoint create --region RegionOne placement admin http://$IP_controller_internal:8778 

openstack service list
openstack endpoint list --region RegionOne --service placement



cat <<EOF > /root/nova_mysql_query.sql
create database nova; 
grant all privileges on nova.* to nova@'localhost' identified by 'password'; 
grant all privileges on nova.* to nova@'%' identified by 'password';

create database nova_api; 
grant all privileges on nova_api.* to nova@'localhost' identified by 'password'; 
grant all privileges on nova_api.* to nova@'%' identified by 'password';

create database nova_placement; 
grant all privileges on nova_placement.* to nova@'localhost' identified by 'password'; 
grant all privileges on nova_placement.* to nova@'%' identified by 'password'; 

create database nova_cell0; 
grant all privileges on nova_cell0.* to nova@'localhost' identified by 'password'; 
grant all privileges on nova_cell0.* to nova@'%' identified by 'password'; 

flush privileges; 
EOF
mysql -u root < /root/nova_mysql_query.sql
mysql -u root -e "show databases like 'nova_%'"



//서비스 설치
yum --enablerepo=centos-openstack-stein,epel -y install openstack-nova

cp -pa /etc/nova/nova.conf /etc/nova/nova.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF >/etc/nova/nova.conf
[DEFAULT]
# 본인의 현재 컨트롤러 노드의 통신용 ip로 입력
my_ip = $IP_controller_internal
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova

# 자신의 rabbitmq 관련 정보를 입력합니다 (ip, password 변경)
transport_url = rabbit://openstack:password@$IP_controller_internal

[api]
auth_strategy = keystone

# glance 서비스의 서버 ip로 대체합니다.
[glance]
api_servers = http://$IP_controller_internal:9292

[oslo_concurrency]
lock_path = $state_path/tmp

# 방금 생성한 nova db 정보입니다. password와 ip에 본인의 구성에 맞게 변경합니다.
[api_database]
connection = mysql+pymysql://nova:password@$IP_controller_internal/nova_api

[database]
connection = mysql+pymysql://nova:password@$IP_controller_internal/nova

# Keystone 인증 정보입니다. 
# 아래 ip들을 keystone이 세팅된 현재 컨트롤러 노드의 통신용 포트의 ip로 바꾸고 password 부분을 본인의 패스워드로 변경합니다.
[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = servicepassword

# nova placement 정보입니다. 
# ip와 password 부분을 본인의 정보로 변경합니다.
[placement]
auth_url = http://$IP_controller_internal:5000
os_region_name = RegionOne
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = servicepassword

# nova placement db정보입니다. 
# ip와 password 부분을 본인의 정보로 변경합니다.
[placement_database]
connection = mysql+pymysql://nova:password@$IP_controller_internal/nova_placement

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF

su -s /bin/bash nova -c "nova-manage api_db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0"
su -s /bin/bash nova -c "nova-manage db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"

systemctl restart httpd 
chown nova. /var/log/nova/nova-placement-api.log
for service in api consoleauth conductor scheduler novncproxy; do
systemctl restart openstack-nova-$service
systemctl enable openstack-nova-$service
done

######################################################## 
# controller node - 컴퓨트 서비스 (Nova) 설치 및 구성 (2)
# - controller node: keystone, glance
#   * App: mariadb-server, rabbitmq-server memcached
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################


yum -y install qemu-kvm libvirt virt-install bridge-utils
systemctl start libvirtd 
systemctl enable libvirtd 

cat <<EOF >> /etc/nova/nova.conf

# VNC 화면을 활성화 합니다. 추후 오픈스택 대시보드 혹은 vnc 클라이언트 프로그램으로 접속할 때 사용됩니다.
# 이때 만약 외부에서 통신망이 아닌 관리망으로 접속해서 vnc를 봐야 하는 경우, 아래와 같이 컴퓨트노드의 관리용 ip로 지정해 줍니다.
[vnc]
enabled = True
server_listen = 0.0.0.0
server_proxyclient_address = $IP_controller_public
novncproxy_base_url = http://$IP_controller_public:6080/vnc_auto.html 
EOF

chmod 640 /etc/nova/nova.conf 
chgrp nova /etc/nova/nova.conf 

systemctl restart openstack-nova-compute 
systemctl enable openstack-nova-compute 

. admin
openstack compute service list
nova hypervisor-list


ls -al /var/log/nova/*

######################################################## 
# controller node - 네트워크 서비스 (Neutron) 설치 및 구성
# - controller node: keystone, glance, nova
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm libvirt virt-install bridge-utils
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################

# 사용자로서 neutron을 추가합니다. servicepassword 부분은 본인이 원하는 패스워드로 변경.
openstack user create --domain default --project service --password servicepassword neutron 

# 방금 추가한 사용자 neutron에 관리자(admin)역할을 부여합니다.
openstack role add --project service --user neutron admin

# 사용자 neutron을 서비스 엔트리에 저장합니다.
openstack service create --name neutron --description "OpenStack Networking service" network 

# neutron 서비스의 endpoint를 추가합니다. (public)
openstack endpoint create --region RegionOne network public http://$IP_controller_internal:9696 

# neutron 서비스의 endpoint를 추가합니다. (internal)
openstack endpoint create --region RegionOne network internal http://$IP_controller_internal:9696 

# neutron 서비스의 endpoint를 추가합니다. (admin)
openstack endpoint create --region RegionOne network admin http://$IP_controller_internal:9696 

cat <<EOF > /root/neutron_mysql_query.sql
create database neutron_ml2; 
grant all privileges on neutron_ml2.* to neutron@'localhost' identified by 'password'; 
grant all privileges on neutron_ml2.* to neutron@'%' identified by 'password'; 
flush privileges; 
EOF
mysql -u root < /root/neutron_mysql_query.sql
mysql -u root -e "show databases like 'neutron_ml2'"

yum --enablerepo=centos-openstack-stein,epel -y install openstack-neutron openstack-neutron-ml2

cp -pa /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/neutron.conf
[DEFAULT]
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
state_path = /var/lib/neutron
dhcp_agent_notification = True
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

# 자신의 rabbitmq 관련 정보를 입력합니다 (ip, password 변경)
transport_url = rabbit://openstack:password@$IP_controller_internal

# Keystone 인증 정보입니다. 
# 아래 ip들을 keystone이 세팅된 현재 컨트롤러 노드의 통신용 포트의 ip로 바꾸고 password 부분을 본인의 패스워드로 변경합니다.
[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = servicepassword

# 방금 생성한 neutron db 정보입니다. password와 ip에 본인의 구성에 맞게 변경합니다.
[database]
connection = mysql+pymysql://neutron:password@$IP_controller_internal/neutron_ml2

# nova 서비스 정보입니다. 
# ip와 password 부분을 본인의 정보로 변경합니다.
[nova]
auth_url = http://$IP_controller_internal:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = servicepassword

[oslo_concurrency]
lock_path = $state_path/tmp
EOF

chmod 640 /etc/neutron/neutron.conf 
chgrp neutron /etc/neutron/neutron.conf 



cp -pa /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
# 아래 정보를 추가합니다.

# Nova API 서버 정보를 명시합니다.
nova_metadata_host = $IP_controller_internal

# 메타데이터 프록시에 대한 암호를 metadata_secret으로 지정합니다.
metadata_proxy_shared_secret = metadata_secret

# 아래 옵션의 주석을 해제하고 memcache 서버가 설치된 컨트롤러 노드의 주소로 변경합니다.
memcache_servers = $IP_controller_internal:11211
EOF

cp -pa /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[DEFAULT]
[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types =
mechanism_drivers = openvswitch
extension_drivers = port_security
EOF

cp -pa /etc/nova/nova.conf /etc/nova/nova.conf.org.$(date +%G%m%d_%H%M%S)
sed -i 's/\[DEFAULT\]/\[DEFAULT\]\nuse_neutron = True\nlinuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver\nfirewall_driver = nova.virt.firewall.NoopFirewallDriver/' /etc/nova/nova.conf

cat <<EOF >> /etc/nova/nova.conf

[neutron]
auth_url = http://$IP_controller_internal:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = servicepassword
service_metadata_proxy = True
metadata_proxy_shared_secret = metadata_secret
EOF

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/bash neutron -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head" 
systemctl restart neutron-server neutron-metadata-agent 
systemctl enable neutron-server neutron-metadata-agent 
systemctl restart openstack-nova-api

######################################################## 
# controller node - 네트워크 서비스 (Neutron) 설치 및 구성 (2)
# - controller node: keystone, glance, nova, Neutron
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm libvirt virt-install bridge-utils
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################



yum --enablerepo=centos-openstack-stein,epel -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch libibverbs

cp -pa /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = openvswitch
EOF

cp -pa /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

cp -pa /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]
[securitygroup]
firewall_driver = openvswitch
enable_security_group = true
enable_ipset = true
EOF

systemctl start openvswitch 
systemctl enable openvswitch 
ovs-vsctl add-br br-int 
for service in dhcp-agent l3-agent metadata-agent openvswitch-agent; do
systemctl restart neutron-$service
systemctl enable neutron-$service
done 

######################################################## 
# controller node - 네트워크 서비스 (Neutron) 설치 및 구성 (3)
# - controller node: keystone, glance, nova, Neutron
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################

sed -i 's/\[DEFAULT\]/\[DEFAULT\]\nvif_plugging_is_fatal = True\nvif_plugging_timeout = 300/' /etc/nova/nova.conf

systemctl restart openstack-nova-compute 
systemctl restart neutron-openvswitch-agent 
systemctl enable neutron-openvswitch-agent

######################################################## 
# controller node - 테넌트 네트워크 환경 구축
# - controller node: keystone, glance, nova, Neutron
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch
#   * public nic: 10.17.10.173
#   * cummunity nic: 192.168.10.173
########################################################

sed -i 's/^tenant_network_types =.*/tenant_network_types = vxlan/' /etc/neutron/plugins/ml2/ml2_conf.ini

cp -pa /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF >> /etc/neutron/plugins/ml2/ml2_conf.ini

[ml2_type_flat]
flat_networks = physnet1

[ml2_type_vxlan]
vni_ranges = 1:1000
EOF

cp -ap /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.org.$(date +%G%m%d_%H%M%S)
cat <<EOF >> /etc/neutron/plugins/ml2/openvswitch_agent.ini

[agent]
tunnel_types = vxlan
prevent_arp_spoofing = True

[ovs]
# ip는 현재 노드인 네트워크 노드의 ip로 지정합니다.
local_ip = $IP_controller_internal
bridge_mappings = physnet1:br-eth1
EOF

for service in dhcp-agent l3-agent metadata-agent openvswitch-agent; do
systemctl restart neutron-$service
done

systemctl restart neutron-server
ovs-vsctl add-br br-eth1 

echo 'OVS_BRIDGE=br-eth1' | sudo tee --append /etc/sysconfig/network-scripts/ifcfg-eno1

sed -i 's/TYPE=.*/TYPE=OVSPort/' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i 's/BOOTPROTO=.*/BOOTPROTO=none/' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i 's/DEVICETYPE=.*/DEVICETYPE=ovs/' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i 's/DEFROUTE=.*/DEFROUTE=no/' /etc/sysconfig/network-scripts/ifcfg-eno1

sed -i '/IPADDR=.*/d' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i '/GATEWAY=.*/d' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i '/NETMASK=.*/d' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i '/DNS1=.*/d' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i '/DNS2=.*/d' /etc/sysconfig/network-scripts/ifcfg-eno1

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-br-eth1
TYPE=OVSBridge
BOOTPROTO=none
DEFROUTE=yes
DEVICE=br-eth1
DEVICETYPE=ovs
ONBOOT=yes
IPADDR=$IP_controller_public
PREFIX=24 
GATEWAY=10.17.10.1
DNS1=8.8.8.8 
EOF

systemctl restart network.service
ovs-vsctl show

######################################################## 
# controller node - 대시보드 서비스(Horizon) 구축 및 대시보드 기본 구조
# - controller node: keystone, glance, nova, Neutron
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch
#   * public nic: 
#   * cummunity nic: 192.168.10.173
#   * ifcfg-br-eth1 nic: 10.17.10.173
########################################################

yum --enablerepo=centos-openstack-stein,epel -y install openstack-dashboard

/etc/openstack-dashboard/local_settings

cp -pa /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.org.$(date +%G%m%d_%H%M%S)

# 아래와 같이 대시보드에 접속할 때 사용할 호스트 명을 지정해줄 수 있습니다.
sed -i "s/ALLOWED_HOSTS =.*/ALLOWED_HOSTS = \['\*'\]/" /etc/openstack-dashboard/local_settings 

# OPENSTACK_API_VERSIONS의 volume 값을 3으로 지정합니다.
sed -i 's/^#OPENSTACK_API_VERSIONS = {/OPENSTACK_API_VERSIONS = {\n    "identity": 3,\n    "volume": 3,\n    "compute": 2,\n}\n# OPENSTACK_API_VERSIONS = {/' /etc/openstack-dashboard/local_settings

# 아래 옵션의 주석을 풀고 True로 변경합니다.
sed -i "s/^#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = .*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/" /etc/openstack-dashboard/local_settings

# 아래 옵션의 주석을 해제합니다.
sed -i "s/^#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = .*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/" /etc/openstack-dashboard/local_settings
sed -i "s/^OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = .*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/" /etc/openstack-dashboard/local_settings

# 아래 옵션에서 LOCATION의 주석을 풀고 127.0.0.1(컨트롤러 노드 자신)로 변경합니다.
sed -i "s/^#CACHES = {/CACHES = {\n    'default': {\n        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',\n        'LOCATION': '127.0.0.1:11211',\n    },\n}\n\n# CACHES = {/" /etc/openstack-dashboard/local_settings

sed -i "s/^#SESSION_ENGINE =.*/SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/" /etc/openstack-dashboard/local_settings
sed -i "s/^SESSION_ENGINE =.*/SESSION_ENGINE = 'django.contrib.sessions.backends.cache'/" /etc/openstack-dashboard/local_settings


# 아래와 같이 OPENSTACK_HOST의 주소를 컨트롤러 노드의 ip로 변경합니다.
sed -i "s/^OPENSTACK_HOST = .*/OPENSTACK_HOST = \"$IP_controller_internal\"/" /etc/openstack-dashboard/local_settings

# 아래 옵션을 통해 기본 역할을 member로 설정합니다.
sed -i "s/^OPENSTACK_KEYSTONE_DEFAULT_ROLE = .*/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"member\"/" /etc/openstack-dashboard/local_settings

cp -pa /etc/httpd/conf.d/openstack-dashboard.conf /etc/httpd/conf.d/openstack-dashboard.conf.org.$(date +%G%m%d_%H%M%S)

sed -i '/WSGIApplicationGroup .*/d' /etc/httpd/conf.d/openstack-dashboard.conf
sed -i 's/WSGISocketPrefix run\/wsgi/WSGISocketPrefix run\/wsgi\nWSGIApplicationGroup \%\{GLOBAL\}/' /etc/httpd/conf.d/openstack-dashboard.conf

systemctl restart memcached.service
systemctl restart httpd.service


######################################################## 
# controller node - 블록 스토리지 (Cinder) 서비스 구성
# - controller node: keystone, glance, nova, Neutron, Horizon
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch
#   * public nic: 
#   * cummunity nic: 192.168.10.173
#   * ifcfg-br-eth1 nic: 10.17.10.173
########################################################

. admin

# 사용자로서 cinder 추가합니다. servicepassword 부분은 본인이 원하는 패스워드로 변경.
openstack user create --domain default --project service --password servicepassword cinder 

# 방금 추가한 사용자 cinder에 관리자(admin)역할을 부여합니다.
openstack role add --project service --user cinder admin

# 사용자 cinderv3를 서비스 엔트리에 저장합니다.
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3 
openstack service show cinderv3    

# keystone의 호스트(즉 컨트롤러 노드의 통신용ip)를 환경변수로 지정합니다.
# cinderv3 서비스의 endpoint를 추가합니다. (public)
openstack endpoint create --region RegionOne volumev3 public http://$IP_controller_internal:8776/v3/%\(tenant_id\)s 

# cinderv3 서비스의 endpoint를 추가합니다. (internal)
openstack endpoint create --region RegionOne volumev3 internal http://$IP_controller_internal:8776/v3/%\(tenant_id\)s 

# cinderv3 서비스의 endpoint를 추가합니다. (admin)
openstack endpoint create --region RegionOne volumev3 admin http://$IP_controller_internal:8776/v3/%\(tenant_id\)s 



cat <<EOF > /root/cinder_mysql_query.sql
create database cinder; 
grant all privileges on cinder.* to cinder@'localhost' identified by 'password'; 
grant all privileges on cinder.* to cinder@'%' identified by 'password'; 
flush privileges; 
EOF
mysql -u root < /root/cinder_mysql_query.sql
mysql -u root -e "show databases like 'cinder'"

# install from Stein, EPEL
yum --enablerepo=centos-openstack-stein,epel -y install openstack-cinder python2-crypto targetcli

cp -pa /etc/cinder/cinder.conf /etc/cinder/cinder.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = $IP_controller_internal
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone

# 자신의 rabbitmq 관련 정보를 입력합니다 (ip, password 변경)
transport_url = rabbit://openstack:password@$IP_controller_internal

# Glance 서비스 연결 정보를 입력합니다.
glance_api_servers = http://$IP_controller_internal:9292
enable_v3_api = True

[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]

# cinder db 정보입니다. password와 ip에 본인의 구성에 맞게 변경합니다.
[database]
connection = mysql+pymysql://cinder:password@$IP_controller_internal/cinder

[fc-zone-manager]
[healthcheck]
[key_manager]

# Keystone 인증 정보입니다. 
[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = servicepassword
[nova]
[oslo_concurrency]
lock_path = $state_path/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[oslo_versionedobjects]
[privsep]
[profiler]
[sample_castellan_source]
[sample_remote_file_source]
[service_user]
[ssl]
[vault]
EOF





chmod 640 /etc/cinder/cinder.conf 
chgrp cinder /etc/cinder/cinder.conf 

su -s /bin/bash cinder -c "cinder-manage db sync" 

systemctl restart openstack-cinder-api openstack-cinder-scheduler 
systemctl enable openstack-cinder-api openstack-cinder-scheduler 

# systemctl status openstack-cinder-api openstack-cinder-scheduler

echo "export OS_VOLUME_API_VERSION=3" >> admin
. admin

openstack volume service list


######################################################## 
# controller node - LVM으로 블록 스토리지 백엔드 구성하기
# - controller node: keystone, glance, nova, Neutron, Horizon, cinder
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch, python2-crypto targetcli
#   * public nic: 
#   * cummunity nic: 192.168.10.173
#   * ifcfg-br-eth1 nic: 10.17.10.173
########################################################

yum --enablerepo=centos-openstack-stein -y install lvm2 device-mapper-persistent-data

systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

# [root@controller ~]# lsblk
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda      8:0    0 447.1G  0 disk
# ├─sda1   8:1    0     1G  0 part /boot
# ├─sda2   8:2    0  15.7G  0 part [SWAP]
# └─sda3   8:3    0 430.4G  0 part /
# sdb      8:16   0 894.2G  0 disk
# ├─sdb1   8:17   0     1G  0 part
# └─sdb2   8:18   0 893.2G  0 part
# sr0     11:0    1  1024M  0 rom
# [root@controller ~]#

parted -s -a optimal -- /dev/sdb mklabel gpt
parted -s -a optimal -- /dev/sdb mkpart primary 0% 70%
parted -s -a optimal -- /dev/sdb mkpart primary 70% 100%

# vgcreate name 과 /etc/cinder/cinder.conf에서 [lvm].volume_group 이 같아야 합니다.
pvcreate /dev/sdb1
vgcreate cinder-volumes /dev/sdb1
lvcreate -l 100%FREE -T cinder-volumes/cinder-volumes-pool
mkfs.xfs /dev/sdb2

cp -pa /etc/lvm/lvm.conf /etc/lvm/lvm.conf.org.$(date +%G%m%d_%H%M%S)

sed -i 's/# Configuration option devices\/global_filter\./filter = \[ "a\/sdb\/", "r\/\.\*\/"\]\n\n        # Configuration option devices\/global_filter\./' /etc/lvm/lvm.conf


cp -pa /etc/cinder/cinder.conf /etc/cinder/cinder.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = $IP_controller_internal
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone

# 자신의 rabbitmq 관련 정보를 입력합니다 (ip, password 변경)
transport_url = rabbit://openstack:password@$IP_controller_internal

# Glance 서비스 연결 정보를 입력합니다.
glance_api_servers = http://$IP_controller_internal:9292
enable_v3_api = True

enabled_backends = lvm

[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]

# cinder db 정보입니다. password와 ip에 본인의 구성에 맞게 변경합니다.
[database]
connection = mysql+pymysql://cinder:password@$IP_controller_internal/cinder

[fc-zone-manager]
[healthcheck]
[key_manager]

# Keystone 인증 정보입니다. 
[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = servicepassword
[nova]
[oslo_concurrency]
lock_path = $state_path/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[oslo_versionedobjects]
[privsep]
[profiler]
[sample_castellan_source]
[sample_remote_file_source]
[service_user]
[ssl]
[vault]

[lvm]
target_helper = lioadm
target_protocol = iscsi

# 스토리지 노드의 IP
target_ip_address = $IP_controller_internal

# 현재 스토리지 노드에서 사용할 LVM 볼륨 그룹 명
volume_group = cinder-volumes 
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volumes_dir = $state_path/volumes
EOF

su -s /bin/bash cinder -c "cinder-manage db sync" 

systemctl restart openstack-cinder-volume


cp -pa /etc/nova/nova.conf /etc/nova/nova.conf.org.$(date +%G%m%d_%H%M%S)

cat <<EOF >> /etc/nova/nova.conf

[cinder]
os_region_name = RegionOne
EOF

systemctl restart openstack-nova-compute 

systemctl restart httpd

. admin
openstack volume service list

######################################################## 
# controller node - NFS,LVM 기반 다중 블록 스토리지 노드 구성하기
# - controller node: keystone, glance, nova, Neutron, Horizon, cinder
#   * App: mariadb-server, rabbitmq-server memcached, qemu-kvm, libvirt, virt-install, bridge-utils, openvswitch, python2-crypto targetcli
#   * public nic: 
#   * cummunity nic: 192.168.10.173
#   * ifcfg-br-eth1 nic: 10.17.10.173
########################################################

yum --enablerepo=centos-openstack-stein -y install nfs-utils

mkdir /nfs

echo "/nfs *(rw,no_root_squash)" >  /etc/exports

# nfs 디렉토리 주요 접근 권한 리스트
# * ro: 마운트 된 볼륨의 데이터를 읽기만 가능
# * rw: 마운트 된 볼륨에 쓰기도 가능
# * no_root_squash: 루트 자격이 있어야 쓰기 가능
# * noaccess: 디렉토리 접근 불가

systemctl restart rpcbind nfs-server
systemctl enable rpcbind nfs-server


exportfs -ra
showmount -e
exportfs -v



cp -pa /etc/cinder/cinder.conf /etc/cinder/cinder.conf.org.$(date +%G%m%d_%H%M%S)
cat <<EOF > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = $IP_controller_internal
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone

# 자신의 rabbitmq 관련 정보를 입력합니다 (ip, password 변경)
transport_url = rabbit://openstack:password@$IP_controller_internal

# Glance 서비스 연결 정보를 입력합니다.
glance_api_servers = http://$IP_controller_internal:9292
enable_v3_api = True

enabled_backends = lvm,nfs

[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]

# cinder db 정보입니다. password와 ip에 본인의 구성에 맞게 변경합니다.
[database]
connection = mysql+pymysql://cinder:password@$IP_controller_internal/cinder

[fc-zone-manager]
[healthcheck]
[key_manager]

# Keystone 인증 정보입니다. 
[keystone_authtoken]
www_authenticate_uri = http://$IP_controller_internal:5000
auth_url = http://$IP_controller_internal:5000
memcached_servers = $IP_controller_internal:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = servicepassword
[nova]
[oslo_concurrency]
lock_path = $state_path/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[oslo_versionedobjects]
[privsep]
[profiler]
[sample_castellan_source]
[sample_remote_file_source]
[service_user]
[ssl]
[vault]

[lvm]
target_helper = lioadm
target_protocol = iscsi

# 스토리지 노드의 IP
target_ip_address = $IP_controller_internal

# 현재 스토리지 노드에서 사용할 LVM 볼륨 그룹 명
volume_group = cinder-volumes 
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volumes_dir = $state_path/volumes

[nfs]
volume_driver = cinder.volume.drivers.nfs.NfsDriver
volume_backend_name = NFS
nfs_shares_config = /etc/cinder/nfs_shares
nfs_mount_point_base = $state_path/mnt_nfs
EOF

echo "$IP_controller_internal:/nfs" > /etc/cinder/nfs_shares
chmod 640 /etc/cinder/nfs_shares
chgrp cinder /etc/cinder/nfs_shares 

mkdir /var/lib/cinder/mnt_nfs
chown -R cinder. /var/lib/cinder/mnt_nfs

systemctl restart openstack-cinder-volume


. admin
openstack volume service list



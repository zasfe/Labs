
# Multi Node OpenStack(stein) Installation on CentOS 7 

> Controller Node Details
> * Hostname = controller.zasfe.local
> * IP Address = 192.168.137.11
> * OS = CentOS 7.x
> * DNS = 8.8.8.8
> * OpenStack Components
>    - Keystone
>    - Glance
>    - swift
>    - Cinder
>    - Horizon
>    - Neutron
>    - Nova novncproxy
>    - Novnc
>    - Nova api
>    - Nova Scheduler
>    - Nova-conductor
>    - Neutron Server
>    - Neturon DHCP agent
>    - Neutron- Openswitch agent
>    - Neutron L3 agent

> Compute Node Details
> * Hostname = compute1.zasfe.local
> * IP Address = 192.168.137.31
> * OS = CentOS 7.x
> * DNS = 8.8.8.8
> * OpenStack Components
>    - Nova Compute
>    - Neutron – Openvswitch Agent

> block1 Node Details
> * Hostname = block1.zasfe.local
> * IP Address = 192.168.137.41
> * OS = CentOS 7.x
> * DNS = 8.8.8.8
> * OpenStack Components





# Step:0 OS Install
## CentOS7.10 Minimal iso


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


hostnamectl set-hostname controller  
echo "192.168.137.11 controller.zasfe.local controller" | sudo tee --append /etc/hosts  
echo "192.168.137.31 compute1.zasfe.local    compute1" | sudo tee --append /etc/hosts  
echo "192.168.137.41 block1.zasfe.local    block1" | sudo tee --append /etc/hosts  
  
hostnamectl set-hostname compute1  
echo "192.168.137.11 controller.zasfe.local controller" | sudo tee --append /etc/hosts  
echo "192.168.137.31 compute1.zasfe.local    compute1" | sudo tee --append /etc/hosts  
echo "192.168.137.41 block1.zasfe.local    block1" | sudo tee --append /etc/hosts  
  
hostnamectl set-hostname block1  
echo "192.168.137.11 controller.zasfe.local controller" | sudo tee --append /etc/hosts  
echo "192.168.137.31 compute1.zasfe.local    compute1" | sudo tee --append /etc/hosts  
echo "192.168.137.41 block1.zasfe.local    block1" | sudo tee --append /etc/hosts  



# Step:3 Disable SELinux and Network Manager on all three nodes.

setenforce 0  
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config  
  
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


# Step:4 Set Passwordless authentication from Controller node to Compute & Network Node.


ssh-keygen  
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@192.168.137.11  
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@192.168.137.31  
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@192.168.137.41  



# Step:5 Set Environment - NTP


yum install chrony -y  
sed -i 's/^server/#server/g' /etc/chrony.conf  
echo "server 2.kr.pool.ntp.org iburst" | sudo tee --append /etc/chrony.conf  
echo "server 1.asia.pool.ntp.org iburst" | sudo tee --append /etc/chrony.conf  
echo "server 3.asia.pool.ntp.org iburst" | sudo tee --append /etc/chrony.conf  
echo "allow 192.168.137.0/24" | sudo tee --append /etc/chrony.conf  
  
systemctl restart chronyd  
systemctl enable chronyd  
systemctl status chronyd  
chronyc sources  
  
ssh compute1  
compute1# yum install chrony -y  
compute1# sed -i 's/^server/#server/g' /etc/chrony.conf  
compute1# echo "server controller iburst" | sudo tee --append /etc/chrony.conf  
compute1# systemctl enable chronyd  
compute1# systemctl restart chronyd  
compute1# systemctl status chronyd  
compute1# chronyc sources  
compute1# exit  

ssh block1  
block1# yum install chrony -y  
block1# sed -i 's/^server/#server/g' /etc/chrony.conf  
block1# echo "server controller iburst" | sudo tee --append /etc/chrony.conf  
block1# systemctl enable chronyd  
block1# systemctl restart chronyd  
block1# systemctl status chronyd  
block1# chronyc sources  
block1# exit  


# Step:6 Set Environment - OpenStack packages


yum install centos-release-openstack-stein -y  
yum upgrade -y  

ssh compute1  
compute1# yum install centos-release-openstack-stein -y  
compute1# yum upgrade -y  
compute1# exit  

ssh block1  
block1# yum install centos-release-openstack-stein -y  
block1# yum upgrade -y  
block1# exit  

yum install python-openstackclient openstack-selinux -y  

ssh compute1  
compute1# yum install python-openstackclient openstack-selinux -y  
compute1# exit  

ssh block1  
block1# yum install python-openstackclient openstack-selinux -y  
block1# exit  


# Step:7 Set Environment - SQL Database on controller node


yum install mariadb mariadb-server python2-PyMySQL -y  

echo "[mysqld]" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "bind-address = 192.168.137.11" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "default-storage-engine = innodb" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "innodb_file_per_table = on" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "max_connections = 4096" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "collation-server = utf8_general_ci" | sudo tee --append /etc/my.cnf.d/openstack.cnf  
echo "character-set-server = utf8" | sudo tee --append /etc/my.cnf.d/openstack.cnf  

systemctl enable mariadb.service  
systemctl start mariadb.service  


# Step:8 Set Environment - Message queue on controller node


yum install rabbitmq-server -y  
systemctl enable rabbitmq-server.service  
systemctl start rabbitmq-server.service  

rabbitmqctl add_user openstack RABBIT_PASS  
rabbitmqctl set_permissions openstack ".*" ".*" ".*"  


# Step:9 Set Environment - Memcached on controller node


yum install memcached python-memcached -y  

sed -i 's/OPTIONS="-l 127.0.0.1,::1"/OPTIONS="-l 127.0.0.1,::1,controller"/g' /etc/sysconfig/memcached  

systemctl enable memcached.service  
systemctl start memcached.service  


# Step:10 Set Environment - Etcd on controller node


yum install etcd -y  

sed -i 's/#ETCD_LISTEN_PEER_URLS="http:\/\/localhost:2380"/ETCD_LISTEN_PEER_URLS="http:\/\/192.168.137.11:2380"/g' /etc/etcd/etcd.conf  
sed -i 's/ETCD_LISTEN_CLIENT_URLS="http:\/\/localhost:2379"/ETCD_LISTEN_CLIENT_URLS="http:\/\/192.168.137.11:2379"/g' /etc/etcd/etcd.conf  
sed -i 's/ETCD_NAME="default"/ETCD_NAME="controller"/g' /etc/etcd/etcd.conf  
sed -i 's/#ETCD_INITIAL_ADVERTISE_PEER_URLS="http:\/\/localhost:2380"/ETCD_INITIAL_ADVERTISE_PEER_URLS="http:\/\/192.168.137.11:2380"/g' /etc/etcd/etcd.conf  

sed -i 's/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/localhost:2379"/ETCD_ADVERTISE_CLIENT_URLS="http:\/\/192.168.137.11:2379"/g' /etc/etcd/etcd.conf  
sed -i 's/#ETCD_INITIAL_CLUSTER="default=http:\/\/localhost:2380"/ETCD_INITIAL_CLUSTER="controller=http:\/\/192.168.137.11:2380"/g' /etc/etcd/etcd.conf  
sed -i 's/#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"/ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"/g' /etc/etcd/etcd.conf  
sed -i 's/#ETCD_INITIAL_CLUSTER_STATE="new"/ETCD_INITIAL_CLUSTER_STATE="new"/g' /etc/etcd/etcd.conf  

systemctl enable etcd  
systemctl start etcd  


# Step:10 Keystone Installation on controller node


mysql -u root  

mysql> CREATE DATABASE keystone;  
mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';  
mysql> exit  

yum install openstack-keystone httpd mod_wsgi -y  

sed -i 's/#connection = <None>/#connection = <None>\nconnection = mysql+pymysql:\/\/keystone:KEYSTONE_DBPASS@controller\/keystone/g' /etc/keystone/keystone.conf  
sed -i 's/#provider = fernet/#provider = fernet\nprovider = fernet/' /etc/keystone/keystone.conf  

su -s /bin/sh -c "keystone-manage db_sync" keystone  
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone  
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone  

keystone-manage bootstrap --bootstrap-password ADMIN_PASS \  
  --bootstrap-admin-url http://controller:5000/v3/ \  
  --bootstrap-internal-url http://controller:5000/v3/ \  
  --bootstrap-public-url http://controller:5000/v3/ \  
  --bootstrap-region-id RegionOne  


sed -i 's/#ServerName www.example.com:80/#ServerName www.example.com:80\nServerName controller/' /etc/httpd/conf/httpd.conf  
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/  

systemctl enable httpd.service  
systemctl start httpd.service  

export OS_USERNAME=admin  
export OS_PASSWORD=ADMIN_PASS  
export OS_PROJECT_NAME=admin  
export OS_USER_DOMAIN_NAME=Default  
export OS_PROJECT_DOMAIN_NAME=Default  
export OS_AUTH_URL=http://controller:5000/v3  
export OS_IDENTITY_API_VERSION=3  


# Step:11 Keystone Installation - Create a domain, projects, users, and roles on controller node


openstack domain create --description "An Example Domain" example  
openstack project create --domain default --description "Service Project" service  
openstack project create --domain default --description "Demo Project" myproject  

openstack user create --domain default --password mypass myuser  

openstack role create myrole  
openstack role add --project myproject --user myuser myrole  

openstack --os-auth-url http://controller:5000/v3 \  
  --os-project-domain-name Default --os-user-domain-name Default \  
  --os-project-name admin --os-username admin token issue  
```
Password: ADMIN_PASS
```

openstack --os-auth-url http://controller:5000/v3 \  
>   --os-project-domain-name Default --os-user-domain-name Default \  
>   --os-project-name myproject --os-username myuser token issue  

```
Password: mypass
```


echo "export OS_PROJECT_DOMAIN_NAME=Default" | sudo tee --append /root/admin-openrc  
echo "export OS_USER_DOMAIN_NAME=Default" | sudo tee --append /root/admin-openrc  
echo "export OS_PROJECT_NAME=admin" | sudo tee --append /root/admin-openrc  
echo "export OS_USERNAME=admin" | sudo tee --append /root/admin-openrc  
echo "export OS_PASSWORD=ADMIN_PASS" | sudo tee --append /root/admin-openrc  
echo "export OS_AUTH_URL=http://controller:5000/v3" | sudo tee --append /root/admin-openrc  
echo "export OS_IDENTITY_API_VERSION=3" | sudo tee --append /root/admin-openrc  
echo "export OS_IMAGE_API_VERSION=2" | sudo tee --append /root/admin-openrc  

echo "export OS_PROJECT_DOMAIN_NAME=Default" | sudo tee --append /root/demo-openrc  
echo "export OS_USER_DOMAIN_NAME=Default" | sudo tee --append /root/demo-openrc  
echo "export OS_PROJECT_NAME=myproject" | sudo tee --append /root/demo-openrc  
echo "export OS_USERNAME=myuser" | sudo tee --append /root/demo-openrc  
echo "export OS_PASSWORD=mypass" | sudo tee --append /root/demo-openrc  
echo "export OS_AUTH_URL=http://controller:5000/v3" | sudo tee --append /root/demo-openrc  
echo "export OS_IDENTITY_API_VERSION=3" | sudo tee --append /root/demo-openrc  
echo "export OS_IMAGE_API_VERSION=2" | sudo tee --append /root/demo-openrc  



# Step:12 glance Installation -  on controller node


mysql -u root  

mysql> CREATE DATABASE glance;  
mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';  
mysql> exit  
  
. admin-openrc  
  
openstack user create --domain default --password GLANCE_DBPASS glance  
  
openstack role add --project service --user glance admin  
openstack service create --name glance --description "OpenStack Image service" image  
openstack endpoint create --region RegionOne image public http://controller:9292  
openstack endpoint create --region RegionOne image internal http://controller:9292  
openstack endpoint create --region RegionOne image admin http://controller:9292  


yum -y install openstack-glance   

sed -i 's/#connection = <None>/#connection = <None>/\nconnection = mysql+pymysql:\/\/glance:GLANCE_DBPASS@controller\/glance/g' /etc/glance/glance-api.conf  

sed -i 's/#www_authenticate_uri = <None>/#www_authenticate_uri = <None>\nwww_authenticate_uri  = http:\/\/controller:5000/' /etc/glance/glance-api.conf  
sed -i 's/#auth_uri = <None>/#auth_uri = <None>\nauth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/' /etc/glance/glance-api.conf  
sed -i 's/#memcached_servers = <None>/#memcached_servers = <None>\nmemcached_servers = controller:11211/' /etc/glance/glance-api.conf  
sed -i 's/#auth_type = <None>/#auth_type = <None>\nauth_type = password\nproject_domain_name = Default\nuser_domain_name = Default\nproject_name = service\nusername = glance\npassword = GLANCE_DBPASS/' /etc/glance/glance-api.conf  
sed -i 's/#flavor = keystone/#flavor = keystone\nflavor = keystone/' /etc/glance/glance-api.conf  

sed -i 's/#stores = file,http/#stores = file,http\nstores = file,http/' /etc/glance/glance-api.conf  
sed -i 's/#default_store = file/#default_store = file\ndefault_store = file/g' /etc/glance/glance-api.conf  
sed -i 's/#filesystem_store_datadir = \/var\/lib\/glance\/images/#filesystem_store_datadir = \/var\/lib\/glance\/images\nfilesystem_store_datadir = \/var\/lib\/glance\/images\//' /etc/glance/glance-api.conf  
  
sed -i 's/#service_token_roles_required = false/#service_token_roles_required = false\nservice_token_roles_required = true/' /etc/glance/glance-api.conf  


sed -i 's/#connection = <None>/#connection = <None>\nconnection = mysql+pymysql:\/\/glance:GLANCE_DBPASS@controller\/glance/g' /etc/glance/glance-registry.conf  

sed -i 's/#www_authenticate_uri = <None>/#www_authenticate_uri = <None>\nwww_authenticate_uri  = http:\/\/controller:5000/' /etc/glance/glance-registry.conf  
sed -i 's/#auth_uri = <None>/#auth_uri = <None>\nauth_uri = http:\/\/controller:5000/' /etc/glance/glance-registry.conf  
sed -i 's/#memcached_servers = <None>/#memcached_servers = <None>\nmemcached_servers = controller:11211/' /etc/glance/glance-registry.conf  
sed -i 's/#auth_type = <None>/#auth_type = <None>\nauth_type = password\nproject_domain_name = Default\nuser_domain_name = Default\nproject_name = service\nusername = glance\npassword = GLANCE_DBPASS/' /etc/glance/glance-registry.conf  
sed -i 's/#flavor = keystone/#flavor = keystone\nflavor = keystone/' /etc/glance/glance-registry.conf  

su -s /bin/sh -c "glance-manage db_sync" glance  

systemctl enable openstack-glance-api.service openstack-glance-registry.service  
systemctl start openstack-glance-api.service openstack-glance-registry.service  
systemctl restart openstack-glance-api.service openstack-glance-registry.service  

`# egrep -v "^#|^$" /etc/glance/glance-api.conf`
  

# Step:12 glance Installation - Verify operation

. admin-openrc  

`# openstack-glance-api.service port tcp 9292`  
lsof -i tcp:9292  
`# openstack-glance-registry.service port tcp 9191`  
lsof -i tcp:9191  

wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img  
openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public  
openstack image list


# Step:13 placement Installation


mysql -u root   

mysql> CREATE DATABASE placement;  
mysql> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'PLACEMENT_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'PLACEMENT_DBPASS';  
  
. admin-openrc  
  
openstack user create --domain default --password PLACEMENT_DBPASS placement  
openstack role add --project service --user placement admin  
openstack service create --name placement --description "Placement API" placement  
openstack endpoint create --region RegionOne placement public http://controller:8778  
openstack endpoint create --region RegionOne placement internal http://controller:8778  
openstack endpoint create --region RegionOne placement admin http://controller:8778  


yum -y install openstack-placement-api  

```
[root@controller ~]# egrep -v "^#|^$" /etc/placement/placement.conf
[DEFAULT]
[api]
[keystone_authtoken]
[placement]
[placement_database]
```
mv /etc/placement/placement.conf  /etc/placement/placement.conf.original  
cat <<EOF > /etc/placement/placement.conf 
[DEFAULT]
[api]
auth_strategy = keystone
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_DBPASS
[placement]
[placement_database]
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
EOF

chown root.placement /etc/placement/placement.conf 
chmod 640 /etc/placement/placement.conf

su -s /bin/sh -c "placement-manage db sync" placement  



# Step:14 glance Installation - Verify Installation

`# httpd placement-api port tcp 8778`  
lsof -i tcp:8778  


. admin-openrc  
placement-status upgrade check  

```
[root@controller ~]# placement-status upgrade check
+----------------------------------+
| Upgrade Check Results            |
+----------------------------------+
| Check: Missing Root Provider IDs |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
| Check: Incomplete Consumers      |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
```

# Step:15 Compute service(nova) Installation


mysql -u root   

mysql> CREATE DATABASE nova_api;  
mysql> CREATE DATABASE nova;  
mysql> CREATE DATABASE nova_cell0;  
mysql> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';  

## admin credentials
. admin-openrc  

openstack user create --domain default --password NOVA_DBPASS nova  
openstack role add --project service --user nova admin  
openstack service create --name nova --description "OpenStack Compute" compute  

openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

openstack endpoint list  

yum -y install openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler  

```
Installed:
  openstack-nova-api.noarch 1:19.3.2-1.el7                 openstack-nova-conductor.noarch 1:19.3.2-1.el7           openstack-nova-novncproxy.noarch 1:19.3.2-1.el7
  openstack-nova-scheduler.noarch 1:19.3.2-1.el7

Dependency Installed:
  dpdk.x86_64 0:18.11.8-1.el7_8                              libsodium.x86_64 0:1.0.18-0.el7                                novnc.noarch 0:0.5.1-2.el7
  openstack-nova-common.noarch 1:19.3.2-1.el7                openvswitch.x86_64 1:2.11.0-4.el7                              python-kazoo.noarch 0:2.2.1-1.el7
  python-openvswitch.x86_64 1:2.11.0-4.el7                   python-oslo-versionedobjects-lang.noarch 0:1.35.1-1.el7        python-websockify.noarch 0:0.8.0-1.el7
  python2-nova.noarch 1:19.3.2-1.el7                         python2-os-vif.noarch 0:1.15.2-1.el7                           python2-oslo-reports.noarch 0:1.29.2-1.el7
  python2-oslo-versionedobjects.noarch 0:1.35.1-1.el7        python2-ovsdbapp.noarch 0:0.15.1-1.el7                         python2-paramiko.noarch 0:2.4.2-2.el7
  python2-psutil.x86_64 0:5.5.1-1.el7                        python2-pynacl.x86_64 0:1.3.0-1.el7                            python2-pyroute2.noarch 0:0.5.6-1.el7
  python2-redis.noarch 0:3.1.0-1.el7                         python2-tooz.noarch 0:1.64.3-1.el7                             python2-voluptuous.noarch 0:0.10.5-2.el7
  python2-zake.noarch 0:0.2.2-2.el7                          unbound-libs.x86_64 0:1.6.6-5.el7_8

Complete!
[root@controller ~]# egrep -v "^#|^$" /etc/nova/nova.conf
[DEFAULT]
[api]
[api_database]
[barbican]
[cache]
[cells]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
[guestfs]
[healthcheck]
[hyperv]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
[libvirt]
[metrics]
[mks]
[neutron]
[notifications]
[osapi_v21]
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
[placement_database]
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
[workarounds]
[wsgi]
[xenserver]
[xvp]
[zvm]
[root@controller ~]#
```


mv /etc/nova/nova.conf /etc/nova/nova.conf.original  
cat <<EOF > /etc/nova/nova.conf  
[DEFAULT]  
enabled_apis = osapi_compute,metadata  
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/  
use_neutron = true  
firewall_driver = nova.virt.firewall.NoopFirewallDriver  
[api]  
auth_strategy=keystone  
[api_database]  
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api  
[barbican]  
[cache]  
[cells]  
[cinder]  
[compute]  
[conductor]  
[console]  
[consoleauth]  
[cors]  
[database]  
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova  
[devices]  
[ephemeral_storage_encryption]  
[filter_scheduler]  
[glance]  
api_servers = http://controller:9292  
[guestfs]  
[healthcheck]  
[hyperv]  
[ironic]  
[key_manager]  
[keystone]    
[keystone_authtoken]  
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211  
auth_type = password  
project_domain_name = Default  
user_domain_name = Default  
project_name = service  
username = nova  
password = NOVA_DBPASS  
[libvirt]  
[metrics]  
[mks]  
[neutron]  
[notifications]  
[osapi_v21]  
[oslo_concurrency]  
lock_path = /var/lib/nova/tmp  
[oslo_messaging_amqp]  
[oslo_messaging_kafka]  
[oslo_messaging_notifications]  
[oslo_messaging_rabbit]  
[oslo_middleware]  
[oslo_policy]  
[pci]  
[placement]  
region_name = RegionOne  
project_domain_name = Default  
project_name = service  
auth_type = password  
user_domain_name = Default  
auth_uri = http://controller:5000/v3
auth_url = http://controller:5000
username = placement  
password = PLACEMENT_DBPASS  
[placement_database]  
[powervm]  
[privsep]  
[profiler]  
[quota]  
[rdp]  
[remote_debug]  
[scheduler]  
discover_hosts_in_cells_interval = 300  
[serial_console]  
[service_user]  
[spice]  
[upgrade_levels]  
[vault]  
[vendordata_dynamic_auth]  
[vmware]  
[vnc]  
enabled = true  
server_listen = 192.168.137.11  
server_proxyclient_address = 192.168.137.11  
[workarounds]  
[wsgi]  
[xenserver]  
[xvp]  
[zvm]  
EOF  

chown root.nova /etc/nova/nova.conf  
chmod 640 /etc/nova/nova.conf  

su -s /bin/sh -c "nova-manage api_db sync" nova  
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova  
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova  
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova  

systemctl enable \  
    openstack-nova-api.service \  
    openstack-nova-scheduler.service \  
    openstack-nova-conductor.service \  
    openstack-nova-novncproxy.service  

systemctl start \  
    openstack-nova-api.service \  
    openstack-nova-scheduler.service \  
    openstack-nova-conductor.service \  
    openstack-nova-novncproxy.service  




# Step:16 Compute service(nova) Installation Verify

`# openstack-nova-api.service port tcp ????`  
lsof -i tcp:????

`# openstack-nova-scheduler.service port tcp ????``  
lsof -i tcp:????  

# lsof -p 12939




. admin-openrc

openstack server list  

nova service-list  
```
[root@controller ~]# nova service-list
+--------------------------------------+----------------+------------+----------+---------+-------+----------------------------+-----------------+-------------+
| Id                                   | Binary         | Host       | Zone     | Status  | State | Updated_at                 | Disabled Reason | Forced down |
+--------------------------------------+----------------+------------+----------+---------+-------+----------------------------+-----------------+-------------+
| 842923b7-4c69-43f9-802d-cf74d141da5b | nova-scheduler | controller | internal | enabled | up    | 2022-03-18T12:41:18.000000 | -               | False       |
| 30431175-3624-486c-92ee-151b11ce6784 | nova-conductor | controller | internal | enabled | up    | 2022-03-18T12:41:18.000000 | -               | False       |
+--------------------------------------+----------------+------------+----------+---------+-------+----------------------------+-----------------+-------------+
[root@controller ~]#
```

 
# Step:17 Compute service(nova) add Installation - on compute1

ssh compute1  
```
[root@controller ~]# ssh compute1
Last login: Fri Mar 18 10:59:17 2022 from controller.zasfe.local
[root@compute1 ~]#
```


yum -y install openstack-nova-compute  


mv /etc/nova/nova.conf /etc/nova/nova.conf.original  

cat <<EOF > /etc/nova/nova.conf
[DEFAULT]  
enabled_apis = osapi_compute,metadata  
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/  
use_neutron = true  
firewall_driver = nova.virt.firewall.NoopFirewallDriver  
[api]  
auth_strategy=keystone  
[api_database]  
[barbican]  
[cache]  
[cells]  
[cinder]  
[compute]  
[conductor]  
[console]  
[consoleauth]  
[cors]  
[database]  
[devices]  
[ephemeral_storage_encryption]  
[filter_scheduler]  
[glance]  
api_servers = http://controller:9292  
[guestfs]  
[healthcheck]  
[hyperv]  
[ironic]  
[key_manager]  
[keystone]    
[keystone_authtoken]  
www_authenticate_uri = http://controller:5000/  
auth_url = http://controller:5000/  
auth_url = http://controller:35357
memcached_servers = controller:11211  
auth_type = password  
project_domain_name = Default  
user_domain_name = Default  
project_name = service  
username = nova  
password = NOVA_DBPASS  
[libvirt]  
virt_type = qemu  
[metrics]  
[mks]  
[neutron]  
[notifications]  
[osapi_v21]  
[oslo_concurrency]  
lock_path = /var/lib/nova/tmp  
[oslo_messaging_amqp]  
[oslo_messaging_kafka]  
[oslo_messaging_notifications]  
[oslo_messaging_rabbit]  
[oslo_middleware]  
[oslo_policy]  
[pci]  
[placement]  
region_name = RegionOne  
project_domain_name = Default  
project_name = service  
auth_type = password  
user_domain_name = Default  
auth_url = http://controller:5000/v3  
auth_url = http://controller:35357  
username = placement  
password = PLACEMENT_DBPASS  
[placement_database]  
[powervm]  
[privsep]  
[profiler]  
[quota]  
[rdp]  
[remote_debug]  
[scheduler]  
[serial_console]  
[service_user]  
[spice]  
[upgrade_levels]  
[vault]  
[vendordata_dynamic_auth]  
[vmware]  
[vnc]  
enabled = true  
server_listen = 0.0.0.0  
server_proxyclient_address = 192.168.137.11  
novncproxy_base_url = http://controller:6080/vnc_auto.html  
[workarounds]  
[wsgi]  
[xenserver]  
[xvp]  
[zvm]  
EOF

chown root.nova /etc/nova/nova.conf  
chmod 640 /etc/nova/nova.conf  

systemctl enable libvirtd.service openstack-nova-compute.service  
systemctl start libvirtd.service openstack-nova-compute.service  

```
[root@compute1 ~]#  systemctl status libvirtd.service
● libvirtd.service - Virtualization daemon
   Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2022-03-18 21:52:56 KST; 59s ago
     Docs: man:libvirtd(8)
           https://libvirt.org
 Main PID: 14308 (libvirtd)
    Tasks: 17 (limit: 32768)
   CGroup: /system.slice/libvirtd.service
           └─14308 /usr/sbin/libvirtd

Mar 18 21:52:56 compute1 systemd[1]: Starting Virtualization daemon...
Mar 18 21:52:56 compute1 systemd[1]: Started Virtualization daemon.
[root@compute1 ~]# systemctl status openstack-nova-compute.service
● openstack-nova-compute.service - OpenStack Nova Compute Server
   Loaded: loaded (/usr/lib/systemd/system/openstack-nova-compute.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2022-03-18 21:53:01 KST; 1min 2s ago
 Main PID: 14325 (nova-compute)
    Tasks: 22
   CGroup: /system.slice/openstack-nova-compute.service
           └─14325 /usr/bin/python2 /usr/bin/nova-compute

Mar 18 21:52:56 compute1 systemd[1]: Starting OpenStack Nova Compute Server...
Mar 18 21:53:01 compute1 systemd[1]: Started OpenStack Nova Compute Server.
[root@compute1 ~]# 
```

## Change controler node

```
[root@compute1 ~]# exit
logout
Connection to compute1 closed.
[root@controller ~]#
```

. admin-openrc  

openstack compute service list --service nova-compute  

```
[root@controller ~]# openstack compute service list --service nova-compute
+----+--------------+----------+------+---------+-------+----------------------------+
| ID | Binary       | Host     | Zone | Status  | State | Updated At                 |
+----+--------------+----------+------+---------+-------+----------------------------+
|  5 | nova-compute | compute1 | nova | enabled | up    | 2022-03-18T12:55:37.000000 |
+----+--------------+----------+------+---------+-------+----------------------------+
```

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova  

```
[root@controller ~]# su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
Found 2 cell mappings.
Skipping cell0 since it does not contain hosts.
Getting computes from cell 'cell1': 91b4f3d5-385c-4e34-8c6b-9b11140359b4
Checking host mapping for compute host 'compute1': 17a10dcd-3c08-4688-92ce-e208eb619f63
Creating host mapping for compute host 'compute1': 17a10dcd-3c08-4688-92ce-e208eb619f63
Found 1 unmapped computes in cell: 91b4f3d5-385c-4e34-8c6b-9b11140359b4
```


# Step:18 Compute service(nova) Verify operation - on controller node.

. admin-openrc  

openstack compute service list  

```
[root@controller ~]# openstack compute service list
+----+----------------+------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host       | Zone     | Status  | State | Updated At                 |
+----+----------------+------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler | controller | internal | enabled | up    | 2022-03-18T13:08:08.000000 |
|  2 | nova-conductor | controller | internal | enabled | up    | 2022-03-18T13:08:08.000000 |
|  5 | nova-compute   | compute1   | nova     | enabled | up    | 2022-03-18T13:08:08.000000 |
+----+----------------+------------+----------+---------+-------+----------------------------+
```

openstack catalog list  

```
[root@controller ~]# openstack catalog list
+-----------+-----------+-----------------------------------------+
| Name      | Type      | Endpoints                               |
+-----------+-----------+-----------------------------------------+
| nova      | compute   | RegionOne                               |
|           |           |   admin: http://controller:8774/v2.1    |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:8774/v2.1 |
|           |           | RegionOne                               |
|           |           |   public: http://controller:8774/v2.1   |
|           |           |                                         |
| placement | placement | RegionOne                               |
|           |           |   internal: http://controller:8778      |
|           |           | RegionOne                               |
|           |           |   public: http://controller:8778        |
|           |           | RegionOne                               |
|           |           |   admin: http://controller:8778         |
|           |           |                                         |
| keystone  | identity  | RegionOne                               |
|           |           |   internal: http://controller:5000/v3/  |
|           |           | RegionOne                               |
|           |           |   public: http://controller:5000/v3/    |
|           |           | RegionOne                               |
|           |           |   admin: http://controller:5000/v3/     |
|           |           |                                         |
| glance    | image     | RegionOne                               |
|           |           |   admin: http://controller:9292         |
|           |           | RegionOne                               |
|           |           |   public: http://controller:9292        |
|           |           | RegionOne                               |
|           |           |   internal: http://controller:9292      |
|           |           |                                         |
+-----------+-----------+-----------------------------------------+

```


openstack image list  

```
[root@controller ~]# openstack image list
+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| a7fb9dc2-8a39-44ae-9583-bb3a055547d6 | cirros | active |
+--------------------------------------+--------+--------+
```


nova-status upgrade check  
```
[root@controller ~]# nova-status upgrade check
+--------------------------------+
| Upgrade Check Results          |
+--------------------------------+
| Check: Cells v2                |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Placement API           |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Ironic Flavor Migration |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Request Spec Migration  |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Console Auths           |
| Result: Success                |
| Details: None                  |
+--------------------------------+
```

```
[root@controller ~]# vim /etc/httpd/conf.d/00-placement-api.conf
Listen 8778

<VirtualHost *:8778>
  WSGIProcessGroup placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  WSGIDaemonProcess placement-api processes=3 threads=1 user=placement group=placement
  WSGIScriptAlias / /usr/bin/placement-api
  <Directory /usr/bin>
    Require all denied
    <Files "placement-api">
      <RequireAll>
        Require all granted
        Require not env blockAccess
      </RequireAll>
    </Files>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
  </Directory>
  <IfVersion >= 2.4>
    ErrorLogFormat "%M"
  </IfVersion>
  ErrorLog /var/log/placement/placement-api.log
  #SSLEngine On
  #SSLCertificateFile ...
  #SSLCertificateKeyFile ...
</VirtualHost>
...(중략)...
```




# Step:19 Networking service(neutron) - on controller node.

mysql -u root  

mysql> CREATE DATABASE neutron;  
mysql> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';  
mysql> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';  
mysql> exit  

. admin-openrc  

openstack user create --domain default --password NEUTRON_DBPASS neutron  
openstack role add --project service --user neutron admin  
openstack service create --name neutron --description "OpenStack Networking" network  

```
[root@controller ~]# openstack user create --domain default --password NEUTRON_DBPASS neutron
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 437174860bfa441dbb89ec82bfde89e3 |
| name                | neutron                          |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
[root@controller ~]# openstack role add --project service --user neutron admin
[root@controller ~]# openstack service create --name neutron --description "OpenStack Networking" network
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Networking             |
| enabled     | True                             |
| id          | 2a1df2ae9cc64fdebcfc2800910922ec |
| name        | neutron                          |
| type        | network                          |
+-------------+----------------------------------+
```


openstack endpoint create --region RegionOne network public http://controller:9696  
openstack endpoint create --region RegionOne network internal http://controller:9696  
openstack endpoint create --region RegionOne network admin http://controller:9696  

```
[root@controller ~]# openstack endpoint create --region RegionOne network public http://controller:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 2b49ea8a12b94f4089e385ddd29f0fd2 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2a1df2ae9cc64fdebcfc2800910922ec |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://controller:9696           |
+--------------+----------------------------------+
[root@controller ~]# openstack endpoint create --region RegionOne network internal http://controller:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 9b12f44343594a638897cbad0bc0de6d |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2a1df2ae9cc64fdebcfc2800910922ec |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://controller:9696           |
+--------------+----------------------------------+
[root@controller ~]# openstack endpoint create --region RegionOne network admin http://controller:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 4cb63440cf75438e840192d523903eaf |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 2a1df2ae9cc64fdebcfc2800910922ec |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://controller:9696           |
+--------------+----------------------------------+
```


# Step:20 Networking service(neutron) - Networking Option 2: Self-service networks on controller node.
## https://docs.openstack.org/neutron/stein/install/controller-install-option2-rdo.html

yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables

```
[root@controller ~]# yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
...
Installed:
  openstack-neutron.noarch 1:14.4.2-1.el7
  openstack-neutron-linuxbridge.noarch 1:14.4.2-1.el7
  openstack-neutron-ml2.noarch 1:14.4.2-1.el7

Dependency Installed:
  c-ares.x86_64 0:1.10.0-3.el7
  conntrack-tools.x86_64 0:1.4.4-7.el7
  dibbler-client.x86_64 0:1.0.1-0.RC1.2.el7
  dnsmasq.x86_64 0:2.76-17.el7_9.3
  dnsmasq-utils.x86_64 0:2.76-17.el7_9.3
  haproxy.x86_64 0:1.5.18-9.el7_9.1
  keepalived.x86_64 0:1.3.5-19.el7
  libev.x86_64 0:4.15-7.el7
  libnetfilter_cthelper.x86_64 0:1.0.0-11.el7
  libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7
  libnetfilter_queue.x86_64 0:1.0.2-2.el7_2
  net-snmp-agent-libs.x86_64 1:5.7.2-49.el7_9.1
  net-snmp-libs.x86_64 1:5.7.2-49.el7_9.1
  nettle.x86_64 0:2.7.1-9.el7_9
  openpgm.x86_64 0:5.2.122-2.el7
  openstack-neutron-common.noarch 1:14.4.2-1.el7
  python-beautifulsoup4.noarch 0:4.6.0-1.el7
  python-logutils.noarch 0:0.3.3-3.el7
  python-setproctitle.x86_64 0:1.1.9-4.el7
  python-waitress.noarch 0:0.8.9-5.el7
  python-webtest.noarch 0:2.0.23-1.el7
  python-zmq.x86_64 0:14.7.0-2.el7
  python2-designateclient.noarch 0:2.11.0-1.el7
  python2-gevent.x86_64 0:1.1.2-2.el7
  python2-neutron.noarch 1:14.4.2-1.el7
  python2-neutron-lib.noarch 0:1.25.1-1.el7
  python2-os-ken.noarch 0:0.3.1-1.el7
  python2-os-xenapi.noarch 0:0.3.4-1.el7
  python2-pecan.noarch 0:1.3.2-1.el7
  python2-singledispatch.noarch 0:3.4.0.3-4.el7
  python2-tinyrpc.noarch 0:0.5-4.20170523git1f38ac.el7
  python2-weakrefmethod.noarch 0:1.0.2-3.el7
  radvd.x86_64 0:2.17-3.el7
  zeromq.x86_64 0:4.0.5-4.el7

Complete!
[root@controller ~]# egrep -v "^#|^$" /etc/neutron/neutron.conf
[DEFAULT]
[cors]
[database]
[keystone_authtoken]
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
[root@controller ~]# egrep -v "^#|^$" /etc/neutron/plugins/ml2/ml2_conf.ini
[DEFAULT]
[root@controller ~]# egrep -v "^#|^$" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[DEFAULT]
[root@controller ~]# egrep -v "^#|^$" /etc/neutron/l3_agent.ini
[DEFAULT]
[root@controller ~]# egrep -v "^#|^$" /etc/neutron/dhcp_agent.ini
[DEFAULT]
[root@controller ~]#
```


mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cat <<EOF > /etc/neutron/neutron.conf
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
[cors]
[database]
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_DBPASS
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
[nova]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_DBPASS
EOF

chown root.neutron /etc/neutron/neutron.conf
chmod 640 /etc/neutron/neutron.conf


# Step:21 Networking service(neutron) - Configure the Modular Layer 2 (ML2) plug-in on Control node


mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.original
cat <<EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[DEFAULT]
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security
[ml2_type_flat]
flat_networks = provider
[ml2_type_vxlan]
vni_ranges = 1:1000
[securitygroup]
enable_ipset = true
EOF

chown root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini
chmod 640 /etc/neutron/plugins/ml2/ml2_conf.ini


# Step:22 Networking service(neutron) - Configure the Linux bridge agent on Control node

mv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
cat <<EOF > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[DEFAULT]
[linux_bridge]
physical_interface_mappings = provider:eth1
[vxlan]
enable_vxlan = true
local_ip = 10.0.0.11
l2_population = true
[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
EOF

chown root.neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chmod 640 /etc/neutron/plugins/ml2/linuxbridge_agent.ini

modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee --append /etc/sysctl.conf 
echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee --append /etc/sysctl.conf
sysctl -p

# Step:23 Networking service(neutron) - Configure the layer-3 agent on Control node

mv /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.original
cat <<EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = linuxbridge
EOF

chown root.neutron /etc/neutron/l3_agent.ini
chmod 640 /etc/neutron/l3_agent.ini


# Step:24 Networking service(neutron) - Configure the DHCP agent on Control node

mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.original
cat <<EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

chown root.neutron /etc/neutron/dhcp_agent.ini
chmod 640 /etc/neutron/dhcp_agent.ini



# Step:25 Networking service(neutron) - Install and configure compute node
## https://docs.openstack.org/neutron/stein/install/compute-install-rdo.html
ssh compute1

yum -y install openstack-neutron-linuxbridge ebtables ipset
```
[root@controller ~]# ssh compute1
Last login: Mon Mar 21 15:53:53 2022 from gateway
[root@compute1 ~]# yum -y install openstack-neutron-linuxbridge ebtables ipset
...
Installed:
  openstack-neutron-linuxbridge.noarch 1:14.4.2-1.el7

Dependency Installed:
  c-ares.x86_64 0:1.10.0-3.el7                       libev.x86_64 0:4.15-7.el7                                 openpgm.x86_64 0:5.2.122-2.el7                  openstack-neutron-common.noarch 1:14.4.2-1.el7
  python-beautifulsoup4.noarch 0:4.6.0-1.el7         python-httplib2.noarch 0:0.9.2-1.el7                      python-logutils.noarch 0:0.3.3-3.el7            python-setproctitle.x86_64 0:1.1.9-4.el7
  python-simplegeneric.noarch 0:0.8-7.el7            python-waitress.noarch 0:0.8.9-5.el7                      python-webtest.noarch 0:2.0.23-1.el7            python-zmq.x86_64 0:14.7.0-2.el7
  python2-designateclient.noarch 0:2.11.0-1.el7      python2-gevent.x86_64 0:1.1.2-2.el7                       python2-neutron.noarch 1:14.4.2-1.el7           python2-neutron-lib.noarch 0:1.25.1-1.el7
  python2-os-ken.noarch 0:0.3.1-1.el7                python2-os-xenapi.noarch 0:0.3.4-1.el7                    python2-osprofiler.noarch 0:2.6.1-1.el7         python2-pecan.noarch 0:1.3.2-1.el7
  python2-singledispatch.noarch 0:3.4.0.3-4.el7      python2-tinyrpc.noarch 0:0.5-4.20170523git1f38ac.el7      python2-weakrefmethod.noarch 0:1.0.2-3.el7      python2-werkzeug.noarch 0:0.14.1-3.el7
  zeromq.x86_64 0:4.0.5-4.el7

Complete!
[root@compute1 ~]# egrep -v "^#|^$" /etc/neutron/neutron.conf
[DEFAULT]
[cors]
[database]
[keystone_authtoken]
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
[root@compute1 ~]#
```

## (compute node) Configure the common component

mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cat <<EOF > /etc/neutron/neutron.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
[cors]
[database]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_DBPASS
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
EOF

chown root.neutron /etc/neutron/neutron.conf
chmod 640 /etc/neutron/neutron.conf



## (compute node) Configure the Compute service to use the Networking service

sed -i 's/^\[neutron\]/\# \[neutron\]/' /etc/nova/nova.conf

echo "[neutron]" | sudo tee --append /etc/nova/nova.conf
echo "url = http://controller:9696" | sudo tee --append /etc/nova/nova.conf
echo "auth_url = http://controller:5000" | sudo tee --append /etc/nova/nova.conf
echo "auth_type = password" | sudo tee --append /etc/nova/nova.conf
echo "project_domain_name = default" | sudo tee --append /etc/nova/nova.conf
echo "user_domain_name = default" | sudo tee --append /etc/nova/nova.conf
echo "region_name = RegionOne" | sudo tee --append /etc/nova/nova.conf
echo "project_name = service" | sudo tee --append /etc/nova/nova.conf
echo "username = neutron" | sudo tee --append /etc/nova/nova.conf
echo "password = NEUTRON_DBPASS" | sudo tee --append /etc/nova/nova.conf
echo "service_metadata_proxy = true" | sudo tee --append /etc/nova/nova.conf
echo "metadata_proxy_shared_secret = METADATA_SECRET" | sudo tee --append /etc/nova/nova.conf

## (compute node)  Finalize installation

systemctl restart openstack-nova-compute.service
systemctl status openstack-nova-compute.service


systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service




# Step:25 Networking service(neutron) - Configure the metadata agent on control node

mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.original
cat <<EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = METADATA_SECRET
EOF

chown root.neutron /etc/neutron/metadata_agent.ini
chmod 640 /etc/neutron/metadata_agent.ini

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```
[root@controller ~]# ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
[root@controller ~]# su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
>   --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
INFO  [alembic.runtime.migration] Context impl MySQLImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
  Running upgrade for neutron ...
INFO  [alembic.runtime.migration] Context impl MySQLImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> kilo
INFO  [alembic.runtime.migration] Running upgrade kilo -> 354db87e3225
INFO  [alembic.runtime.migration] Running upgrade 354db87e3225 -> 599c6a226151
INFO  [alembic.runtime.migration] Running upgrade 599c6a226151 -> 52c5312f6baf
INFO  [alembic.runtime.migration] Running upgrade 52c5312f6baf -> 313373c0ffee
INFO  [alembic.runtime.migration] Running upgrade 313373c0ffee -> 8675309a5c4f
INFO  [alembic.runtime.migration] Running upgrade 8675309a5c4f -> 45f955889773
INFO  [alembic.runtime.migration] Running upgrade 45f955889773 -> 26c371498592
INFO  [alembic.runtime.migration] Running upgrade 26c371498592 -> 1c844d1677f7
INFO  [alembic.runtime.migration] Running upgrade 1c844d1677f7 -> 1b4c6e320f79
INFO  [alembic.runtime.migration] Running upgrade 1b4c6e320f79 -> 48153cb5f051
INFO  [alembic.runtime.migration] Running upgrade 48153cb5f051 -> 9859ac9c136
INFO  [alembic.runtime.migration] Running upgrade 9859ac9c136 -> 34af2b5c5a59
INFO  [alembic.runtime.migration] Running upgrade 34af2b5c5a59 -> 59cb5b6cf4d
INFO  [alembic.runtime.migration] Running upgrade 59cb5b6cf4d -> 13cfb89f881a
INFO  [alembic.runtime.migration] Running upgrade 13cfb89f881a -> 32e5974ada25
INFO  [alembic.runtime.migration] Running upgrade 32e5974ada25 -> ec7fcfbf72ee
INFO  [alembic.runtime.migration] Running upgrade ec7fcfbf72ee -> dce3ec7a25c9
INFO  [alembic.runtime.migration] Running upgrade dce3ec7a25c9 -> c3a73f615e4
INFO  [alembic.runtime.migration] Running upgrade c3a73f615e4 -> 659bf3d90664
INFO  [alembic.runtime.migration] Running upgrade 659bf3d90664 -> 1df244e556f5
INFO  [alembic.runtime.migration] Running upgrade 1df244e556f5 -> 19f26505c74f
INFO  [alembic.runtime.migration] Running upgrade 19f26505c74f -> 15be73214821
INFO  [alembic.runtime.migration] Running upgrade 15be73214821 -> b4caf27aae4
INFO  [alembic.runtime.migration] Running upgrade b4caf27aae4 -> 15e43b934f81
INFO  [alembic.runtime.migration] Running upgrade 15e43b934f81 -> 31ed664953e6
INFO  [alembic.runtime.migration] Running upgrade 31ed664953e6 -> 2f9e956e7532
INFO  [alembic.runtime.migration] Running upgrade 2f9e956e7532 -> 3894bccad37f
INFO  [alembic.runtime.migration] Running upgrade 3894bccad37f -> 0e66c5227a8a
INFO  [alembic.runtime.migration] Running upgrade 0e66c5227a8a -> 45f8dd33480b
INFO  [alembic.runtime.migration] Running upgrade 45f8dd33480b -> 5abc0278ca73
INFO  [alembic.runtime.migration] Running upgrade 5abc0278ca73 -> d3435b514502
INFO  [alembic.runtime.migration] Running upgrade d3435b514502 -> 30107ab6a3ee
INFO  [alembic.runtime.migration] Running upgrade 30107ab6a3ee -> c415aab1c048
INFO  [alembic.runtime.migration] Running upgrade c415aab1c048 -> a963b38d82f4
INFO  [alembic.runtime.migration] Running upgrade kilo -> 30018084ec99
INFO  [alembic.runtime.migration] Running upgrade 30018084ec99 -> 4ffceebfada
INFO  [alembic.runtime.migration] Running upgrade 4ffceebfada -> 5498d17be016
INFO  [alembic.runtime.migration] Running upgrade 5498d17be016 -> 2a16083502f3
INFO  [alembic.runtime.migration] Running upgrade 2a16083502f3 -> 2e5352a0ad4d
INFO  [alembic.runtime.migration] Running upgrade 2e5352a0ad4d -> 11926bcfe72d
INFO  [alembic.runtime.migration] Running upgrade 11926bcfe72d -> 4af11ca47297
INFO  [alembic.runtime.migration] Running upgrade 4af11ca47297 -> 1b294093239c
INFO  [alembic.runtime.migration] Running upgrade 1b294093239c -> 8a6d8bdae39
INFO  [alembic.runtime.migration] Running upgrade 8a6d8bdae39 -> 2b4c2465d44b
INFO  [alembic.runtime.migration] Running upgrade 2b4c2465d44b -> e3278ee65050
INFO  [alembic.runtime.migration] Running upgrade e3278ee65050 -> c6c112992c9
INFO  [alembic.runtime.migration] Running upgrade c6c112992c9 -> 5ffceebfada
INFO  [alembic.runtime.migration] Running upgrade 5ffceebfada -> 4ffceebfcdc
INFO  [alembic.runtime.migration] Running upgrade 4ffceebfcdc -> 7bbb25278f53
INFO  [alembic.runtime.migration] Running upgrade 7bbb25278f53 -> 89ab9a816d70
INFO  [alembic.runtime.migration] Running upgrade a963b38d82f4 -> 3d0e74aa7d37
INFO  [alembic.runtime.migration] Running upgrade 3d0e74aa7d37 -> 030a959ceafa
INFO  [alembic.runtime.migration] Running upgrade 030a959ceafa -> a5648cfeeadf
INFO  [alembic.runtime.migration] Running upgrade a5648cfeeadf -> 0f5bef0f87d4
INFO  [alembic.runtime.migration] Running upgrade 0f5bef0f87d4 -> 67daae611b6e
INFO  [alembic.runtime.migration] Running upgrade 89ab9a816d70 -> c879c5e1ee90
INFO  [alembic.runtime.migration] Running upgrade c879c5e1ee90 -> 8fd3918ef6f4
INFO  [alembic.runtime.migration] Running upgrade 8fd3918ef6f4 -> 4bcd4df1f426
INFO  [alembic.runtime.migration] Running upgrade 4bcd4df1f426 -> b67e765a3524
INFO  [alembic.runtime.migration] Running upgrade 67daae611b6e -> 6b461a21bcfc
INFO  [alembic.runtime.migration] Running upgrade 6b461a21bcfc -> 5cd92597d11d
INFO  [alembic.runtime.migration] Running upgrade 5cd92597d11d -> 929c968efe70
INFO  [alembic.runtime.migration] Running upgrade 929c968efe70 -> a9c43481023c
INFO  [alembic.runtime.migration] Running upgrade a9c43481023c -> 804a3c76314c
INFO  [alembic.runtime.migration] Running upgrade 804a3c76314c -> 2b42d90729da
INFO  [alembic.runtime.migration] Running upgrade 2b42d90729da -> 62c781cb6192
INFO  [alembic.runtime.migration] Running upgrade 62c781cb6192 -> c8c222d42aa9
INFO  [alembic.runtime.migration] Running upgrade c8c222d42aa9 -> 349b6fd605a6
INFO  [alembic.runtime.migration] Running upgrade 349b6fd605a6 -> 7d32f979895f
INFO  [alembic.runtime.migration] Running upgrade 7d32f979895f -> 594422d373ee
INFO  [alembic.runtime.migration] Running upgrade 594422d373ee -> 61663558142c
INFO  [alembic.runtime.migration] Running upgrade 61663558142c -> 867d39095bf4, port forwarding
INFO  [alembic.runtime.migration] Running upgrade 867d39095bf4 -> d72db3e25539, modify uniq port forwarding
INFO  [alembic.runtime.migration] Running upgrade d72db3e25539 -> cada2437bf41
INFO  [alembic.runtime.migration] Running upgrade cada2437bf41 -> 195176fb410d, router gateway IP QoS
INFO  [alembic.runtime.migration] Running upgrade 195176fb410d -> fb0167bd9639
INFO  [alembic.runtime.migration] Running upgrade fb0167bd9639 -> 0ff9e3881597
INFO  [alembic.runtime.migration] Running upgrade 0ff9e3881597 -> 9bfad3f1e780
INFO  [alembic.runtime.migration] Running upgrade b67e765a3524 -> a84ccf28f06a
INFO  [alembic.runtime.migration] Running upgrade a84ccf28f06a -> 7d9d8eeec6ad
INFO  [alembic.runtime.migration] Running upgrade 7d9d8eeec6ad -> a8b517cff8ab
INFO  [alembic.runtime.migration] Running upgrade a8b517cff8ab -> 3b935b28e7a0
INFO  [alembic.runtime.migration] Running upgrade 3b935b28e7a0 -> b12a3ef66e62
INFO  [alembic.runtime.migration] Running upgrade b12a3ef66e62 -> 97c25b0d2353
INFO  [alembic.runtime.migration] Running upgrade 97c25b0d2353 -> 2e0d7a8a1586
INFO  [alembic.runtime.migration] Running upgrade 2e0d7a8a1586 -> 5c85685d616d
  OK
[root@controller ~]#
```

systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl enable neutron-l3-agent.service
systemctl start neutron-l3-agent.service


neutron-status upgrade check

```
[root@controller ~]# neutron-status upgrade check
+---------------------------------------------------------------------+
| Upgrade Check Results                                               |
+---------------------------------------------------------------------+
| Check: External network bridge                                      |
| Result: Success                                                     |
| Details: L3 agents are using integration bridge to connect external |
|   gateways                                                          |
+---------------------------------------------------------------------+
| Check: Worker counts configured                                     |
| Result: Warning                                                     |
| Details: The default number of workers has changed. Please see      |
|   release notes for the new values, but it is strongly              |
|   encouraged for deployers to manually set the values for           |
|   api_workers and rpc_workers.                                      |
+---------------------------------------------------------------------+
[root@controller ~]#

```

# Step:26 Dashboard – horizon installation for Stein on controller node
## https://docs.openstack.org/horizon/stein/install/

yum -y install openstack-dashboard
```
[root@controller ~]# yum -y install openstack-dashboard
...
Installed:
  openstack-dashboard.noarch 1:15.3.2-1.el7

Dependency Installed:
  XStatic-Angular-common.noarch 1:1.5.8.0-1.el7                       bootswatch-common.noarch 0:3.3.7.0-1.el7                                      bootswatch-fonts.noarch 0:3.3.7.0-1.el7
  fontawesome-fonts.noarch 0:4.4.0-1.el7                              fontawesome-fonts-web.noarch 0:4.4.0-1.el7                                    mdi-common.noarch 0:1.4.57.0-4.el7
  mdi-fonts.noarch 0:1.4.57.0-4.el7                                   openstack-dashboard-theme.noarch 1:15.3.2-1.el7                               python-XStatic-Angular-lrdragndrop.noarch 0:1.0.2.2-2.el7
  python-XStatic-Bootstrap-Datepicker.noarch 0:1.3.1.0-1.el7          python-XStatic-Hogan.noarch 0:2.0.0.2-2.el7                                   python-XStatic-JQuery-Migrate.noarch 0:1.2.1.1-2.el7
  python-XStatic-JQuery-TableSorter.noarch 0:2.14.5.1-2.el7           python-XStatic-JQuery-quicksearch.noarch 0:2.0.3.1-2.el7                      python-XStatic-Magic-Search.noarch 0:0.2.0.1-2.el7
  python-XStatic-Rickshaw.noarch 0:1.5.0.0-4.el7                      python-XStatic-Spin.noarch 0:1.2.5.2-2.el7                                    python-XStatic-jQuery.noarch 0:1.10.2.1-1.el7
  python-XStatic-jquery-ui.noarch 0:1.10.4.1-1.el7                    python-django-appconf.noarch 0:1.0.1-4.el7                                    python-django-bash-completion.noarch 0:1.11.20-1.el7
  python-django-pyscss.noarch 0:2.0.2-1.el7                           python-lesscpy.noarch 0:0.9j-4.el7                                            python-pathlib.noarch 0:1.0.1-1.el7
  python-semantic_version.noarch 0:2.4.2-2.el7                        python-versiontools.noarch 0:1.9.1-4.el7                                      python2-XStatic.noarch 0:1.0.1-8.el7
  python2-XStatic-Angular.noarch 1:1.5.8.0-1.el7                      python2-XStatic-Angular-Bootstrap.noarch 0:2.2.0.0-1.el7                      python2-XStatic-Angular-FileUpload.noarch 0:12.0.4.0-1.el7
  python2-XStatic-Angular-Gettext.noarch 0:2.3.8.0-1.el7              python2-XStatic-Angular-Schema-Form.noarch 0:0.8.13.0-0.1.pre_review.el7      python2-XStatic-Bootstrap-SCSS.noarch 0:3.3.7.1-2.el7
  python2-XStatic-D3.noarch 0:3.5.17.0-1.el7                          python2-XStatic-Font-Awesome.noarch 0:4.7.0.0-3.el7                           python2-XStatic-JSEncrypt.noarch 0:2.3.1.1-1.el7
  python2-XStatic-Jasmine.noarch 0:2.4.1.1-1.el7                      python2-XStatic-bootswatch.noarch 0:3.3.7.0-1.el7                             python2-XStatic-mdi.noarch 0:1.4.57.0-4.el7
  python2-XStatic-objectpath.noarch 0:1.2.1.0-0.1.pre_review.el7      python2-XStatic-roboto-fontface.noarch 0:0.5.0.0-1.el7                        python2-XStatic-smart-table.noarch 0:1.4.13.2-1.el7
  python2-XStatic-termjs.noarch 0:0.0.7.0-1.el7                       python2-XStatic-tv4.noarch 0:1.2.7.0-0.1.pre_review.el7                       python2-bson.x86_64 0:3.7.2-1.el7
  python2-django.noarch 0:1.11.20-1.el7                               python2-django-babel.noarch 0:0.6.2-1.el7                                     python2-django-compressor.noarch 0:2.1-5.el7
  python2-django-debreach.noarch 0:1.5.2-1.el7                        python2-django-horizon.noarch 1:15.3.2-1.el7                                  python2-pint.noarch 0:0.9-1.el7
  python2-pymongo.x86_64 0:3.7.2-1.el7                                python2-rcssmin.x86_64 0:1.0.6-2.el7                                          python2-rjsmin.x86_64 0:1.0.12-2.el7
  python2-scss.x86_64 0:1.3.4-6.el7                                   roboto-fontface-common.noarch 0:0.5.0.0-1.el7                                 roboto-fontface-fonts.noarch 0:0.5.0.0-1.el7
  web-assets-filesystem.noarch 0:5-1.el7                              xstatic-angular-bootstrap-common.noarch 0:2.2.0.0-1.el7                       xstatic-angular-fileupload-common.noarch 0:12.0.4.0-1.el7
  xstatic-angular-gettext-common.noarch 0:2.3.8.0-1.el7               xstatic-angular-schema-form-common.noarch 0:0.8.13.0-0.1.pre_review.el7       xstatic-bootstrap-scss-common.noarch 0:3.3.7.1-2.el7
  xstatic-d3-common.noarch 0:3.5.17.0-1.el7                           xstatic-jasmine-common.noarch 0:2.4.1.1-1.el7                                 xstatic-jsencrypt-common.noarch 0:2.3.1.1-1.el7
  xstatic-objectpath-common.noarch 0:1.2.1.0-0.1.pre_review.el7       xstatic-smart-table-common.noarch 0:1.4.13.2-1.el7                            xstatic-termjs-common.noarch 0:0.0.7.0-1.el7
  xstatic-tv4-common.noarch 0:1.2.7.0-0.1.pre_review.el7

Complete!
[root@controller ~]#
```
cp -pa /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.original

cat <<EOF > /etc/openstack-dashboard/local_settings
# -*- coding: utf-8 -*-
import os
from django.utils.translation import ugettext_lazy as _
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
WEBROOT = '/dashboard/'
ALLOWED_HOSTS = ['*']
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'

SHOW_OPENRC_FILE = True
SHOW_OPENSTACK_CLOUDS_YAML = True
LOCAL_PATH = '/tmp'
SECRET_KEY='0eacc6ca52e5aa0858c5'
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'controller:11211',
    }
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "controller"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_KEYSTONE_BACKEND = {
    'name': 'native',
    'can_edit_user': True,
    'can_edit_group': True,
    'can_edit_project': True,
    'can_edit_domain': True,
    'can_edit_role': True,
}
OPENSTACK_HYPERVISOR_FEATURES = {
    'can_set_mount_point': False,
    'can_set_password': False,
    'requires_keypair': False,
    'enable_quotas': True
}
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': False,
    'enable_quotas': False,
    'enable_ipv6': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': False,
    'enable_firewall': False,
    'enable_vpn': False,
    'enable_fip_topology_check': False,
    'supported_vnic_types': ['*'],
    'physical_networks': [],
}
OPENSTACK_HEAT_STACK = {
    'enable_user_pass': True,
}
IMAGE_CUSTOM_PROPERTY_TITLES = {
    "architecture": _("Architecture"),
    "kernel_id": _("Kernel ID"),
    "ramdisk_id": _("Ramdisk ID"),
    "image_state": _("Euca2ools state"),
    "project_id": _("Project ID"),
    "image_type": _("Image Type"),
}
IMAGE_RESERVED_CUSTOM_PROPERTIES = []
API_RESULT_LIMIT = 1000
API_RESULT_PAGE_SIZE = 20
SWIFT_FILE_TRANSFER_CHUNK_SIZE = 512 * 1024
INSTANCE_LOG_LENGTH = 35
DROPDOWN_MAX_ITEMS = 30
TIME_ZONE = "UTC"
POLICY_FILES_PATH = '/etc/openstack-dashboard'
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'console': {
            'format': '%(levelname)s %(name)s %(message)s'
        },
        'operation': {
            'format': '%(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'logging.NullHandler',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'console',
        },
        'operation': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'operation',
        },
    },
    'loggers': {
        'horizon': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'horizon.operation_log': {
            'handlers': ['operation'],
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_dashboard': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'novaclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'cinderclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneauth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'glanceclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'neutronclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'swiftclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'oslo_policy': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_auth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'urllib3': {
            'handlers': ['null'],
            'propagate': False,
        },
        'chardet.charsetprober': {
            'handlers': ['null'],
            'propagate': False,
        },
        'iso8601': {
            'handlers': ['null'],
            'propagate': False,
        },
        'scss': {
            'handlers': ['null'],
            'propagate': False,
        },
    },
}
SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': _('All TCP'),
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': _('All UDP'),
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': _('All ICMP'),
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}
REST_API_REQUIRED_SETTINGS = ['OPENSTACK_HYPERVISOR_FEATURES',
                              'LAUNCH_INSTANCE_DEFAULTS',
                              'OPENSTACK_IMAGE_FORMATS',
                              'OPENSTACK_KEYSTONE_BACKEND',
                              'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN',
                              'CREATE_IMAGE_DEFAULTS',
                              'ENFORCE_PASSWORD_CHECK']
ALLOWED_PRIVATE_SUBNET_CIDR = {'ipv4': [], 'ipv6': []}
EOF

sed -i "s/^WSGIProcessGroup dashboard/WSGIProcessGroup dashboard\nWSGIApplicationGroup %{GLOBAL}/" /etc/httpd/conf.d/openstack-dashboard.conf
systemctl restart httpd.service memcached.service


# Step:27 Dashboard – horizon Verify operation for Red Hat Enterprise Linux and CentOS
## http://controller/dashboard
## domain: admin
## user: admin
## password: ADMIN_PASS


# Step:28 Block Storage service – cinder installation for Stein
## https://docs.openstack.org/cinder/stein/install/
## https://docs.openstack.org/cinder/stein/install/index-rdo.html

## controller node

mysql -u root
mysql> CREATE DATABASE cinder;
mysql> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';
mysql> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';
mysql> exit

. admin-openrc

openstack user create --domain default --password CINDER_DBPASS cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s


yum -y install openstack-cinder
```
[root@controller ~]# yum -y install openstack-cinder
...
Installed:
  openstack-cinder.noarch 1:14.3.1-1.el7

Dependency Installed:
  glusterfs.x86_64 0:6.0-49.1.el7              glusterfs-api.x86_64 0:6.0-49.1.el7           glusterfs-client-xlators.x86_64 0:6.0-49.1.el7        glusterfs-libs.x86_64 0:6.0-49.1.el7
  gnutls.x86_64 0:3.3.29-9.el7_6               gperftools-libs.x86_64 0:2.6.1-1.el7          iscsi-initiator-utils.x86_64 0:6.2.0.874-22.el7_9     iscsi-initiator-utils-iscsiuio.x86_64 0:6.2.0.874-22.el7_9
  libiscsi.x86_64 0:1.9.0-7.el7                librados2.x86_64 2:14.2.20-1.el7              librbd1.x86_64 2:14.2.20-1.el7                        librdmacm.x86_64 0:22.4-6.el7_9
  lttng-ust.x86_64 0:2.10.0-1.el7              python-kmod.x86_64 0:0.9-4.el7                python-rtslib.noarch 0:2.1.74-1.el7_9                 python2-cinder.noarch 1:14.3.1-1.el7
  python2-etcd3gw.noarch 0:0.2.4-6.el7         python2-gflags.noarch 0:2.0-5.el7             python2-google-api-client.noarch 0:1.4.2-4.el7        python2-oauth2client.noarch 0:1.5.2-3.el7.1
  python2-uri-templates.noarch 0:0.6-5.el7     qemu-img-ev.x86_64 10:2.12.0-44.1.el7_8.1     trousers.x86_64 0:0.3.14-2.el7                        userspace-rcu.x86_64 0:0.10.0-3.el7

Complete!
[root@controller ~]# ls -al /etc/cinder/cinder.conf
-rw-r----- 1 root cinder 175348 Nov 12  2020 /etc/cinder/cinder.conf
[root@controller ~]# egrep -v "^#|^$"  /etc/cinder/cinder.conf
[DEFAULT]
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
[nova]
[oslo_concurrency]
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
[root@controller ~]#
```

cp -pa /etc/cinder/cinder.conf /etc/cinder/cinder.conf.original

cat <<EOF > /etc/cinder/cinder.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
my_ip = 192.168.137.11
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_DBPASS
[nova]
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
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

su -s /bin/sh -c "cinder-manage db sync" cinder
```
[root@controller ~]# su -s /bin/sh -c "cinder-manage db sync" cinder
Deprecated: Option "logdir" from group "DEFAULT" is deprecated. Use option "log-dir" from group "DEFAULT".
[root@controller ~]#
```


sed -i "s/^\[cinder\]/\[cinder\]\nos_region_name = RegionOne/" /etc/nova/nova.conf

```
[root@controller ~]# grep -A4 "^\[cinder\]" /etc/nova/nova.conf | sed -e "s/^\[cinder\]/\[cinder\]\nos_region_name = RegionOne/"
[cinder]
os_region_name = RegionOne
[compute]
[conductor]
[console]
[consoleauth]
[root@controller ~]# sed -i "s/^\[cinder\]/\[cinder\]\nos_region_name = RegionOne/" /etc/nova/nova.conf
[root@controller ~]# grep -A4 "^\[cinder\]" /etc/nova/nova.conf
[cinder]
os_region_name = RegionOne
[compute]
[conductor]
[console]
[root@controller ~]#
```
systemctl restart openstack-nova-api.service

systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service

cinder-status upgrade check
```
[root@controller ~]# cinder-status upgrade check
Deprecated: Option "logdir" from group "DEFAULT" is deprecated. Use option "log-dir" from group "DEFAULT".
+----------------------------+
| Upgrade Check Results      |
+----------------------------+
| Check: Backup Driver Path  |
| Result: Success            |
| Details: None              |
+----------------------------+
| Check: Use of Policy File  |
| Result: Success            |
| Details: None              |
+----------------------------+
| Check: Windows Driver Path |
| Result: Success            |
| Details: None              |
+----------------------------+
| Check: Removed Drivers     |
| Result: Success            |
| Details: None              |
+----------------------------+
| Check: Service UUIDs       |
| Result: Success            |
| Details: None              |
+----------------------------+
| Check: Attachment specs    |
| Result: Success            |
| Details: None              |
+----------------------------+
[root@controller ~]#
```




# Step:29 Block Storage service – cinder Install and configure a storage node
## https://docs.openstack.org/cinder/stein/install/cinder-storage-install-rdo.html

**[storage node]**
yum -y install lvm2 device-mapper-persistent-data

```
[root@block1 ~]# yum -y install lvm2 device-mapper-persistent-data
...
Package 7:lvm2-2.02.187-6.el7_9.5.x86_64 already installed and latest version
Package device-mapper-persistent-data-0.8.5-3.el7_9.2.x86_64 already installed and latest version
Nothing to do
[root@block1 ~]#
```
systemctl enable lvm2-lvmetad.service
systemctl restart lvm2-lvmetad.service


pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
sed -i 's/# Configuration option devices\/global_filter\./filter = \[ "a\/sdb\/", "r\/\.\*\/"\]\n\n        # Configuration option devices\/global_filter\./' /etc/lvm/lvm.conf



```
[root@block1 ~]# fdisk -l

Disk /dev/sdb: 136.4 GB, 136365211648 bytes, 266338304 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/sda: 136.4 GB, 136365211648 bytes, 266338304 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disk label type: dos
Disk identifier: 0x000c3ddc

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048     2099199     1048576   83  Linux
/dev/sda2         2099200   266338303   132119552   8e  Linux LVM

Disk /dev/mapper/centos-root: 133.1 GB, 133135597568 bytes, 260030464 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos-swap: 2147 MB, 2147483648 bytes, 4194304 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes

[root@block1 ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@block1 ~]# vgcreate cinder-volumes /dev/sdb
  Volume group "cinder-volumes" successfully created
[root@block1 ~]# sed -i 's/# Configuration option devices\/global_filter\./filter = \[ "a\/sdb\/", "r\/\.\*\/"\]\n\n        # Configuration option devices\/global_filter\./' /etc/lvm/lvm.conf
```


yum -y install openstack-cinder targetcli python-keystone
```
[root@block1 ~]# yum -y install openstack-cinder targetcli python-keystone
...
Installed:
  openstack-cinder.noarch 1:14.3.1-1.el7              python2-keystone.noarch 1:15.0.1-1.el7
  targetcli.noarch 0:2.1.53-1.el7_9

Dependency Installed:
  adobe-mappings-cmap.noarch 0:20171205-3.el7
  adobe-mappings-cmap-deprecated.noarch 0:20171205-3.el7
  adobe-mappings-pdf.noarch 0:20180407-1.el7
  atk.x86_64 0:2.28.1-2.el7
  atlas.x86_64 0:3.10.1-12.el7
  avahi-libs.x86_64 0:0.6.31-20.el7
  blosc.x86_64 0:1.11.1-3.el7
  cairo.x86_64 0:1.15.12-4.el7
  cups-libs.x86_64 1:1.6.3-51.el7
  dejavu-fonts-common.noarch 0:2.33-6.el7
  dejavu-sans-fonts.noarch 0:2.33-6.el7
  desktop-file-utils.x86_64 0:0.23-2.el7
  device-mapper-multipath.x86_64 0:0.4.9-135.el7_9
  device-mapper-multipath-libs.x86_64 0:0.4.9-135.el7_9
  emacs-filesystem.noarch 1:24.3-23.el7
  fontconfig.x86_64 0:2.13.0-4.3.el7
  fontpackages-filesystem.noarch 0:1.44-8.el7
  fribidi.x86_64 0:1.0.2-1.el7_7.1
  gd.x86_64 0:2.0.35-27.el7_9
  gdk-pixbuf2.x86_64 0:2.36.12-3.el7
  glusterfs.x86_64 0:6.0-49.1.el7
  glusterfs-api.x86_64 0:6.0-49.1.el7
  glusterfs-client-xlators.x86_64 0:6.0-49.1.el7
  glusterfs-libs.x86_64 0:6.0-49.1.el7
  gnutls.x86_64 0:3.3.29-9.el7_6
  gperftools-libs.x86_64 0:2.6.1-1.el7
  graphite2.x86_64 0:1.3.10-1.el7_3
  graphviz.x86_64 0:2.30.1-22.el7
  graphviz-python.x86_64 0:2.30.1-22.el7
  gtk-update-icon-cache.x86_64 0:3.22.30-6.el7
  gtk2.x86_64 0:2.24.31-1.el7
  harfbuzz.x86_64 0:1.7.5-2.el7
  hdf5.x86_64 0:1.8.13-7.el7
  hicolor-icon-theme.noarch 0:0.12-7.el7
  iscsi-initiator-utils.x86_64 0:6.2.0.874-22.el7_9
  iscsi-initiator-utils-iscsiuio.x86_64 0:6.2.0.874-22.el7_9
  jasper-libs.x86_64 0:1.900.1-33.el7
  jbigkit-libs.x86_64 0:2.0-11.el7
  lcms2.x86_64 0:2.6-3.el7
  libICE.x86_64 0:1.0.9-9.el7
  libSM.x86_64 0:1.2.2-2.el7
  libX11.x86_64 0:1.6.7-4.el7_9
  libX11-common.noarch 0:1.6.7-4.el7_9
  libXau.x86_64 0:1.0.8-2.1.el7
  libXaw.x86_64 0:1.0.13-4.el7
  libXcomposite.x86_64 0:0.4.4-4.1.el7
  libXcursor.x86_64 0:1.1.15-1.el7
  libXdamage.x86_64 0:1.1.4-4.1.el7
  libXext.x86_64 0:1.3.3-3.el7
  libXfixes.x86_64 0:5.0.3-1.el7
  libXft.x86_64 0:2.3.2-2.el7
  libXi.x86_64 0:1.7.9-1.el7
  libXinerama.x86_64 0:1.1.3-2.1.el7
  libXmu.x86_64 0:1.1.2-2.el7
  libXpm.x86_64 0:3.5.12-1.el7
  libXrandr.x86_64 0:1.5.1-2.el7
  libXrender.x86_64 0:0.9.10-1.el7
  libXt.x86_64 0:1.1.5-3.el7
  libXxf86misc.x86_64 0:1.0.3-7.1.el7
  libXxf86vm.x86_64 0:1.1.4-1.el7
  libfontenc.x86_64 0:1.1.3-3.el7
  libgfortran.x86_64 0:4.8.5-44.el7
  libglvnd.x86_64 1:1.0.1-0.8.git5baa1e5.el7
  libglvnd-egl.x86_64 1:1.0.1-0.8.git5baa1e5.el7
  libglvnd-glx.x86_64 1:1.0.1-0.8.git5baa1e5.el7
  libgs.x86_64 0:9.25-5.el7
  libibverbs.x86_64 0:22.4-6.el7_9
  libimagequant.x86_64 0:2.8.2-2.el7
  libiscsi.x86_64 0:1.9.0-7.el7
  libjpeg-turbo.x86_64 0:1.2.90-8.el7
  libnl.x86_64 0:1.1.4-3.el7
  libpaper.x86_64 0:1.1.24-9.el7
  libqhull.x86_64 0:2015.2-1.el7
  libquadmath.x86_64 0:4.8.5-44.el7
  librados2.x86_64 2:14.2.20-1.el7
  librbd1.x86_64 2:14.2.20-1.el7
  librdmacm.x86_64 0:22.4-6.el7_9
  librsvg2.x86_64 0:2.40.20-1.el7
  libsodium.x86_64 0:1.0.18-0.el7
  libthai.x86_64 0:0.1.14-9.el7
  libtiff.x86_64 0:4.0.3-35.el7
  libtomcrypt.x86_64 0:1.17-26.el7
  libtommath.x86_64 0:0.42.0-6.el7
  libtool-ltdl.x86_64 0:2.4.2-22.el7_3
  libwayland-client.x86_64 0:1.15.0-1.el7
  libwayland-server.x86_64 0:1.15.0-1.el7
  libwebp.x86_64 0:0.3.0-10.el7_9
  libxcb.x86_64 0:1.13-1.el7
  libxshmfence.x86_64 0:1.2-1.el7
  libxslt.x86_64 0:1.1.28-6.el7
  lttng-ust.x86_64 0:2.10.0-1.el7
  mesa-libEGL.x86_64 0:18.3.4-12.el7_9
  mesa-libGL.x86_64 0:18.3.4-12.el7_9
  mesa-libgbm.x86_64 0:18.3.4-12.el7_9
  mesa-libglapi.x86_64 0:18.3.4-12.el7_9
  nettle.x86_64 0:2.7.1-9.el7_9
  openjpeg2.x86_64 0:2.3.1-3.el7_7
  pango.x86_64 0:1.42.4-4.el7_7
  pciutils.x86_64 0:3.5.1-3.el7
  pixman.x86_64 0:0.34.0-1.el7
  python-Bottleneck.x86_64 0:0.6.0-4.el7
  python-aniso8601.noarch 0:0.82-3.el7
  python-click.noarch 0:6.3-1.el7
  python-configshell.noarch 1:1.1.26-1.el7
  python-dns.noarch 0:1.15.0-5.el7
  python-editor.noarch 0:0.4-4.el7
  python-ethtool.x86_64 0:0.8-8.el7
  python-httplib2.noarch 0:0.9.2-1.el7
  python-jwcrypto.noarch 0:0.4.2-1.el7
  python-kazoo.noarch 0:2.2.1-1.el7
  python-kmod.x86_64 0:0.9-4.el7
  python-lxml.x86_64 0:3.2.1-4.el7
  python-matplotlib-data.noarch 0:2.0.0-3.el7
  python-matplotlib-data-fonts.noarch 0:2.0.0-3.el7
  python-memcached.noarch 0:1.58-1.el7
  python-migrate.noarch 0:0.11.0-1.el7
  python-nose.noarch 0:1.3.7-7.el7
  python-oslo-cache-lang.noarch 0:1.33.3-1.el7
  python-oslo-concurrency-lang.noarch 0:3.29.1-1.el7
  python-oslo-db-lang.noarch 0:4.45.0-1.el7
  python-oslo-middleware-lang.noarch 0:3.37.1-1.el7
  python-oslo-policy-lang.noarch 0:2.1.3-1.el7
  python-oslo-privsep-lang.noarch 0:1.32.2-1.el7
  python-oslo-versionedobjects-lang.noarch 0:1.35.1-1.el7
  python-oslo-vmware-lang.noarch 0:2.32.2-1.el7
  python-paste-deploy.noarch 0:1.5.2-6.el7
  python-pycadf-common.noarch 0:2.9.0-1.el7
  python-pyngus.noarch 0:2.0.3-3.el7
  python-retrying.noarch 0:1.2.3-4.el7
  python-routes.noarch 0:2.4.1-1.el7
  python-rtslib.noarch 0:2.1.74-1.el7_9
  python-sqlparse.noarch 0:0.1.18-5.el7
  python-urwid.x86_64 0:1.1.1-3.el7
  python2-PyMySQL.noarch 0:0.9.2-2.el7
  python2-alembic.noarch 0:1.0.7-1.el7
  python2-amqp.noarch 0:2.4.1-1.el7
  python2-automaton.noarch 0:1.16.0-1.el7
  python2-barbicanclient.noarch 0:4.8.1-1.el7
  python2-bcrypt.x86_64 0:3.1.6-1.el7
  python2-cachetools.noarch 0:3.1.0-1.el7
  python2-castellan.noarch 0:1.2.3-1.el7
  python2-cinder.noarch 1:14.3.1-1.el7
  python2-crypto.x86_64 0:2.6.1-15.el7
  python2-cursive.noarch 0:0.2.2-1.el7
  python2-cycler.noarch 0:0.10.0-2.el7
  python2-defusedxml.noarch 0:0.5.0-2.el7
  python2-etcd3gw.noarch 0:0.2.4-6.el7
  python2-eventlet.noarch 0:0.24.1-3.el7
  python2-fasteners.noarch 0:0.14.1-6.el7
  python2-flask.noarch 1:1.0.2-1.el7
  python2-flask-restful.noarch 0:0.3.6-7.el7
  python2-functools32.noarch 0:3.2.3.2-1.el7
  python2-future.noarch 0:0.16.0-4.el7
  python2-futurist.noarch 0:1.8.1-1.el7
  python2-gflags.noarch 0:2.0-5.el7
  python2-google-api-client.noarch 0:1.4.2-4.el7
  python2-greenlet.x86_64 0:0.4.12-1.el7
  python2-itsdangerous.noarch 0:0.24-14.el7
  python2-jinja2.noarch 0:2.10.1-1.el7
  python2-jwt.noarch 0:1.6.1-1.el7
  python2-keystonemiddleware.noarch 0:6.0.1-1.el7
  python2-kombu.noarch 1:4.2.2-1.el7
  python2-ldap.x86_64 0:3.1.0-1.el7
  python2-ldappool.noarch 0:2.4.0-2.el7
  python2-matplotlib.x86_64 0:2.0.0-3.el7
  python2-matplotlib-tk.x86_64 0:2.0.0-3.el7
  python2-networkx.noarch 0:2.2-3.el7
  python2-numexpr.x86_64 0:2.6.1-3.el7
  python2-numpy.x86_64 1:1.14.5-1.el7
  python2-oauth2client.noarch 0:1.5.2-3.el7.1
  python2-oauthlib.noarch 0:2.0.1-8.el7
  python2-olefile.noarch 0:0.44-1.el7
  python2-os-brick.noarch 0:2.8.7-1.el7
  python2-os-win.noarch 0:4.2.1-1.el7
  python2-oslo-cache.noarch 0:1.33.3-1.el7
  python2-oslo-concurrency.noarch 0:3.29.1-1.el7
  python2-oslo-db.noarch 0:4.45.0-1.el7
  python2-oslo-messaging.noarch 0:9.5.2-1.el7
  python2-oslo-middleware.noarch 0:3.37.1-1.el7
  python2-oslo-policy.noarch 0:2.1.3-1.el7
  python2-oslo-privsep.noarch 0:1.32.2-1.el7
  python2-oslo-reports.noarch 0:1.29.2-1.el7
  python2-oslo-rootwrap.noarch 0:5.15.3-1.el7
  python2-oslo-service.noarch 0:1.38.1-1.el7
  python2-oslo-upgradecheck.noarch 0:0.2.1-1.el7
  python2-oslo-versionedobjects.noarch 0:1.35.1-1.el7
  python2-oslo-vmware.noarch 0:2.32.2-1.el7
  python2-osprofiler.noarch 0:2.6.1-1.el7
  python2-pandas.x86_64 0:0.19.1-2.el7.2
  python2-paramiko.noarch 0:2.4.2-2.el7
  python2-passlib.noarch 0:1.7.0-4.el7
  python2-pillow.x86_64 0:5.4.1-3.el7
  python2-psutil.x86_64 0:5.5.1-1.el7
  python2-pyasn1.noarch 0:0.3.7-6.el7
  python2-pyasn1-modules.noarch 0:0.3.7-6.el7
  python2-pycadf.noarch 0:2.9.0-1.el7
  python2-pydot.noarch 0:1.4.1-1.el7
  python2-pynacl.x86_64 0:1.3.0-1.el7
  python2-pysaml2.noarch 0:4.6.5-1.el7
  python2-qpid-proton.x86_64 0:0.22.0-1.el7
  python2-redis.noarch 0:3.1.0-1.el7
  python2-rsa.noarch 0:3.3-2.el7
  python2-scipy.x86_64 0:0.18.0-3.el7
  python2-scrypt.x86_64 0:0.8.0-2.el7
  python2-sqlalchemy.x86_64 0:1.2.17-2.el7
  python2-statsd.noarch 0:3.2.1-5.el7
  python2-suds.noarch 0:0.7-0.4.94664ddd46a6.el7
  python2-swiftclient.noarch 0:3.7.1-1.el7
  python2-tables.x86_64 0:3.3.0-4.el7
  python2-taskflow.noarch 0:3.5.0-1.el7
  python2-tenacity.noarch 0:5.0.2-2.el7
  python2-tooz.noarch 0:1.64.3-1.el7
  python2-uri-templates.noarch 0:0.6-5.el7
  python2-vine.noarch 0:1.2.0-2.el7
  python2-voluptuous.noarch 0:0.10.5-2.el7
  python2-webob.noarch 0:1.8.5-1.el7
  python2-werkzeug.noarch 0:0.14.1-3.el7
  python2-yappi.x86_64 0:1.0-1.el7
  python2-zake.noarch 0:0.2.2-2.el7
  qemu-img-ev.x86_64 10:2.12.0-44.1.el7_8.1
  qpid-proton-c.x86_64 0:0.22.0-1.el7
  rdma-core.x86_64 0:22.4-6.el7_9
  sg3_utils.x86_64 1:1.37-19.el7
  sg3_utils-libs.x86_64 1:1.37-19.el7
  sysfsutils.x86_64 0:2.1.0-16.el7
  t1lib.x86_64 0:5.1.2-14.el7
  tcl.x86_64 1:8.5.13-8.el7
  texlive-base.noarch 2:2012-45.20130427_r30134.el7
  texlive-dvipng.noarch 2:svn26689.1.14-45.el7
  texlive-dvipng-bin.x86_64 2:svn26509.0-45.20130427_r30134.el7
  texlive-kpathsea.noarch 2:svn28792.0-45.el7
  texlive-kpathsea-bin.x86_64 2:svn27347.0-45.20130427_r30134.el7
  texlive-kpathsea-lib.x86_64 2:2012-45.20130427_r30134.el7
  tix.x86_64 1:8.4.3-12.el7
  tk.x86_64 1:8.5.13-6.el7
  tkinter.x86_64 0:2.7.5-90.el7
  trousers.x86_64 0:0.3.14-2.el7
  urw-base35-bookman-fonts.noarch 0:20170801-10.el7
  urw-base35-c059-fonts.noarch 0:20170801-10.el7
  urw-base35-d050000l-fonts.noarch 0:20170801-10.el7
  urw-base35-fonts.noarch 0:20170801-10.el7
  urw-base35-fonts-common.noarch 0:20170801-10.el7
  urw-base35-gothic-fonts.noarch 0:20170801-10.el7
  urw-base35-nimbus-mono-ps-fonts.noarch 0:20170801-10.el7
  urw-base35-nimbus-roman-fonts.noarch 0:20170801-10.el7
  urw-base35-nimbus-sans-fonts.noarch 0:20170801-10.el7
  urw-base35-p052-fonts.noarch 0:20170801-10.el7
  urw-base35-standard-symbols-ps-fonts.noarch 0:20170801-10.el7
  urw-base35-z003-fonts.noarch 0:20170801-10.el7
  userspace-rcu.x86_64 0:0.10.0-3.el7
  xdg-utils.noarch 0:1.1.0-0.17.20120809git.el7
  xorg-x11-font-utils.x86_64 1:7.5-21.el7
  xorg-x11-server-utils.x86_64 0:7.7-20.el7

Complete!
[root@block1 ~]# ls -al /etc/cinder/cinder.conf
-rw-r----- 1 root cinder 175348 Nov 12  2020 /etc/cinder/cinder.conf
[root@block1 ~]# egrep -v "^#|^$"  /etc/cinder/cinder.conf
[DEFAULT]
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
[nova]
[oslo_concurrency]
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
[root@block1 ~]#
```

cp -pa /etc/cinder/cinder.conf /etc/cinder/cinder.conf.original
cat <<EOF > /etc/cinder/cinder.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
my_ip = 192.168.137.41
enabled_backends = lvm
glance_api_servers = http://controller:9292
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_DBPASS
[nova]
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
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
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = lioadm
EOF


systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service

**[control node]**

openstack volume service list
```
[root@controller ~]# openstack volume service list
+------------------+------------+------+---------+-------+----------------------------+
| Binary           | Host       | Zone | Status  | State | Updated At                 |
+------------------+------------+------+---------+-------+----------------------------+
| cinder-scheduler | controller | nova | enabled | up    | 2022-03-22T06:41:12.000000 |
| cinder-volume    | block1@lvm | nova | enabled | up    | 2022-03-22T06:41:14.000000 |
+------------------+------------+------+---------+-------+----------------------------+
[root@controller ~]# cinder get-capabilities block1@lvm
+---------------------+---------------------------------------+
| Volume stats        | Value                                 |
+---------------------+---------------------------------------+
| description         | None                                  |
| display_name        | None                                  |
| driver_version      | 3.0.0                                 |
| namespace           | OS::Storage::Capabilities::block1@lvm |
| pool_name           | None                                  |
| replication_targets | []                                    |
| storage_protocol    | iSCSI                                 |
| vendor_name         | Open Source                           |
| visibility          | None                                  |
| volume_backend_name | LVM                                   |
+---------------------+---------------------------------------+
+---------------------+---------------------------------------+
| Backend properties  | Value                                 |
+---------------------+---------------------------------------+
| compression         | description : Enables compression.    |
|                     | title : Compression                   |
|                     | type : boolean                        |
| qos                 | description : Enables QoS.            |
|                     | title : QoS                           |
|                     | type : boolean                        |
| replication_enabled | description : Enables replication.    |
|                     | title : Replication                   |
|                     | type : boolean                        |
| thin_provisioning   | description : Sets thin provisioning. |
|                     | title : Thin Provisioning             |
|                     | type : boolean                        |
+---------------------+---------------------------------------+
[root@controller ~]#
```



# Step:30 launch-instance
## https://docs.openstack.org/install-guide/launch-instance.html#create-virtual-networks

. admin-openrc
openstack network create  --share --external --provider-physical-network provider --provider-network-type flat provider
openstack subnet create --network provider --allocation-pool start=192.168.137.200,end=192.168.137.250 --dns-nameserver 8.8.4.4 --gateway 192.168.137.1 --subnet-range 192.168.137.0/24 provider
  
. demo-openrc
openstack network create selfservice
openstack subnet create --network selfservice --dns-nameserver 8.8.8.8 --gateway 172.16.1.1 --subnet-range 172.16.1.0/24 selfservice

. demo-openrc
openstack router create router
openstack router add subnet router selfservice
openstack router set router --external-gateway provider

. admin-openrc
ip netns
openstack port list --router router







openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
. demo-openrc
ssh-keygen -q -N ""
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
```
+-------+-------------------------------------------------+
| Name  | Fingerprint                                     |
+-------+-------------------------------------------------+
| mykey | ef:f0:d1:c6:d0:88:ca:a0:57:91:78:9d:d8:d7:8e:d4 |
+-------+-------------------------------------------------+
[root@controller ~]#
```
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default



openstack flavor list


openstack server create --flavor m1.nano --image cirros --nic net-id=PROVIDER_NET_ID --security-group default --key-name mykey provider-instance

























https://docs.openstack.org/install-guide/openstack-services.html

Minimal deployment for Stein

Identity service – keystone installation for Stein -- ok
Image service – glance installation for Stein  -- ok
Placement service – placement installation for Stein  -- ok
Compute service – nova installation for Stein -- ok
Networking service – neutron installation for Stein -- ok
Dashboard – horizon installation for Stein -- ok
Block Storage service – cinder installation for Stein


## ====================================================================================================================================
## ====================================================================================================================================
## ====================================================================================================================================
## 이슈 해결

### public endpoint for image service not found

* 증상: glance 설치 후 image 리스트가 안보임
* 원인: glance-api 서비스 endpoint 등록이 되어 있지 않음
```
[root@controller ~]# opentopenstack endpoint list
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                        |
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
| 91727549ee26445080fe63863ccf2ee9 | RegionOne | keystone     | identity     | True    | internal  | http://controller:5000/v3/ |
| accc6fc810764e73aac3ed61e5366ad5 | RegionOne | keystone     | identity     | True    | public    | http://controller:5000/v3/ |
| bb0de8bb6d064c0283a95d438a7d11f4 | RegionOne | keystone     | identity     | True    | admin     | http://controller:5000/v3/ |
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
```
* 조치: endpoint 등록
```
# openstack role add --project service --user glance admin
# openstack service create --name glance --description "OpenStack Image service" image
# openstack endpoint create --region RegionOne image public http://controller:9292
# openstack endpoint create --region RegionOne image internal http://controller:9292
# openstack endpoint create --region RegionOne image admin http://controller:9292
[root@controller ~]# openstack endpoint list
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                        |
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
| 06ae5b79252c4120aefafdf8b5e7f554 | RegionOne | glance       | image        | True    | admin     | http://controller:9292     |
| 42800b34edf24334b67dffc1302a83c5 | RegionOne | glance       | image        | True    | public    | http://controller:9292     |
| 91727549ee26445080fe63863ccf2ee9 | RegionOne | keystone     | identity     | True    | internal  | http://controller:5000/v3/ |
| 9f283b497dd24490b3c37600c81933b9 | RegionOne | glance       | image        | True    | internal  | http://controller:9292     |
| accc6fc810764e73aac3ed61e5366ad5 | RegionOne | keystone     | identity     | True    | public    | http://controller:5000/v3/ |
| bb0de8bb6d064c0283a95d438a7d11f4 | RegionOne | keystone     | identity     | True    | admin     | http://controller:5000/v3/ |
+----------------------------------+-----------+--------------+--------------+---------+-----------+----------------------------+
```

### openstack image list - Unauthorized (HTTP 401)

* 증상: glance image 리스트를 불러오면 인증이 실패했다고 나옴
```
[root@controller ~]# openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

HTTP 401 Unauthorized: This server could not verify that you are authorized to access the document you requested. Either you supplied the wrong credentials (e.g., bad password), or your browser does not understand how to supply the credentials required.
[root@controller ~]# 

- /var/log/glance/api.log
2022-03-18 12:57:20.638 18705 INFO glance.common.wsgi [-] Starting 1 workers
2022-03-18 12:57:20.639 18705 INFO glance.common.wsgi [-] Started child 18730
2022-03-18 12:57:20.643 18730 INFO eventlet.wsgi.server [-] (18730) wsgi starting up on http://0.0.0.0:9292
2022-03-18 12:57:30.508 18730 WARNING keystonemiddleware.auth_token [-] Identity response: {"error":{"code":401,"message":"The request you have made requires authentication.","title":"Unauthorized"}}
: Unauthorized: The request you have made requires authentication. (HTTP 401) (Request-ID: req-b127deed-fcd6-4d87-a8d3-b40ba2c74deb)
2022-03-18 12:57:30.918 18730 WARNING keystonemiddleware.auth_token [-] Identity response: {"error":{"code":401,"message":"The request you have made requires authentication.","title":"Unauthorized"}}
: Unauthorized: The request you have made requires authentication. (HTTP 401) (Request-ID: req-f572ca02-85f7-4694-a64f-228461665c96)
2022-03-18 12:57:30.918 18730 CRITICAL keystonemiddleware.auth_token [-] Unable to validate token: Identity server rejected authorization necessary to fetch token data: ServiceError: Identity server rejected authorization necessary to fetch token data
2022-03-18 12:57:30.920 18730 INFO eventlet.wsgi.server [-] 192.168.137.11 - - [18/Mar/2022 12:57:30] "GET /v2/schemas/image HTTP/1.1" 401 566 0.827830

[root@controller ~]# egrep -v "^#|^$" /etc/glance/glance-api.conf
[DEFAULT]
show_image_direct_url = True
[cinder]
[cors]
[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
[file]
filesystem_store_datadir = /var/lib/glance/images/
[glance.store.http.store]
[glance.store.rbd.store]
[glance.store.sheepdog.store]
[glance.store.swift.store]
[glance.store.vmware_datastore.store]
[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images
[image_format]
[keystone_authtoken]
www_authenticate_uri  = http://controller:5000
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
service_token_roles_required = true
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
flavor = keystone
[profiler]
[store_type_location_strategy]
[task]
[taskflow_executor]
[root@controller ~]# mysql -u glance -pGLANCE_PASS
ERROR 1045 (28000): Access denied for user 'glance'@'localhost' (using password: YES)
```
* 원인: mysql glance 디비 접속을 위한 password로 접속되지 않음
* 조치: /etc/glance/glance-api.conf 파일에서 password를 GLANCE_DBPASS로 수정


### nova-status upgrade check Forbidden: Forbidden (HTTP 403)

* 증상: nova 설치 후 nova-status upgrade check할 때 Forbidden 에러 발생
```
[root@controller ~]# . admin-openrc
[root@controller ~]# nova-status upgrade check
Error:
Traceback (most recent call last):
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 515, in main
    ret = fn(*fn_args, **fn_kwargs)
  File "/usr/lib/python2.7/site-packages/oslo_upgradecheck/upgradecheck.py", line 99, in check
    result = func(self)
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 160, in _check_placement
    versions = self._placement_get("/")
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 150, in _placement_get
    return client.get(path, raise_exc=True).json()
  File "/usr/lib/python2.7/site-packages/keystoneauth1/adapter.py", line 375, in get
    return self.request(url, 'GET', **kwargs)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/adapter.py", line 237, in request
    return self.session.request(url, method, **kwargs)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/session.py", line 890, in request
    raise exceptions.from_response(resp, method, url)
Forbidden: Forbidden (HTTP 403)
```
* 원인: httpd 서비스에 placement-api 설정이 되어 있지 않음
* 조치: 00-placement-api.conf 추가후 httpd 재시작
```
[root@controller ~]# vim /etc/httpd/conf.d/00-placement-api.conf
Listen 8778

<VirtualHost *:8778>
  WSGIProcessGroup placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  WSGIDaemonProcess placement-api processes=3 threads=1 user=placement group=placement
  WSGIScriptAlias / /usr/bin/placement-api
  <Directory /usr/bin>
    Require all denied
    <Files "placement-api">
      <RequireAll>
        Require all granted
        Require not env blockAccess
      </RequireAll>
    </Files>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
  </Directory>
  <IfVersion >= 2.4>
    ErrorLogFormat "%M"
  </IfVersion>
  ErrorLog /var/log/placement/placement-api.log
  #SSLEngine On
  #SSLCertificateFile ...
  #SSLCertificateKeyFile ...
</VirtualHost>

Alias /placement-api /usr/bin/placement-api
<Location /placement-api>
  SetHandler wsgi-script
  Options +ExecCGI
  WSGIProcessGroup placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
</Location>
[root@controller ~]# systemctl restart httpd
```

### nova-status upgrade check Forbidden: InternalServerError: Internal Server Error (HTTP 500)

* 증상: nova 설치 후 nova-status upgrade check할 때 Internal Server Error (HTTP 500) 에러 발생
```
[root@controller ~]# nova-status upgrade check
Error:
Traceback (most recent call last):
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 515, in main
    ret = fn(*fn_args, **fn_kwargs)
  File "/usr/lib/python2.7/site-packages/oslo_upgradecheck/upgradecheck.py", line 99, in check
    result = func(self)
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 160, in _check_placement
    versions = self._placement_get("/")
  File "/usr/lib/python2.7/site-packages/nova/cmd/status.py", line 150, in _placement_get
    return client.get(path, raise_exc=True).json()
  File "/usr/lib/python2.7/site-packages/keystoneauth1/adapter.py", line 375, in get
    return self.request(url, 'GET', **kwargs)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/adapter.py", line 237, in request
    return self.session.request(url, method, **kwargs)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/session.py", line 890, in request
    raise exceptions.from_response(resp, method, url)
InternalServerError: Internal Server Error (HTTP 500)

[root@controller ~]#tail /var/log/placement/placement-api.log
2022-03-21 12:13:57.110 5562 WARNING placement.db_api [-] TransactionFactory already started, not reconfiguring.\x1b[00m
2022-03-21 12:13:57.119 5562 WARNING keystonemiddleware.auth_token [-] AuthToken middleware is set with keystone_authtoken.service_token_roles_required set to False. This is backwards compatible but deprecated behaviour. Please set this to True.\x1b[00m
mod_wsgi (pid=5562): Target WSGI script '/usr/bin/placement-api' cannot be loaded as Python module.
mod_wsgi (pid=5562): Exception occurred processing WSGI script '/usr/bin/placement-api'.
Traceback (most recent call last):
  File "/usr/bin/placement-api", line 52, in <module>
    application = init_application()
  File "/usr/lib/python2.7/site-packages/placement/wsgi.py", line 150, in init_application
    return deploy.loadapp(config)
  File "/usr/lib/python2.7/site-packages/placement/deploy.py", line 132, in loadapp
    application = deploy(config)
  File "/usr/lib/python2.7/site-packages/placement/deploy.py", line 93, in deploy
    application = middleware(application)
  File "/usr/lib/python2.7/site-packages/placement/auth.py", line 101, in auth_filter
    return PlacementAuthProtocol(app, conf)
  File "/usr/lib/python2.7/site-packages/placement/auth.py", line 86, in __init__
    super(PlacementAuthProtocol, self).__init__(app, conf)
  File "/usr/lib/python2.7/site-packages/keystonemiddleware/auth_token/__init__.py", line 574, in __init__
    self._auth = self._create_auth_plugin()
  File "/usr/lib/python2.7/site-packages/keystonemiddleware/auth_token/__init__.py", line 889, in _create_auth_plugin
    return plugin_loader.load_from_options_getter(getter)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/loading/base.py", line 187, in load_from_options_getter
    return self.load_from_options(**kwargs)
  File "/usr/lib/python2.7/site-packages/keystoneauth1/loading/base.py", line 162, in load_from_options
    raise exceptions.MissingRequiredOptions(missing_required)
MissingRequiredOptions: Auth plugin requires parameters which were not given: auth_url
[root@controller ~]# nova-status upgrade check
Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.
+--------------------------------------------------+
| Upgrade Check Results                            |
+--------------------------------------------------+
| Check: Cells v2                                  |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Placement API                             |
| Result: Failure                                  |
| Details: Discovery for placement API URI failed. |
+--------------------------------------------------+
| Check: Ironic Flavor Migration                   |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Request Spec Migration                    |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Console Auths                             |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
```
* 원인: nova.conf 에 [keystone_authtoken]에 auth_url 설정이 없음
```
[root@controller ~]# grep -A11 keystone_authtoken /etc/nova/nova.conf
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_DBPASS
[libvirt]
[metrics]
```
* 조치
   * /etc/nova/nova.conf 에 [keystone_authtoken]에 auth_url 설정 추가
   * /etc/placement/placement.conf에 [keystone_authtoken]에 auth_url 설정 추가
```
[root@controller ~]# grep -A12 keystone_authtoken /etc/nova/nova.conf
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_DBPASS
[libvirt]
[metrics]
[root@controller ~]# grep -A12 keystone_authtoken /etc/placement/placement.conf
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_DBPASS
[placement]
[placement_database]
[root@controller ~]#

```
* 확인
```
[root@controller ~]# nova-status upgrade check
+--------------------------------+
| Upgrade Check Results          |
+--------------------------------+
| Check: Cells v2                |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Placement API           |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Ironic Flavor Migration |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Request Spec Migration  |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Console Auths           |
| Result: Success                |
| Details: None                  |
+--------------------------------+

```
* 참고
   * https://zhuanlan.zhihu.com/p/52795181
   * https://hpux-interview-questions.blogspot.com/2016/07/openstack-mitaka-issue-starting-nova.html
   * https://www.codedevlib.com/article/openstack-about-the-role-of-adminopenrcsh-queens-version-50111



### openstack compute service list: The Keystone service is temporarily unavailable. (HTTP 503) on controller node

* 증상: 재부팅후 openstack compute service list에서 Keystone 접속이 되지 않음
```
[root@controller ~]# openstack compute service list
The server is currently unavailable. Please try again at a later time.<br /><br />
The Keystone service is temporarily unavailable.

 (HTTP 503) (Request-ID: req-1c44223e-f3e8-4620-9a77-e0086b6b879d)
[root@controller ~]# tail /var/log/nova/nova-api.log
2022-03-22 09:23:49.119 2720 WARNING keystoneauth.identity.generic.base [-] Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.: ConnectFailure: Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f2e0c118210>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-22 09:23:49.120 2720 CRITICAL keystonemiddleware.auth_token [-] Unable to validate token: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f2e0c118210>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',)): DiscoveryFailure: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f2e0c118210>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-22 09:23:49.121 2720 INFO nova.osapi_compute.wsgi.server [-] 192.168.137.11 "GET /v2.1/os-services HTTP/1.1" status: 503 len: 498 time: 0.0100830

```
* 원인: keystone에서 http://controller:35357에 접속할 수가 없음, httpd 포트 바인딩 되지 않음
```
[root@controller ~]# ls -al /etc/httpd/conf.d/
total 24
drwxr-xr-x. 2 root root  171 Mar 22 09:10 .
drwxr-xr-x. 5 root root   92 Mar 18 11:44 ..
-rw-r--r--  1 root root  197 Mar 21 10:58 00-nova-placement-api.conf
-rw-r-----  1 root root 1035 Mar 21 11:56 00-placement-api.conf
-rw-r--r--. 1 root root 2926 Jan 25 23:08 autoindex.conf
-rw-r--r--. 1 root root  366 Jan 25 23:09 README
-rw-r--r--. 1 root root 1252 Jan  8 01:08 userdir.conf
-rw-r--r--. 1 root root  824 Jan 14 02:38 welcome.conf
lrwxrwxrwx. 1 root root   38 Mar 18 11:54 wsgi-keystone.conf -> /usr/share/keystone/wsgi-keystone.conf
[root@controller ~]# cat /usr/share/keystone/wsgi-keystone.conf
Listen 5000

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/httpd/keystone.log
    CustomLog /var/log/httpd/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
[root@controller ~]#
```
* 조치
   * /etc/nova/nova.conf 에서 auth_url 를 http://controller:5000 로 수정
   * nova 서비스 재시작 `systemctl restart openstack-nova-*`
```
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:5000
#auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_DBPASS
```
* 확인
```
[root@controller ~]# openstack compute service list
+----+----------------+------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host       | Zone     | Status  | State | Updated At                 |
+----+----------------+------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler | controller | internal | enabled | up    | 2022-03-22T00:42:08.000000 |
|  2 | nova-conductor | controller | internal | enabled | up    | 2022-03-22T00:42:14.000000 |
|  5 | nova-compute   | compute1   | nova     | enabled | up    | 2022-03-22T00:42:11.000000 |
+----+----------------+------------+----------+---------+-------+----------------------------+
```


### openstack compute service list: State down on controller node

* 증상: /etc/nova/nova.conf 수정 후 openstack compute service list에서 State가 down으로 표시됨
```
[root@controller ~]# openstack compute service list
+----+----------------+------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host       | Zone     | Status  | State | Updated At                 |
+----+----------------+------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler | controller | internal | enabled | down  | 2022-03-21T05:10:20.000000 |
|  2 | nova-conductor | controller | internal | enabled | down  | 2022-03-21T05:10:15.000000 |
|  5 | nova-compute   | compute1   | nova     | enabled | down  | 2022-03-21T05:10:22.000000 |
+----+----------------+------------+----------+---------+-------+----------------------------+
```
* 원인: /etc/nova/nova.conf에서 [keystone_authtoken]에 auth_url 설정이 잘못됨
* 조치: nova.conf 에 [keystone_authtoken]에 auth_url 설정 추가
```
[root@controller ~]# grep -A12 keystone_authtoken /etc/nova/nova.conf
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_DBPASS
[libvirt]
[metrics]
[root@controller ~]# openstack compute service list
+----+----------------+------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host       | Zone     | Status  | State | Updated At                 |
+----+----------------+------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler | controller | internal | enabled | up    | 2022-03-21T05:27:30.000000 |
|  2 | nova-conductor | controller | internal | enabled | up    | 2022-03-21T05:27:31.000000 |
|  5 | nova-compute   | compute1   | nova     | enabled | up    | 2022-03-21T05:27:24.000000 |
+----+----------------+------------+----------+---------+-------+----------------------------+
[root@controller ~]#
```





### (compute node) Networking service(neutron) Verify nova.log Error

* 증상: 컴퓨트 노드에 Networking service를 설치하고 nova로그에서 error 가 발생함
```
[root@compute1 ~]# tail -f /var/log/nova/nova-compute.log
2022-03-21 16:49:55.902 2863 WARNING keystoneauth.identity.generic.base [req-8100936c-5a83-447e-bbac-ed18d9a17d96 - - - - -] Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.: ConnectFailure: Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7fbd2c1dd810>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-21 16:49:55.902 2863 ERROR nova.compute.resource_tracker [req-8100936c-5a83-447e-bbac-ed18d9a17d96 - - - - -] Skipping removal of allocations for deleted instances: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7fbd2c1dd810>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',)): DiscoveryFailure: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7fbd2c1dd810>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-21 16:49:55.906 2863 WARNING keystoneauth.identity.generic.base [req-8100936c-5a83-447e-bbac-ed18d9a17d96 - - - - -] Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.: ConnectFailure: Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7fbd2c239e50>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-21 16:49:55.909 2863 WARNING keystoneauth.identity.generic.base [req-8100936c-5a83-447e-bbac-ed18d9a17d96 - - - - -] Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.: ConnectFailure: Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7fbd2c201490>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager [req-8100936c-5a83-447e-bbac-ed18d9a17d96 - - - - -] Error updating resources for node compute1.zasfe.local.: ResourceProviderCreationFailed: Failed to create resource provider compute1.zasfe.local
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager Traceback (most recent call last):
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/compute/manager.py", line 8336, in _update_available_resource_for_node
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     startup=startup)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/compute/resource_tracker.py", line 748, in update_available_resource
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     self._update_available_resource(context, resources, startup=startup)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/oslo_concurrency/lockutils.py", line 328, in inner
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     return f(*args, **kwargs)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/compute/resource_tracker.py", line 829, in _update_available_resource
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     self._update(context, cn, startup=startup)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/compute/resource_tracker.py", line 1036, in _update
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     self._update_to_placement(context, compute_node, startup)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/retrying.py", line 68, in wrapped_f
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     return Retrying(*dargs, **dkw).call(f, *args, **kw)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/retrying.py", line 223, in call
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     return attempt.get(self._wrap_exception)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/retrying.py", line 261, in get
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     six.reraise(self.value[0], self.value[1], self.value[2])
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/retrying.py", line 217, in call
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     attempt = Attempt(fn(*args, **kwargs), attempt_number, False)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/compute/resource_tracker.py", line 962, in _update_to_placement
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     context, compute_node.uuid, name=compute_node.hypervisor_hostname)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/scheduler/client/report.py", line 873, in get_provider_tree_and_ensure_root
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     parent_provider_uuid=parent_provider_uuid)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager   File "/usr/lib/python2.7/site-packages/nova/scheduler/client/report.py", line 667, in _ensure_resource_provider
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager     name=name or uuid)
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager ResourceProviderCreationFailed: Failed to create resource provider compute1.zasfe.local
2022-03-21 16:49:55.909 2863 ERROR nova.compute.manager
[root@compute1 ~]# 

[root@controller ~]# tail /var/log/nova/nova-api.log
2022-03-21 17:52:33.838 12954 CRITICAL keystonemiddleware.auth_token [-] Unable to validate token: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7efd48c7ef50>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',)): DiscoveryFailure: Could not find versioned identity endpoints when attempting to authenticate. Please check that your auth_url is correct. Unable to establish connection to http://controller:35357: HTTPConnectionPool(host='controller', port=35357): Max retries exceeded with url: / (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7efd48c7ef50>: Failed to establish a new connection: [Errno 111] ECONNREFUSED',))
[root@compute1 ~]# grep 35357 /etc/nova/nova.conf
#auth_url = http://controller:35357
auth_url = http://controller:35357
[root@compute1 ~]# vim /etc/nova/nova.conf
[root@compute1 ~]# grep 35357 /etc/nova/nova.conf
[root@compute1 ~]#
```
* 윈인: control 노드 Placement API에서 Failur가 발생함
```
[root@controller ~]# nova-status upgrade check
Failed to discover available identity versions when contacting http://controller:35357. Attempting to parse version from URL.
+--------------------------------------------------+
| Upgrade Check Results                            |
+--------------------------------------------------+
| Check: Cells v2                                  |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Placement API                             |
| Result: Failure                                  |
| Details: Discovery for placement API URI failed. |
+--------------------------------------------------+
| Check: Ironic Flavor Migration                   |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Request Spec Migration                    |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
| Check: Console Auths                             |
| Result: Success                                  |
| Details: None                                    |
+--------------------------------------------------+
```
* 조치: control 노드에서 /etc/placement/placement.conf에 [keystone_authtoken]에 auth_url 설정 추가
* 확인
```
[root@controller ~]# nova-status upgrade check
+--------------------------------+
| Upgrade Check Results          |
+--------------------------------+
| Check: Cells v2                |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Placement API           |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Ironic Flavor Migration |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Request Spec Migration  |
| Result: Success                |
| Details: None                  |
+--------------------------------+
| Check: Console Auths           |
| Result: Success                |
| Details: None                  |
+--------------------------------+
```









openstack endpoint list  


# keystone - control
## /etc/httpd/conf.d/wsgi-keystone.conf
## root       964  0.0  0.0 232380   752 ?        Ss   08:50   0:00 /usr/sbin/httpd -DFOREGROUND
## apache    1123  0.0  0.0 234656  1216 ?        S    08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## apache    1124  0.0  0.0 234656  2816 ?        S    08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## apache    1127  0.0  0.0 234656  1004 ?        S    08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## apache    1128  0.0  0.0 234656  1004 ?        S    08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## apache    1133  0.0  0.0 234656  1004 ?        S    08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## apache    2155  0.0  0.1 234656  5628 ?        S    09:02   0:00  \_ /usr/sbin/httpd -DFOREGROUND
lsof -i tcp:5000


# glance Verify
## /usr/bin/python2 /usr/bin/glance-api
##  \_ /usr/bin/python2 /usr/bin/glance-api
openstack image list
lsof -i tcp:9292

# placement Verify
## /etc/httpd/conf.d/00-placement-api.conf
## root       964  0.0  0.0 232380   752 ?        Ss   08:50   0:00 /usr/sbin/httpd -DFOREGROUND
## placeme+  1107  0.0  0.0 324664   964 ?        Sl   08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## placeme+  1108  0.0  0.0 390200   932 ?        Sl   08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND
## placeme+  1114  0.0  0.0 324664   964 ?        Sl   08:50   0:00  \_ /usr/sbin/httpd -DFOREGROUND

lsof -i tcp:8778
placement-status upgrade check


# Compute 
## nova      2674  3.4  3.2 436612 126096 ?       Ss   09:12   0:10 /usr/bin/python2 /usr/bin/nova-api
## nova      2720  0.0  3.3 444064 128872 ?       S    09:12   0:00  \_ /usr/bin/python2 /usr/bin/nova-api
## nova      2721  0.0  3.3 444052 128552 ?       S    09:12   0:00  \_ /usr/bin/python2 /usr/bin/nova-api

lsof -i tcp:8774
nova service-list  
nova-status upgrade check
openstack compute service list --service nova-compute  
openstack compute service list  

# neutron
## neutron   8266  0.6  2.2 435728 116388 ?       Ss   11:28   0:02 /usr/bin/python2 /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log
## neutron   8347  0.0  2.1 435728 110628 ?       S    11:28   0:00  \_ /usr/bin/python2 /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log
## neutron   8348  0.2  2.3 445264 120940 ?       S    11:28   0:00  \_ neutron-server: rpc worker (/usr/bin/python2 /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log)
## neutron   8349  0.1  2.2 438336 113876 ?       S    11:28   0:00  \_ neutron-server: rpc worker (/usr/bin/python2 /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log)
## neutron   8350  0.1  2.2 441948 117356 ?       S    11:28   0:00  \_ neutron-server: periodic worker (/usr/bin/python2 /usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-server --log-file /var/log/neutron/server.log)
## neutron   8268  1.9  1.8 386668 94684 ?        Ss   11:28   0:06 /usr/bin/python2 /usr/bin/neutron-dhcp-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-dhcp-agent --log-file /var/log/neutron/dhcp-agent.log
## neutron   8269  0.4  1.7 383728 91920 ?        Ss   11:28   0:01 /usr/bin/python2 /usr/bin/neutron-metadata-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/metadata_agent.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-metadata-agent --log-file /var/log/neutron/metadata-agent.log
## neutron   8433  0.5  1.9 524412 101068 ?       Ss   11:29   0:01 /usr/bin/python2 /usr/bin/neutron-l3-agent --config-file /usr/share/neutron/neutron-dist.conf --config-dir /usr/share/neutron/l3_agent --config-file /etc/neutron/neutron.conf --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-l3-agent --log-file /var/log/neutron/l3-agent.log
## root      8524  0.0  1.1 398344 60176 ?        Sl   11:29   0:00 /usr/bin/python2 /bin/privsep-helper --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-dir /etc/neutron/conf.d/neutron-l3-agent --privsep_context neutron.privileged.default --privsep_sock_path /tmp/tmpKfZMGX/privsep.sock

## neutron.service
lsof -i tcp:9696
neutron-status upgrade check


# cinder
## cinder   13581  3.7  2.2 607940 137972 ?       Ss   13:27   0:06 /usr/bin/python2 /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log
## cinder   13608  0.0  2.0 607940 126428 ?       S    13:27   0:00  \_ /usr/bin/python2 /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log
## cinder   13582  1.3  2.1 597720 128072 ?       Ss   13:27   0:02 /usr/bin/python2 /usr/bin/cinder-scheduler --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/scheduler.log

## /usr/bin/python2 /usr/bin/cinder-api 
lsof -i tcp:8776

cinder-status upgrade check



* https://heavenkong.blogspot.com/2016/04/resolved-mitaka-openstack-server-create.html
* https://open-infra.tistory.com/19
* https://blog.actorsfit.com/a?ID=01500-f10c6400-2c50-4da7-ac3b-dfac607ea4c2
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'nova' and table_rows<>0 ORDER BY table_rows DESC;`
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'nova_api' and table_rows<>0 ORDER BY table_rows DESC; `
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'cinder' and table_rows<>0 ORDER BY table_rows DESC; `
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'glance' and table_rows<>0 ORDER BY table_rows DESC; `
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'keystone' and table_rows<>0 ORDER BY table_rows DESC; `
   * `SELECT table_name,table_rows FROM information_schema.tables WHERE TABLE_SCHEMA = 'neutron' and table_rows<>0 ORDER BY table_rows DESC; `
* https://4betterme.tistory.com/44

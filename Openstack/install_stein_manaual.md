
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


# Step:10 Keystone Installation


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


# Step:11 Keystone Installation - Create a domain, projects, users, and roles


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



# Step:12 glance Installation - 


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

sed -i 's/#connection = <None>/#connection = <None>\nconnection = mysql+pymysql:\/\/placement:PLACEMENT_DBPASS@controller\/placement/g' /etc/placement/placement.conf  

sed -i 's/#auth_strategy = keystone/#auth_strategy = keystone\nauth_strategy = keystone/' /etc/placement/placement.conf  

sed -i 's/#www_authenticate_uri = <None>/#www_authenticate_uri = <None>\nwww_authenticate_uri  = http:\/\/controller:5000/' /etc/placement/placement.conf  
sed -i 's/#auth_uri = <None>/#auth_uri = <None>\nauth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:5000/' /etc/placement/placement.conf  
sed -i 's/#memcached_servers = <None>/#memcached_servers = <None>\nmemcached_servers = controller:11211/' /etc/placement/placement.conf  

sed -i 's/#auth_type = <None>/#auth_type = <None>\nauth_type = password\nproject_domain_name = Default\nuser_domain_name = Default\nproject_name = service\nusername = placement\npassword = PLACEMENT_DBPASS/' /etc/placement/placement.conf  

su -s /bin/sh -c "placement-manage db sync" placement  


# Step:14 glance Installation - Verify Installation

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
auth_url = http://controller:5000/  
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
auth_url = http://controller:5000/v3  
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










https://docs.openstack.org/install-guide/openstack-services.html

Minimal deployment for Stein

Identity service – keystone installation for Stein -- ok
Image service – glance installation for Stein  -- ok
Placement service – placement installation for Stein  -- ok
Compute service – nova installation for Stein -- ok
Networking service – neutron installation for Stein -- ing
Dashboard – horizon installation for Stein
Block Storage service – cinder installation for Stein



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
auth_url = http://controller:5000
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


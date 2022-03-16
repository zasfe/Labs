


# Multi Node OpenStack Installation on CentOS 7 via Packstack
## https://www.linuxtechi.com/multiple-node-openstack-liberty-installation-on-centos-7-x/

> Controller Node Details
> * Hostname = controller.gabia.local
> * IP Address = 10.17.10.172
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

> Compute Node Details
> * Hostname = compute.gabia.local
> * IP Address = 10.17.10.173
> * OS = CentOS 7.x
> * DNS = 8.8.8.8
> * OpenStack Components
>    - Nova Compute
>    - Neutron – Openvswitch Agent

> Network Node Details
> * Hostname = network.gabia.local
> * IP Address = 10.17.10.174
> * OS = CentOS 7.x
> * DNS = 8.8.8.8
> * OpenStack Components
>    - Neutron Server
>    - Neturon DHCP agent
>    - Neutron- Openswitch agent
>    - Neutron L3 agent






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

/etc/hosts
10.17.10.172 controller.gabia.local controller
10.17.10.173 compute.gabia.local    compute
10.17.10.174 network.gabia.local    network

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
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@10.17.10.172
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@10.17.10.173
ssh-copy-id -f -i /root/.ssh/id_rsa.pub root@10.17.10.174


# Step:5 Enable RDO repository and install packstack utility

yum -y remove leatherman-1.10.0-1.el7.x86_64
yum -y install leatherman-1.3.0*
yum -y install leatherman-devel-1.3.0*
yum -y remove openstack-packstack

yum -y install centos-release-openstack-train epel-release
yum -y install https://www.rdoproject.org/repos/rdo-release.rpm

> yum -y install python-openstackclient
> yum -y install openstack-selinux 
> yum -y install mariadb mariadb-server python2-PyMySQL

yum install -y mod_wsgi

yum -y install openstack-utils
yum -y install openstack-packstack

# Step:6 Generate and customize answer file
packstack --gen-answer-file=/root/answer.txt

sed -i s/^CONFIG_CONTROLLER_HOST=.*$/CONFIG_CONTROLLER_HOST=10\.17\.10\.172/ /root/answer.txt
sed -i s/^CONFIG_COMPUTE_HOSTS=.*$/CONFIG_COMPUTE_HOSTS=10\.17\.10\.173/ /root/answer.txt
sed -i s/^CONFIG_NETWORK_HOSTS=.*$/CONFIG_NETWORK_HOSTS=10\.17\.10\.174/ /root/answer.txt
sed -i s/^CONFIG_PROVISION_DEMO=.*$/CONFIG_PROVISION_DEMO=n/ /root/answer.txt
sed -i s/^CONFIG_CEILOMETER_INSTALL=.*$/CONFIG_CEILOMETER_INSTALL=n/ /root/answer.txt
sed -i s/^CONFIG_HORIZON_SSL=.*$/CONFIG_HORIZON_SSL=y/ /root/answer.txt
sed -i s/^CONFIG_NTP_SERVERS=.*$/CONFIG_NTP_SERVERS=time\.windows\.com/ /root/answer.txt
sed -i s/^CONFIG_KEYSTONE_ADMIN_PW=.*$/CONFIG_KEYSTONE_ADMIN_PW=gabia1234/ /root/answer.txt
sed -i s/^CONFIG_NEUTRON_L2_AGENT=.*$/CONFIG_NEUTRON_L2_AGENT=openvswitch/ /root/answer.txt


> vi /root/answer.txt
> ........................................
> CONFIG_CONTROLLER_HOST=10.17.10.172
> CONFIG_COMPUTE_HOSTS=10.17.10.173
> CONFIG_NETWORK_HOSTS=10.17.10.174
> CONFIG_PROVISION_DEMO=n
> CONFIG_CEILOMETER_INSTALL=n
> CONFIG_HORIZON_SSL=y
> CONFIG_NTP_SERVERS=time.windows.com
> CONFIG_KEYSTONE_ADMIN_PW=gabia1234 <-- 오픈스택 패스워드
> ..........................................

# Step:7 Start Installation using packstack command.

packstack --answer-file=/root/answer.txt









## 초기화
ssh compute
yum -y remove openstack-*
exit

ssh network
yum -y remove openstack-*
exit


yum -y remove openstack-*
yum -y install openstack-packstack
packstack --answer-file=/root/answer.txt


ssh compute





# 문제 해결


## packstack 설치간 leatherman_curl 라이브러리 못찾음

```
[root@controller ~]# packstack --answer-file=/root/answer.txt
Welcome to the Packstack setup utility

The installation log file is available at: /var/tmp/packstack/20220315-114939-dzInbT/openstack-setup.log

Installing:
Clean Up                                             [ DONE ]
Discovering ip protocol version                      [ DONE ]
Setting up ssh keys                                  [ DONE ]
Preparing servers                                    [ DONE ]
Pre installing Puppet and discovering hosts' details[ ERROR ]

ERROR : Failed to run remote script, stdout:
stderr: Warning: Permanently added '10.17.10.173' (ECDSA) to the list of known hosts.
+ trap t ERR
+ facter -p
facter: error while loading shared libraries: leatherman_curl.so.1.3.0: cannot open shared object file: No such file or directory
++ t
++ exit 127

[root@controller ~]# rpm -qa | grep leatherman
leatherman-1.10.0-1.el7.x86_64
```

* 조치: 현재 설치된 버전 삭제 및 하위 버전 설치
```
yum -y remove leatherman-1.10.0-1.el7.x86_64
yum -y install leatherman-1.3.0*
yum -y install leatherman-devel-1.3.0*
```

## packstack 설치간 NTP 서버 연결 불가

* 증상
```
Applying Puppet manifests                         [ ERROR ]

ERROR : Error appeared during Puppet run: 10.17.10.172_controller.pp
Error: '/usr/sbin/ntpdate 203.248.240.140' returned 1 instead of one of [0]
You will find full trace in log /var/tmp/packstack/20220315-122242-V0BZn9/manifests/10.17.10.172_controller.pp.log
Please check log file /var/tmp/packstack/20220315-122242-V0BZn9/openstack-setup.log for more information
Additional information:
 * File /root/keystonerc_admin has been created on OpenStack client host 10.17.10.172. To use the command line tools you need to source the file.
 * NOTE : A certificate was generated to be used for ssl, You should change the ssl certificate configured in /etc/httpd/conf.d/ssl.conf on 10.17.10.172 to use a CA signed cert.
 * To access the OpenStack Dashboard browse to https://10.17.10.172/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
[root@controller ~]# /usr/sbin/ntpdate 203.248.240.140
15 Mar 12:32:04 ntpdate[19188]: no server suitable for synchronization found
[root@controller ~]# /usr/sbin/ntpdate time.bora.net
15 Mar 12:32:23 ntpdate[19239]: no server suitable for synchronization found
[root@controller ~]# /usr/sbin/ntpdate time.kriss.re.kr
15 Mar 12:34:07 ntpdate[19372]: no server suitable for synchronization found
[root@controller ~]#
```

* 조치
```
[root@controller ~]# /usr/sbin/ntpdate time.windows.com
15 Mar 12:36:52 ntpdate[19638]: adjust time server 52.231.114.183 offset -0.005067 sec
[root@controller ~]# sed -i s/^CONFIG_NTP_SERVERS=.*$/CONFIG_NTP_SERVERS=time\.windows\.com/ /root/answer.txt
```

## packstack 설치간 openstack-dashboard 설치 오류

* 증상
```
Applying 10.17.10.172_controller.pp
10.17.10.172_controller.pp:                       [ ERROR ]
Applying Puppet manifests                         [ ERROR ]

ERROR : Error appeared during Puppet run: 10.17.10.172_controller.pp
Error: Execution of '/usr/bin/yum -d 0 -e 0 -y install openstack-dashboard' returned 1: Package python36-mod_wsgi is obsoleted by python3-mod_wsgi, but obsoleting package does not provide for requirements
You will find full trace in log /var/tmp/packstack/20220315-123814-vjFq0h/manifests/10.17.10.172_controller.pp.log
Please check log file /var/tmp/packstack/20220315-123814-vjFq0h/openstack-setup.log for more information
Additional information:
 * File /root/keystonerc_admin has been created on OpenStack client host 10.17.10.172. To use the command line tools you need to source the file.
 * NOTE : A certificate was generated to be used for ssl, You should change the ssl certificate configured in /etc/httpd/conf.d/ssl.conf on 10.17.10.172 to use a CA signed cert.
 * To access the OpenStack Dashboard browse to https://10.17.10.172/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
[root@controller ~]# /usr/bin/yum -d 0 -e 0 -y install openstack-dashboard
Package python36-mod_wsgi is obsoleted by python3-mod_wsgi, but obsoleting package does not provide for requirements
Package python36-mod_wsgi is obsoleted by python3-mod_wsgi, but obsoleting package does not provide for requirements
Package python36-mod_wsgi is obsoleted by python3-mod_wsgi, but obsoleting package does not provide for requirements
Package python36-mod_wsgi is obsoleted by python3-mod_wsgi, but obsoleting package does not provide for requirements
Error: Package: 1:openstack-dashboard-16.2.2-1.el7.noarch (centos-openstack-train)
           Requires: mod_wsgi
           Available: mod_wsgi-3.4-18.el7.x86_64 (base)
               mod_wsgi = 3.4-18.el7
           Available: python36-mod_wsgi-4.6.2-2.el7.ius.x86_64 (ius)
               mod_wsgi = 4.6.2
 You could try using --skip-broken to work around the problem
 You could try running: rpm -Va --nofiles --nodigest
[root@controller ~]# yum search mod_wsgi
Loaded plugins: fastestmirror, product-id, search-disabled-repos, subscription-manager

This system is not registered with an entitlement server. You can use subscription-manager to register.

Repository rdo-trunk-train-tested is listed more than once in the configuration
Loading mirror speeds from cached hostfile
 * base: mirror.kakao.com
 * centos-ceph-nautilus: mirror.kakao.com
 * centos-nfs-ganesha28: mirror.kakao.com
 * centos-openstack-train: mirror.kakao.com
 * centos-qemu-ev: mirror.kakao.com
 * epel: ftp.riken.jp
 * extras: mirror.kakao.com
 * openstack-train: mirror.kakao.com
 * rdo-qemu-ev: mirror.kakao.com
 * updates: mirror.kakao.com
============================================================================================== N/S matched: mod_wsgi ==============================================================================================
koschei-frontend.noarch : Web frontend for koschei using mod_wsgi
mod_wsgi.x86_64 : A WSGI interface for Python web applications in Apache
python3-mod_wsgi.x86_64 : A WSGI interface for Python web applications in Apache
python36-mod_wsgi.x86_64 : A WSGI interface for Python web applications in Apache
viewvc-httpd-wsgi.noarch : ViewVC configuration for Apache/mod_wsgi

  Name and summary matches only, use "search all" for everything.
[root@controller ~]#
```

* 조치: mod_wsgi 패키지 설치

```
[root@controller ~]# yum install -y mod_wsgi
...
Installed:
  mod_wsgi.x86_64 0:3.4-18.el7

Complete!
[root@controller ~]#
```


## packstack 설치간 openstack volume 오류

* 증상
```
10.17.10.172_controller.pp:                       [ ERROR ]
Applying Puppet manifests                         [ ERROR ]

ERROR : Error appeared during Puppet run: 10.17.10.172_controller.pp
Error: Failed to apply catalog: Execution of '/usr/bin/openstack volume type list --quiet --format csv --long' returned 1: Unable to establish connection to http://10.17.10.172:8776/v3/93d4fc1c561a4234a0fcf850880846be/types?is_public=None: HTTPConnectionPool(host='10.17.10.172', port=8776): Max retries exceeded with url: /v3/93d4fc1c561a4234a0fcf850880846be/types?is_public=None (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f9c038714d0>: Failed to establish a new connection: [Errno 111] Connection refused',)) (tried 31, for a total of 170 seconds)
You will find full trace in log /var/tmp/packstack/20220315-125954-WRVtCJ/manifests/10.17.10.172_controller.pp.log
Please check log file /var/tmp/packstack/20220315-125954-WRVtCJ/openstack-setup.log for more information
Additional information:
 * File /root/keystonerc_admin has been created on OpenStack client host 10.17.10.172. To use the command line tools you need to source the file.
 * NOTE : A certificate was generated to be used for ssl, You should change the ssl certificate configured in /etc/httpd/conf.d/ssl.conf on 10.17.10.172 to use a CA signed cert.
 * To access the OpenStack Dashboard browse to https://10.17.10.172/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
```

* 조치
```
[root@controller ~]# /usr/bin/openstack volume type list --quiet --format csv --long
Missing value auth-url required for auth plugin password
[root@controller ~]# source ~/keystonerc_admin
[root@controller ~(keystone_admin)]# /usr/bin/openstack volume type list --quiet --format csv --long
"ID","Name","Is Public","Description","Properties"
"a59785c1-83e1-464e-9607-945a77b148fa","__DEFAULT__",True,"Default Volume Type","{}"
[root@controller ~(keystone_admin)]# 
```

## packstack 설치간 에러


* 증상
```
Applying 10.17.10.172_controller.pp
10.17.10.172_controller.pp:                       [ ERROR ]
Applying Puppet manifests                         [ ERROR ]

ERROR : Error appeared during Puppet run: 10.17.10.172_controller.pp
Error: Failed to apply catalog: Execution of '/usr/bin/openstack flavor list --quiet --format csv --long --all' returned 1: Unknown Error (HTTP 500) (tried 28, for a total of 170 seconds)
You will find full trace in log /var/tmp/packstack/20220315-132206-8d6pfe/manifests/10.17.10.172_controller.pp.log
Please check log file /var/tmp/packstack/20220315-132206-8d6pfe/openstack-setup.log for more information
Additional information:
 * File /root/keystonerc_admin has been created on OpenStack client host 10.17.10.172. To use the command line tools you need to source the file.
 * NOTE : A certificate was generated to be used for ssl, You should change the ssl certificate configured in /etc/httpd/conf.d/ssl.conf on 10.17.10.172 to use a CA signed cert.
 * To access the OpenStack Dashboard browse to https://10.17.10.172/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
[root@controller ~(keystone_admin)]# /usr/bin/openstack flavor list --quiet --format csv --long --all
Unknown Error (HTTP 500)
[root@controller ~(keystone_admin)]#
```

* 조치
```
[root@controller httpd(keystone_admin)]# tail /var/log/httpd/nova_api_wsgi_error.log
[Tue Mar 15 13:59:12.290334 2022] [:error] [pid 8790] [remote 10.17.10.172:0]     result.read()
[Tue Mar 15 13:59:12.290339 2022] [:error] [pid 8790] [remote 10.17.10.172:0]   File "/usr/lib/python2.7/site-packages/pymysql/connections.py", line 1075, in read
[Tue Mar 15 13:59:12.290346 2022] [:error] [pid 8790] [remote 10.17.10.172:0]     first_packet = self.connection._read_packet()
[Tue Mar 15 13:59:12.290350 2022] [:error] [pid 8790] [remote 10.17.10.172:0]   File "/usr/lib/python2.7/site-packages/pymysql/connections.py", line 684, in _read_packet
[Tue Mar 15 13:59:12.290357 2022] [:error] [pid 8790] [remote 10.17.10.172:0]     packet.check_error()
[Tue Mar 15 13:59:12.290361 2022] [:error] [pid 8790] [remote 10.17.10.172:0]   File "/usr/lib/python2.7/site-packages/pymysql/protocol.py", line 220, in check_error
[Tue Mar 15 13:59:12.290434 2022] [:error] [pid 8790] [remote 10.17.10.172:0]     err.raise_mysql_exception(self._data)
[Tue Mar 15 13:59:12.290442 2022] [:error] [pid 8790] [remote 10.17.10.172:0]   File "/usr/lib/python2.7/site-packages/pymysql/err.py", line 109, in raise_mysql_exception
[Tue Mar 15 13:59:12.290480 2022] [:error] [pid 8790] [remote 10.17.10.172:0]     raise errorclass(errno, errval)
[Tue Mar 15 13:59:12.290554 2022] [:error] [pid 8790] [remote 10.17.10.172:0] ProgrammingError: (pymysql.err.ProgrammingError) (1146, u"Table 'nova.services' doesn't exist") [SQL: u'SELECT services.created_at AS services_created_at, services.updated_at AS services_updated_at, services.deleted_at AS services_deleted_at, services.deleted AS services_deleted, services.id AS services_id, services.uuid AS services_uuid, services.host AS services_host, services.`binary` AS services_binary, services.topic AS services_topic, services.report_count AS services_report_count, services.disabled AS services_disabled, services.disabled_reason AS services_disabled_reason, services.last_seen_up AS services_last_seen_up, services.forced_down AS services_forced_down, services.version AS services_version \\nFROM services \\nWHERE services.deleted = %(deleted_1)s AND services.host = %(host_1)s AND services.`binary` = %(binary_1)s \\n LIMIT %(param_1)s'] [parameters: {u'host_1': 'controller', u'param_1': 1, u'deleted_1': 0, u'binary_1': 'nova-osapi_compute'}] (Background on this error at: http://sqlalche.me/e/f405)
[root@controller httpd(keystone_admin)]# nova-manage db sync
/usr/lib/python2.7/site-packages/pymysql/cursors.py:170: Warning: (1831, u'Duplicate index `block_device_mapping_instance_uuid_virtual_name_device_name_idx`. This is deprecated and will be disallowed in a future release')
  result = self._query(query)
/usr/lib/python2.7/site-packages/pymysql/cursors.py:170: Warning: (1831, u'Duplicate index `uniq_instances0uuid`. This is deprecated and will be disallowed in a future release')
  result = self._query(query)
[root@controller httpd(keystone_admin)]# /usr/bin/openstack flavor list --quiet --format csv --long --all
"ID","Name","RAM","Disk","Ephemeral","VCPUs","Is Public","Swap","RXTX Factor","Properties"
```

## packstack 설치간 오류

* 증상
```

```

* 조치
```

```







## 재부팅후 확인해야할 서비스

systemctl status memcached.service // 세션, 토큰
systemctl status rabbitmq-server.service // 메시지
systemctl status chronyd.service // 시간 서버

# 참고

* https://bxmsta9ram.tistory.com/154
* https://www.reddit.com/r/openstack/comments/gxe8wf/unable_to_install_packstack_on_centos_78/
* 오픈스택 잘 안 될시 문제 사항 (https://it-hangil.tistory.com/37)
* OpenStack 설치(Packstack) (https://it-hangil.tistory.com/34)
* https://www.cnblogs.com/yanzi2020/p/14456092.html
* https://zhuanlan.zhihu.com/p/52795181


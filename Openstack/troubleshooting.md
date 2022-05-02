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

### (compute node) Networking service(neutron) Verify nova.log Error

* 증상: compute 노드에서 neutron-linuxbridge-agent.service 서비스가 중단된다
```
[root@compute1 ~]# systemctl status neutron-linuxbridge-agent.service
â— neutron-linuxbridge-agent.service - OpenStack Neutron Linux Bridge Agent
   Loaded: loaded (/usr/lib/systemd/system/neutron-linuxbridge-agent.service; enabled; vendor preset: disabled)
   Active: failed (Result: start-limit) since Tue 2022-03-22 11:01:18 KST; 8h ago
  Process: 3136 ExecStart=/usr/bin/neutron-linuxbridge-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/linuxbridge_agent.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-linuxbridge-agent --log-file /var/log/neutron/linuxbridge-agent.log (code=exited, status=1/FAILURE)
  Process: 3131 ExecStartPre=/usr/bin/neutron-enable-bridge-firewall.sh (code=exited, status=0/SUCCESS)
 Main PID: 3136 (code=exited, status=1/FAILURE)

Mar 22 11:01:18 compute1 systemd[1]: neutron-linuxbridge-agent.service: main process exited, code=exited, status=1/FAILURE
Mar 22 11:01:18 compute1 systemd[1]: Unit neutron-linuxbridge-agent.service entered failed state.
Mar 22 11:01:18 compute1 systemd[1]: neutron-linuxbridge-agent.service failed.
Mar 22 11:01:18 compute1 systemd[1]: neutron-linuxbridge-agent.service holdoff time over, scheduling restart.
Mar 22 11:01:18 compute1 systemd[1]: Stopped OpenStack Neutron Linux Bridge Agent.
Mar 22 11:01:18 compute1 systemd[1]: start request repeated too quickly for neutron-linuxbridge-agent.service
Mar 22 11:01:18 compute1 systemd[1]: Failed to start OpenStack Neutron Linux Bridge Agent.
Mar 22 11:01:18 compute1 systemd[1]: Unit neutron-linuxbridge-agent.service entered failed state.
Mar 22 11:01:18 compute1 systemd[1]: neutron-linuxbridge-agent.service failed.
[root@compute1 ~]# 
```
* 원인: /etc/neutron/plugins/ml2/linuxbridge_agent.ini 에 vxlan 설정이 없음
* 조치:
```
echo "[vxlan]" | sudo tee --append /etc/neutron/plugins/ml2/linuxbridge_agent.ini
echo "local_ip=192.168.137.31" | sudo tee --append /etc/neutron/plugins/ml2/linuxbridge_agent.ini
```
* 확인
```
[root@compute1 ~]# systemctl status neutron-linuxbridge-agent.service
â— neutron-linuxbridge-agent.service - OpenStack Neutron Linux Bridge Agent
   Loaded: loaded (/usr/lib/systemd/system/neutron-linuxbridge-agent.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2022-03-22 19:18:33 KST; 5min ago
  Process: 8798 ExecStartPre=/usr/bin/neutron-enable-bridge-firewall.sh (code=exited, status=0/SUCCESS)
 Main PID: 8803 (/usr/bin/python)
    Tasks: 1
   CGroup: /system.slice/neutron-linuxbridge-agent.service
           â””â”€8803 /usr/bin/python2 /usr/bin/neutron-linuxbridge-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/linuxbri...

Mar 22 19:18:33 compute1 systemd[1]: Starting OpenStack Neutron Linux Bridge Agent...
Mar 22 19:18:33 compute1 neutron-enable-bridge-firewall.sh[8798]: net.bridge.bridge-nf-call-iptables = 1
Mar 22 19:18:33 compute1 neutron-enable-bridge-firewall.sh[8798]: net.bridge.bridge-nf-call-ip6tables = 1
Mar 22 19:18:33 compute1 systemd[1]: Started OpenStack Neutron Linux Bridge Agent.
Mar 22 19:18:35 compute1 sudo[8817]:  neutron : TTY=unknown ; PWD=/ ; USER=root ; COMMAND=/bin/neutron-rootwrap /etc/neutron/rootwrap.conf privsep-helper --config-file /usr/share/neutron/neutron-dist.conf --c...
Mar 22 19:18:38 compute1 sudo[8846]:  neutron : TTY=unknown ; PWD=/ ; USER=root ; COMMAND=/bin/neutron-rootwrap-daemon /etc/neutron/rootwrap.conf
Hint: Some lines were ellipsized, use -l to show in full.
[root@compute1 ~]#
```


### (control node) openstack server create, <class 'neutronclient.common.exceptions.Unauthorized'> (HTTP 500)

* 증상: server를 생성할 때 HTTP 500에러가 발생한다.
```
[root@controller ~]# openstack server create --flavor m1.nano --image cirros --nic net-id=494ecb7c-8153-4835-bdfe-411df939efa6 --security-group default --key-name mykey provider-instance
Unexpected API Error. Please report this at http://bugs.launchpad.net/nova/ and attach the Nova API log if possible.
<class 'neutronclient.common.exceptions.Unauthorized'> (HTTP 500) (Request-ID: req-d8bb1060-35f7-40fe-8946-ecd51156585e)
[root@controller ~]# grep ERROR  /var/log/nova/nova-api.log
2022-03-22 19:19:10.936 533 ERROR nova.network.neutronv2.api [req-d8bb1060-35f7-40fe-8946-ecd51156585e 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] The [neutron] section of your nova configuration file must be configured for authentication with the networking service endpoint. See the networking service install guide for details: https://docs.openstack.org/neutron/latest/install/
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi [req-d8bb1060-35f7-40fe-8946-ecd51156585e 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] Unexpected exception in API method: Unauthorized: Unknown auth type: None
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi Traceback (most recent call last):
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/openstack/wsgi.py", line 671, in wrapped
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return f(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/validation/__init__.py", line 110, in wrapper
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     return func(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/api/openstack/compute/servers.py", line 687, in create
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     **create_kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/hooks.py", line 154, in inner
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     rv = f(*args, **kwargs)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/compute/api.py", line 1883, in create
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     supports_port_resource_request=supports_port_resource_request)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/compute/api.py", line 1303, in _create_instance
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     reservation_id, max_count, supports_port_resource_request)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/compute/api.py", line 929, in _validate_and_build_base_options
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     context, requested_networks, pci_request_info)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/network/neutronv2/api.py", line 2085, in create_resource_requests
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     neutron = get_client(context, admin=True)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/network/neutronv2/api.py", line 180, in get_client
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     auth_plugin = _get_auth_plugin(context, admin=admin)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/network/neutronv2/api.py", line 160, in _get_auth_plugin
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     _ADMIN_AUTH = _load_auth_plugin(CONF)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi   File "/usr/lib/python2.7/site-packages/nova/network/neutronv2/api.py", line 91, in _load_auth_plugin
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi     raise neutron_client_exc.Unauthorized(message=err_msg)
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi Unauthorized: Unknown auth type: None
2022-03-22 19:19:10.936 533 ERROR nova.api.openstack.wsgi

```
* 원인: `/etc/nova/nova.conf`에 `[neutron]` endpoint 설정이 없음
```
[root@controller ~]# grep -A4 "^\[neutron\]" /etc/nova/nova.conf
[neutron]
[notifications]
[osapi_v21]
[oslo_concurrency]
[root@controller ~]#
```
* 조치
   1. `/etc/nova/nova.conf`에 `[neutron]` endpoint 설정 추가
   2. `systemctl restart openstack-nova-*` 
```
[neutron]
url = http://controller:9696
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_DBPASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
```
* 확인
   * `openstack server create --flavor m1.nano --image cirros --nic net-id=494ecb7c-8153-4835-bdfe-411df939efa6 --security-group default --key-name mykey provider-instance`
   * `openstack server list`
```
[root@controller ~]# openstack server create --flavor m1.nano --image cirros --nic net-id=494ecb7c-8153-4835-bdfe-411df939efa6 --security-group default --key-name mykey provider-instance
HTTP 500 Internal Server Error: The server has either erred or is incapable of performing the requested operation.
[root@controller ~]# 
```


### (control node) openstack server create, status ERROR, Build of instance 14c8f79e-4436-4ad9-9e5f-07de34b47247 aborted: Auth plugin requires parameters which were not given: auth_url

* 증상: server를 생성할 때 status가 ERROR 이다.
```
[root@controller ~]# openstack server create --flavor m1.nano --image cirros   --nic net-id=494ecb7c-8153-4835-bdfe-411df939efa6 --security-group default   --key-name mykey selfservice-instance
+-----------------------------+-----------------------------------------------+
| Field                       | Value                                         |
+-----------------------------+-----------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                        |
| OS-EXT-AZ:availability_zone |                                               |
| OS-EXT-STS:power_state      | NOSTATE                                       |
| OS-EXT-STS:task_state       | scheduling                                    |
| OS-EXT-STS:vm_state         | building                                      |
| OS-SRV-USG:launched_at      | None                                          |
| OS-SRV-USG:terminated_at    | None                                          |
| accessIPv4                  |                                               |
| accessIPv6                  |                                               |
| addresses                   |                                               |
| adminPass                   | JBQ99gtBeZFm                                  |
| config_drive                |                                               |
| created                     | 2022-03-23T02:02:13Z                          |
| flavor                      | m1.nano (0)                                   |
| hostId                      |                                               |
| id                          | 77ef07bc-62e9-4d49-884e-98fbf2b5cf71          |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6) |
| key_name                    | mykey                                         |
| name                        | selfservice-instance                          |
| progress                    | 0                                             |
| project_id                  | fdd6efd656374844a7d4a095736e21dd              |
| properties                  |                                               |
| security_groups             | name='7db0a045-c512-40cb-8ccd-518e849b1936'   |
| status                      | BUILD                                         |
| updated                     | 2022-03-23T02:02:14Z                          |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af              |
| volumes_attached            |                                               |
+-----------------------------+-----------------------------------------------+
clean_up CreateServer:
END return value: 0
[root@controller ~]# openstack server list
+--------------------------------------+----------------------+--------+----------+--------+---------+
| ID                                   | Name                 | Status | Networks | Image  | Flavor  |
+--------------------------------------+----------------------+--------+----------+--------+---------+
| 14c8f79e-4436-4ad9-9e5f-07de34b47247 | selfservice-instance | ERROR  |          | cirros | m1.nano |
+--------------------------------------+----------------------+--------+----------+--------+---------+
[root@controller ~]#  openstack server show selfservice-instance
+-----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| Field                       | Value
+-----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| OS-DCF:diskConfig           | MANUAL
| OS-EXT-AZ:availability_zone |
| OS-EXT-STS:power_state      | NOSTATE
| OS-EXT-STS:task_state       | None
| OS-EXT-STS:vm_state         | error
| OS-SRV-USG:launched_at      | None
| OS-SRV-USG:terminated_at    | None
| accessIPv4                  |
| accessIPv6                  |
| addresses                   |
| config_drive                |
| created                     | 2022-03-23T01:33:59Z
| fault                       | {u'message': u'Build of instance 14c8f79e-4436-4ad9-9e5f-07de34b47247 aborted: Auth plugin requires parameters which were not given: auth_url', u'code': 500, u'created': u'2022-03
| flavor                      | m1.nano (0)
| hostId                      |
| id                          | 14c8f79e-4436-4ad9-9e5f-07de34b47247
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6)
| key_name                    | mykey
| name                        | selfservice-instance
| project_id                  | fdd6efd656374844a7d4a095736e21dd
| properties                  |
| status                      | ERROR
| updated                     | 2022-03-23T01:34:11Z
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af
| volumes_attached            |
+-----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
...
[root@compute1 ~]# grep -i error /var/log/nova/*
/var/log/nova/nova-compute.log:2022-03-23 11:02:16.336 970 WARNING nova.compute.manager [req-8f7d61d1-be71-418a-be39-baa5dc7dcf5f 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] Could not clean up failed build, not rescheduling. Error: Auth plugin requires parameters which were not given: auth_url: MissingRequiredOptions: Auth plugin requires parameters which were not given: auth_url
/var/log/nova/nova-compute.log:2022-03-23 11:02:16.467 970 ERROR nova.compute.manager [req-8f7d61d1-be71-418a-be39-baa5dc7dcf5f 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] [instance: 77ef07bc-62e9-4d49-884e-98fbf2b5cf71] Build of instance 77ef07bc-62e9-4d49-884e-98fbf2b5cf71 aborted: Auth plugin requires parameters which were not given: auth_url: BuildAbortException: Build of instance 77ef07bc-62e9-4d49-884e-98fbf2b5cf71 aborted: Auth plugin requires parameters which were not given: auth_url
/var/log/nova/nova-compute.log:2022-03-23 11:02:16.481 970 WARNING nova.compute.manager [req-8f7d61d1-be71-418a-be39-baa5dc7dcf5f 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] Failed to update network info cache when cleaning up allocated networks. Stale VIFs may be left on this host.Error: Auth plugin requires parameters which were not given: auth_url: MissingRequiredOptions: Auth plugin requires parameters which were not given: auth_url

```
* 원인
   * compute 노드 `/etc/nova/nova.conf`에서 `[neutron]` 항목에 auth_url 설정이 없음
* 조치: compute 노드 `/etc/nova/nova.conf`에서 `[neutron]` 항목에 auth_url 설정 추가
```
[neutron]
url = http://controller:9696
auth_uri = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
```
* 확인
```
[root@controller ~]# openstack server create --flavor m1.nano --image cirros   --nic net-id=494ecb7c-8153-4835-bdfe-411df939efa6 --security-group default   --key-name mykey selfservice-instance
+-----------------------------+-----------------------------------------------+
| Field                       | Value                                         |
+-----------------------------+-----------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                        |
| OS-EXT-AZ:availability_zone |                                               |
| OS-EXT-STS:power_state      | NOSTATE                                       |
| OS-EXT-STS:task_state       | scheduling                                    |
| OS-EXT-STS:vm_state         | building                                      |
| OS-SRV-USG:launched_at      | None                                          |
| OS-SRV-USG:terminated_at    | None                                          |
| accessIPv4                  |                                               |
| accessIPv6                  |                                               |
| addresses                   |                                               |
| adminPass                   | uVoYGWnBn3Qp                                  |
| config_drive                |                                               |
| created                     | 2022-03-23T03:18:41Z                          |
| flavor                      | m1.nano (0)                                   |
| hostId                      |                                               |
| id                          | 26994e1e-54ac-4208-bd65-0d9637fd0d2e          |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6) |
| key_name                    | mykey                                         |
| name                        | selfservice-instance                          |
| progress                    | 0                                             |
| project_id                  | fdd6efd656374844a7d4a095736e21dd              |
| properties                  |                                               |
| security_groups             | name='7db0a045-c512-40cb-8ccd-518e849b1936'   |
| status                      | BUILD                                         |
| updated                     | 2022-03-23T03:18:41Z                          |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af              |
| volumes_attached            |                                               |
+-----------------------------+-----------------------------------------------+
[root@controller ~]# openstack server list
+--------------------------------------+----------------------+--------+--------------------------+--------+---------+
| ID                                   | Name                 | Status | Networks                 | Image  | Flavor  |
+--------------------------------------+----------------------+--------+--------------------------+--------+---------+
| 26994e1e-54ac-4208-bd65-0d9637fd0d2e | selfservice-instance | ACTIVE | selfservice=172.16.1.135 | cirros | m1.nano |
+--------------------------------------+----------------------+--------+--------------------------+--------+---------+
[root@controller ~]#
```


### (control node) openstack server create, status ERROR, Exceeded maximum number of retries. Exhausted all hosts available for retrying build failures for instance

* 증상: 서버를 생성할 때 오류가 발생한다
```
[root@controller ~]# openstack server create --flavor m1.nano --image cirros --nic net-id=163c6532-1576-4fc4-b527-0d0443c4a3ba --security-group default --key-name mykey provider-instance
+-----------------------------+-----------------------------------------------+
| Field                       | Value                                         |
+-----------------------------+-----------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                        |
| OS-EXT-AZ:availability_zone |                                               |
| OS-EXT-STS:power_state      | NOSTATE                                       |
| OS-EXT-STS:task_state       | scheduling                                    |
| OS-EXT-STS:vm_state         | building                                      |
| OS-SRV-USG:launched_at      | None                                          |
| OS-SRV-USG:terminated_at    | None                                          |
| accessIPv4                  |                                               |
| accessIPv6                  |                                               |
| addresses                   |                                               |
| adminPass                   | ckCPVgDLe2VH                                  |
| config_drive                |                                               |
| created                     | 2022-03-23T03:55:36Z                          |
| flavor                      | m1.nano (0)                                   |
| hostId                      |                                               |
| id                          | eb4ab6f8-42cb-4d14-befc-96d5db70e357          |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6) |
| key_name                    | mykey                                         |
| name                        | provider-instance                             |
| progress                    | 0                                             |
| project_id                  | fdd6efd656374844a7d4a095736e21dd              |
| properties                  |                                               |
| security_groups             | name='7db0a045-c512-40cb-8ccd-518e849b1936'   |
| status                      | BUILD                                         |
| updated                     | 2022-03-23T03:55:36Z                          |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af              |
| volumes_attached            |                                               |
+-----------------------------+-----------------------------------------------+
[root@controller ~]# openstack server show provider-instance
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field                       | Value                                                                                                                                                                                                                |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                                                                                                                                                                               |
| OS-EXT-AZ:availability_zone |                                                                                                                                                                                                                      |
| OS-EXT-STS:power_state      | NOSTATE                                                                                                                                                                                                              |
| OS-EXT-STS:task_state       | None                                                                                                                                                                                                                 |
| OS-EXT-STS:vm_state         | error                                                                                                                                                                                                                |
| OS-SRV-USG:launched_at      | None                                                                                                                                                                                                                 |
| OS-SRV-USG:terminated_at    | None                                                                                                                                                                                                                 |
| accessIPv4                  |                                                                                                                                                                                                                      |
| accessIPv6                  |                                                                                                                                                                                                                      |
| addresses                   |                                                                                                                                                                                                                      |
| config_drive                |                                                                                                                                                                                                                      |
| created                     | 2022-03-23T04:02:16Z                                                                                                                                                                                                 |
| fault                       | {u'message': u'Exceeded maximum number of retries. Exhausted all hosts available for retrying build failures for instance 3b055932-43f0-4dbe-be72-b02dd3cde75c.', u'code': 500, u'created': u'2022-03-23T04:02:24Z'} |
| flavor                      | m1.nano (0)                                                                                                                                                                                                          |
| hostId                      |                                                                                                                                                                                                                      |
| id                          | 3b055932-43f0-4dbe-be72-b02dd3cde75c                                                                                                                                                                                 |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6)                                                                                                                                                                        |
| key_name                    | mykey                                                                                                                                                                                                                |
| name                        | provider-instance                                                                                                                                                                                                    |
| project_id                  | fdd6efd656374844a7d4a095736e21dd                                                                                                                                                                                     |
| properties                  |                                                                                                                                                                                                                      |
| status                      | ERROR                                                                                                                                                                                                                |
| updated                     | 2022-03-23T04:02:24Z                                                                                                                                                                                                 |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af                                                                                                                                                                                     |
| volumes_attached            |                                                                                                                                                                                                                      |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
[root@controller ~]#
[root@compute1 ~]# ssh compute1
[root@compute1 ~]# grep -i error /var/log/nova/*
...생략...
/var/log/nova/nova-compute.log:2022-03-23 13:02:22.993 4099 ERROR nova.compute.manager [req-ad8cc578-f4d3-435b-b781-173adfb4521b 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] Instance failed network setup after 1 attempt(s): PortBindingFailed: Binding failed for port 46812e80-9ed3-4ee0-910c-24716997b0d4, please check neutron logs for more information.
...생략...
[root@compute1 ~]# exit
[root@controller ~]# grep -i error /var/log/neutron/*
...생략...
/var/log/neutron/server.log:2022-03-23 13:02:13.607 20156 INFO neutron.api.v2.resource [req-161b3e9c-4017-4eb7-b164-1d7b0b9df117 8e9813079f73476b9ba29a6b8c3cf4af fdd6efd656374844a7d4a095736e21dd - default default] show failed (client error): The resource could not be found.
/var/log/neutron/server.log:2022-03-23 13:02:20.737 20156 ERROR neutron.plugins.ml2.managers [req-2ffb7f01-d456-4092-bf3e-67ba2c031f80 437174860bfa441dbb89ec82bfde89e3 b55d89a2f4f94c348417aabbd603c8b3 - default default] Failed to bind port 46812e80-9ed3-4ee0-910c-24716997b0d4 on host compute1 for vnic_type normal using segments [{'network_id': '163c6532-1576-4fc4-b527-0d0443c4a3ba', 'segmentation_id': None, 'physical_network': u'provider', 'id': 'ae319ffc-c127-4402-8582-82ff753b9aa4', 'network_type': u'flat'}]
...생략...
[root@controller ~]# ssh compute1
[root@compute1 ~]# cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[DEFAULT]
local_ip=10.0.0.31
```
* 원인: compute 노드에 `[linux_bridge]` 항목이 설정되어 있지 않음
* 조치
```
[root@compute1 ~]# cat /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[DEFAULT]
[linux_bridge]
physical_interface_mappings = provider:eth1
[vxlan]
local_ip=10.0.0.31
[root@compute1 ~]#
```
* 확인
```
[root@controller ~]# openstack server delete provider-instance
[root@controller ~]# openstack server create --flavor m1.nano --image cirros --nic net-id=163c6532-1576-4fc4-b527-0d0443c4a3ba --security-group default --key-name mykey provider-instance
+-----------------------------+-----------------------------------------------+
| Field                       | Value                                         |
+-----------------------------+-----------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                        |
| OS-EXT-AZ:availability_zone |                                               |
| OS-EXT-STS:power_state      | NOSTATE                                       |
| OS-EXT-STS:task_state       | scheduling                                    |
| OS-EXT-STS:vm_state         | building                                      |
| OS-SRV-USG:launched_at      | None                                          |
| OS-SRV-USG:terminated_at    | None                                          |
| accessIPv4                  |                                               |
| accessIPv6                  |                                               |
| addresses                   |                                               |
| adminPass                   | N5WkDewkpF6k                                  |
| config_drive                |                                               |
| created                     | 2022-03-23T05:05:12Z                          |
| flavor                      | m1.nano (0)                                   |
| hostId                      |                                               |
| id                          | 13ee677c-0045-4a21-904d-24ce02926467          |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6) |
| key_name                    | mykey                                         |
| name                        | provider-instance                             |
| progress                    | 0                                             |
| project_id                  | fdd6efd656374844a7d4a095736e21dd              |
| properties                  |                                               |
| security_groups             | name='7db0a045-c512-40cb-8ccd-518e849b1936'   |
| status                      | BUILD                                         |
| updated                     | 2022-03-23T05:05:12Z                          |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af              |
| volumes_attached            |                                               |
+-----------------------------+-----------------------------------------------+
[root@controller ~]# openstack server show provider-instance
+-----------------------------+----------------------------------------------------------+
| Field                       | Value                                                    |
+-----------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                   |
| OS-EXT-AZ:availability_zone | nova                                                     |
| OS-EXT-STS:power_state      | Running                                                  |
| OS-EXT-STS:task_state       | None                                                     |
| OS-EXT-STS:vm_state         | active                                                   |
| OS-SRV-USG:launched_at      | 2022-03-23T05:05:22.000000                               |
| OS-SRV-USG:terminated_at    | None                                                     |
| accessIPv4                  |                                                          |
| accessIPv6                  |                                                          |
| addresses                   | provider=192.168.137.242                                 |
| config_drive                |                                                          |
| created                     | 2022-03-23T05:05:12Z                                     |
| flavor                      | m1.nano (0)                                              |
| hostId                      | f5e70d240a781b940fc202032cb2f3fbbe6ae3ce1e3eb7bc10694ee7 |
| id                          | 13ee677c-0045-4a21-904d-24ce02926467                     |
| image                       | cirros (a7fb9dc2-8a39-44ae-9583-bb3a055547d6)            |
| key_name                    | mykey                                                    |
| name                        | provider-instance                                        |
| progress                    | 0                                                        |
| project_id                  | fdd6efd656374844a7d4a095736e21dd                         |
| properties                  |                                                          |
| security_groups             | name='default'                                           |
| status                      | ACTIVE                                                   |
| updated                     | 2022-03-23T05:05:22Z                                     |
| user_id                     | 8e9813079f73476b9ba29a6b8c3cf4af                         |
| volumes_attached            |                                                          |
+-----------------------------+----------------------------------------------------------+
[root@controller ~]#
```

### (control node)openstack server add floating ip, ResourceNotFound: 404, 

* 증상: 서버에 IP를 할당할 때 오류가 발생한다.
```
[root@controller ~]# . demo-openrc
[root@controller ~]# openstack floating ip list
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port | Floating Network                     | Project                          |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
| 05f02d5f-b6ff-4687-9af4-233da6e56175 | 192.168.137.211     | None             | None | 163c6532-1576-4fc4-b527-0d0443c4a3ba | fdd6efd656374844a7d4a095736e21dd |
+--------------------------------------+---------------------+------------------+------+--------------------------------------+----------------------------------+
[root@controller ~]# openstack server add floating ip selfservice-instance 192.168.137.211
ResourceNotFound: 404: Client Error for url: http://controller:9696/v2.0/floatingips/05f02d5f-b6ff-4687-9af4-233da6e56175, External network 163c6532-1576-4fc4-b527-0d0443c4a3ba is not reachable from subnet 6a713f14-62bf-4d74-ba4f-fe875203103d.  Therefore, cannot associate Port 3bab169f-49d2-4a77-8e58-4afd2c9d5fc6 with a Floating IP.
[root@controller ~]#
```
* 원인:
* 조치
* 확인




### (instence) hostname 에 novalocal 이라는 문구가 함께 표시된다.

* 증상: hostname 조회를 하면 인스턴스이름 뒤에 novalocal 이 함께 표시된다. ex) my-vm.novalocal
* 조치: `/etc/nova/nova.conf` 에서 `[DEFAULT]` 항목에 `dhcp_domain=`를 추가한다.
* 원인: 서버 IP를 할당할 때 기본 설정된 도메인인 novalocal을 함께 전달하여 발생함
* 참고: 오픈스택 nova 15.0이전에는 `nova.conf`에 15.0부터는 `dhcp_agent.ini`에 설정하여야 한다.
   * https://stackoverflow.com/questions/64500429/openstack-hostname-is-appended-by-novalocal
   * http://lists.openstack.org/pipermail/openstack/2017-March/019000.html


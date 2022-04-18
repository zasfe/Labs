## Verify  Openstack Service Status

## Mysql tcp 3306
```
ps aufx | grep mysql | grep -v grep
lsof -i tcp:3306
```

## rabbitmq-server tcp 25672
```
ps aufx | grep -i rabbitmq | grep -v grep
lsof -i tcp:25672
```
## memcached tcp 11211
```
ps aufx | grep -i memcached | grep -v grep
lsof -i tcp:11211
```
## etcd
```
ps aufx | grep -i etcd | grep -v grep
```

## Keystone


`# openstack-glance-api.service port tcp 9292`  
lsof -i tcp:9292  
`# openstack-glance-registry.service port tcp 9191`  
lsof -i tcp:9191  

## Nova

`# openstack-nova-api.service port tcp 8774`  
# lsof -i tcp:8774
ps aufx | grep nova-api

`# openstack-nova-scheduler.service port tcp 8775`  
lsof -i tcp:8775

`# openstack-nova placement endpoint port tcp 8778`  
lsof -i tcp:8778

`# openstack-nova vpn port tcp 6080`  
lsof -i tcp:6080

openstack compute service list
nova hypervisor-list

nova-status upgrade check  


## Neutron

`# openstack-neutron placement endpoint port tcp 9696`  
lsof -i tcp:9696

openstack network agent list
neutron agent-list

`# openstack-neutron-dhcp-agent port tcp -`  

`# openstack-neutron-l3-agent port tcp -`

`# openstack-neutron-metadata-agent port tcp -`

`# openstack-neutron-openvswitch-agent port tcp 6633`
lsof -i tcp:6633

## Horizon
```
ps aufx | grep -i httpd | grep -v grep
```


## Cinder


openstack volume service list
cinder service-list

`# openstack-cinder-scheduler port tcp -`

`# openstack-cinder-api port tcp 8776`
```
ps aufx | grep cinder-api | grep -v grep
lsof -i tcp:8776
```

`# openstack-cinder-volume port tcp -`


openstack catalog list  

`# cinder lvm volume`
ps aufx | grep lvmetad | grep -v lvmetad


systemctl restart openstack-cinder-volume


    

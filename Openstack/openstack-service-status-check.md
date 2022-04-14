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

# 1. docker setting

```
docker pull ubuntu:16.04
docker run -i -t --name hadoop ubuntu:16.04

> apt-get update
> apt-get install net-tools
> apt-get install vim
> apt-get install iputils-ping
> apt-get install wget
```

# 2. java install
* https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
* Linux x64용 jdk tar.gz


```
> mkdir -p /downloads/
> cd /downloads/

> wget --header "Cookie:oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.tar.gz
```



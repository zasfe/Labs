#!/bin/bash

SYSCTL="/etc/sysctl.conf"
LIMITS="/etc/security/limits.conf"
NPROC="/etc/security/limits.d/90-nproc.conf"

CleanSysctl () {
cat $SYSCTL | grep '^## For WEB Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WEB\ Server/,/^##\ End\ of\ WEB\ Server/d' $SYSCTL
fi
cat $SYSCTL | grep '^## For WAS Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WAS\ Server/,/^##\ End\ of\ WAS\ Server/d' $SYSCTL
fi
cat $SYSCTL | grep '^## For MYSQL Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ MYSQL\ Server/,/^##\ End\ of\ MYSQL\ Server/d' $SYSCTL
fi
}

CleanLmiits () {
cat $LIMITS | grep '^## For WEB Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WEB\ Server/,/^##\ End\ of\ WEB\ Server/d' $LIMITS
fi
cat $LIMITS | grep '^## For WAS Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WAS\ Server/,/^##\ End\ of\ WAS\ Server/d' $LIMITS
fi
cat $LIMITS | grep '^## For MYSQL Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ MYSQL\ Server/,/^##\ End\ of\ MYSQL\ Server/d' $LIMITS
fi
}

CleanNproc () {
cat $NPROC | grep '^## For WEB Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WEB\ Server/,/^##\ End\ of\ WEB\ Server/d' $NPROC
fi
cat $NPROC | grep '^## For WAS Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ WAS\ Server/,/^##\ End\ of\ WAS\ Server/d' $NPROC
fi
cat $NPROC | grep '^## For MYSQL Server' >& /dev/null
if [ $? == 0 ]; then
    sed -i '/^##\ For\ MYSQL\ Server/,/^##\ End\ of\ MYSQL\ Server/d' $NPROC
fi
}

WebServer () {
#WEB SYSCTL.CONF
CleanSysctl;

#cat $SYSCTL | grep ^kernel.shmall >& /dev/null
#if [ $? == 0 ]; then
#    sed -i 's/^kernel.shmall/\#kernel.shmall/g' $SYSCTL
#fi

cat $SYSCTL | grep ^kernel.sysrq >& /dev/null
if [ $? == 0 ]; then
    sed -i 's/^kernel.sysrq/\#kernel.sysrq/g' $SYSCTL
fi

cat >> $SYSCTL << EOF

## For WEB Server Parameter ##
kernel.sysrq = 1
kernel.panic_on_unrecovered_nmi = 1
kernel.unknown_nmi_panic = 1
vm.swappiness = 10
kernel.softlockup_thresh = 60
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_fin_timeout = 10
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 1440000
net.core.somaxconn = 16384
net.ipv4.tcp_mem = 8388608 12582912 16777216
net.ipv4.udp_mem = 8388608 12582912 16777216
## End of WEB Server Parameter ##
EOF

#WEB LIMITS.CONF
CleanLmiits;

cat >> $LIMITS << EOF
## For WEB Server Parameter ##
*           hard           nofile      65535
*           soft           nofile      65535
## End of WEB Server Parameter ##
EOF

#WEB 90-NPROC.CONF
CleanNproc;

sed -i '/nproc/d' /etc/security/limits.d/90-nproc.conf
cat >> $NPROC << EOF
## For WEB Server Parameter ##
#*          soft    nproc     1024
#root       soft    nproc     unlimited
## End of WEB Server Parameter ##
EOF
}

MysqlServer () {
#MYSQL SYSCTL.CONF
CleanSysctl;

#cat $SYSCTL | grep ^kernel.shmall >& /dev/null
#if [ $? == 0 ]; then
#    sed -i 's/^kernel.shmall/\#kernel.shmall/g' $SYSCTL
#fi

cat $SYSCTL | grep ^kernel.sysrq >& /dev/null
if [ $? == 0 ]; then
    sed -i 's/^kernel.sysrq/\#kernel.sysrq/g' $SYSCTL
fi

cat >> $SYSCTL << EOF

## For MYSQL Server Parameter ##
kernel.sysrq = 1
kernel.panic_on_unrecovered_nmi = 1
kernel.unknown_nmi_panic = 1
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 1440000
net.core.somaxconn = 16384
net.ipv4.tcp_mem = 8388608 12582912 16777216
net.ipv4.udp_mem = 8388608 12582912 16777216
## End of MYSQL Server Parameter ##
EOF

#MYSQL LIMITS.CONF
CleanLmiits;

cat >> $LIMITS << EOF
## For MYSQL Server Parameter ##
*           hard           nofile      10240
*           soft           nofile      10240
## End of MYSQL Server Parameter ##
EOF

#MYSQL 90-NPROC.CONF
CleanNproc;

sed -i '/nproc/d' /etc/security/limits.d/90-nproc.conf
cat >> $NPROC << EOF
## For MYSQL Server Parameter ##
#*          soft    nproc     1024
#root       soft    nproc     unlimited
## End of MYSQL Server Parameter ##
EOF
}

ARGS=1
E_BADARGS=65

if [ $# -ne $ARGS ]; then
  echo "Method: `basename $0` {web | was | mysql}"
  exit $E_BADARGS
fi

TargetConf=$1
function action
{
    WebServer
}

if [ "$1" == "web" ]; then
    action 
    echo "Successed Config of WEB Server Parameters."
    exit
fi

function action2
{
    WebServer
}

if [ "$1" == "was" ]; then
    action2
    sed -i 's/WEB\ Server\ Parameter/WAS\ Server\ Parameter/g' $SYSCTL
    sed -i 's/WEB\ Server\ Parameter/WAS\ Server\ Parameter/g' $LIMITS
    sed -i 's/WEB\ Server\ Parameter/WAS\ Server\ Parameter/g' $NPROC
    echo "Successed Config of WAS Server Parameters."
    exit
fi

function action3
{
    MysqlServer
}

if [ "$1" == "mysql" ]; then
    action3
    echo "Successed Config of MYSQL Server Parameters."
    exit
fi

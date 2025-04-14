#!/bin/bash
set -e

AJP_TOMCAT_HOST=10.9.89.24   # tomcat server ip
AJP_PORT=7019
MOD_JK_VER=1.2.49

MIRROR_current="https://downloads.apache.org/tomcat/tomcat-connectors/jk/"
MIRROR_archive="https://archive.apache.org/dist/tomcat/tomcat-connectors/jk/"
DOWNLOAD_DIR="/path/to/download/directory"


count_MIRROR_current=`wget -q $MIRROR_current -O - | grep "tomcat-connectors-$MOD_JK_VER-src.tar.gz" | wc -l`
count_MIRROR_archive=`wget -q $MIRROR_archive -O - | grep "tomcat-connectors-$MOD_JK_VER-src.tar.gz" | wc -l`

echo "[Apache] Apache + mod_jk install..."
yum install -y httpd gcc make wget openssl-devel redhat-rpm-config httpd-devel

mkdir -p ${DOWNLOAD_DIR}
echo "[Apache] mod_jk compile and install..."
if [ ! -f "${DOWNLOAD_DIR}/tomcat-connectors-$MOD_JK_VER-src.tar.gz" ]; then
    if [ $count_MIRROR_current -ge 0 ];then
      wget $MIRROR_current/tomcat-connectors-$MOD_JK_VER-src.tar.gz -O ${DOWNLOAD_DIR}/tomcat-connectors-$MOD_JK_VER-src.tar.gz
    fi
fi

if [ ! -f "${DOWNLOAD_DIR}/tomcat-connectors-$MOD_JK_VER-src.tar.gz" ]; then
    if [ $count_MIRROR_archive -ge 0 ];then
      wget $count_MIRROR_archive/tomcat-connectors-$MOD_JK_VER-src.tar.gz -O ${DOWNLOAD_DIR}/tomcat-connectors-$MOD_JK_VER-src.tar.gz
    fi
fi

if [ -f "${DOWNLOAD_DIR}/tomcat-connectors-$MOD_JK_VER-src.tar.gz" ]; then
    tar -xvzf tomcat-connectors-$MOD_JK_VER-src.tar.gz
    cd tomcat-connectors-$MOD_JK_VER-src/native
    ./configure --with-apxs=/bin/apxs
    make && make install
fi

echo "[Apache] mod_jk config file create..."
cat <<EOF > /etc/httpd/conf.d/mod_jk.conf
LoadModule jk_module modules/mod_jk.so
JkWorkersFile /etc/httpd/conf/workers.properties
JkLogFile /var/log/httpd/mod_jk.log
JkLogLevel info
JkMount /upload ajp_worker
EOF

cat <<EOF > /etc/httpd/conf/workers.properties
worker.list=ajp_worker
worker.ajp_worker.type=ajp13
worker.ajp_worker.host=$AJP_TOMCAT_HOST
worker.ajp_worker.port=$AJP_PORT
worker.ajp_worker.socket_timeout=7200
worker.ajp_worker.reply_timeout=7200000
worker.ajp_worker.socket_buffer=65536
worker.ajp_worker.connection_pool_size=20
EOF

echo "[Apache] vhost config..."
cat <<EOF > /etc/httpd/conf.d/vhost-tomcat.conf
<VirtualHost *:80>
    ServerName www.example.local
    ServerAlias example.local *.example.local

    Timeout 7200
    KeepAliveTimeout 7200

    JkMount /* ajp_worker
    LimitRequestBody 0

    ErrorLog logs/vhost-tomcat_error_log
    TransferLog logs/vhost-tomcat_access_log
    LogLevel warn
</VirtualHost>
EOF

echo "[Apache] service start..."
systemctl enable httpd
systemctl restart httpd

echo "[ Apache config complate] http://$(ip -o -4 addr show ${interface} scope global | awk '{print $4;}' | cut -d/ -f 1)/upload.html"

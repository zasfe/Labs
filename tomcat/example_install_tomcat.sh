#!/bin/bash
# ref - https://gist.github.com/drmalex07/e6e99dad070a78d5dab24ff3ae032ed1

# 1. Firstly go to root like user
sudo -s

# 2. create tomcat user
useradd --create-home --user-group --home-dir /opt/tomcat --system --shell /bin/false tomcat

# 3. Download tomcat
tomcat_version='10.1.5'
tomcat_major_version="${tomcat_version%%.*}"
curl -Lo/tmp/apache-tomcat-${tomcat_version}.tar.gz https://dlcdn.apache.org/tomcat/tomcat-${tomcat_major_version}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz
install -o tomcat -d tomcat -D /opt/tomcat/${tomcat_version}
tar xf /tmp/apache-tomcat-${tomcat_version}.tar.gz -C /opt/tomcat/${tomcat_version}/ --strip-components=1
pushd /opt/tomcat/
  ln -s ${tomcat_version} latest
popd
chown -R tomcat: /opt/tomcat/
find /opt/tomcat/ -type d -print0  | xargs -0 chmod 770
find /opt/tomcat/ -type f -print0   | xargs -0 chmod 660
find /opt/tomcat/ -type f -name '*.sh'  | xargs chmod 770

# 4. Create a tomcat service

# 4.1 Env var file

cat <<EOF> /etc/default/tomcat 
CATALINA_HOME=/opt/tomcat/latest
CATALINA_BASE=/opt/tomcat/latest
CATALINA_TMPDIR=/var/tmp/tomcat
JAVA_HOME=/usr/lib/jvm/jre
JAVA_OPTS=-Djava.security.egd=file:///dev/urandom
CATALINA_CLASSPATH=/opt/tomcat/latest/bin/bootstrap.jar:/opt/tomcat/latest/bin/tomcat-juli.jar
CATALINA_OPTS=-Djava.util.logging.config.file=/opt/tomcat/latest/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djdk.tls.ephemeralDHKeySize=2048 -Djava.protocol.handler.pkgs=org.apache.catalina.webresources -Dorg.apache.catalina.security.SecurityListener.UMASK=0027 --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED
EOF

# 4.2 Systemd service file

cat <<'EOF'> /etc/systemd/system/tomcat.service 
[Unit]
Description=Apache Tomcat Web Application Container
 
[Service]
[Unit]
Description=Apache Tomcat Web Application Container
 
[Service]
User=tomcat
Group=tomcat
RuntimeDirectory=tomcat
EnvironmentFile=-/etc/default/tomcat


ProtectSystem=strict
ProtectHome=yes
PrivateDevices=yes
PrivateTmp=yes
PrivateUsers=yes
ProtectKernelTunables=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ReadWritePaths=/opt/tomcat/latest/logs
ReadWritePaths=/opt/tomcat/latest/webapps
ReadWritePaths=/opt/tomcat/latest/work
ReadWritePaths=/opt/tomcat/latest/temp
RestrictAddressFamilies=AF_INET6 AF_INET
SystemCallArchitectures=native
SystemCallFilter=@system-service

ExecStart=/usr/bin/env ${JAVA_HOME}/bin/java \
${JAVA_OPTS} ${CATALINA_OPTS} \
-classpath ${CATALINA_CLASSPATH} \
-Dcatalina.base=${CATALINA_BASE} \
-Dcatalina.home=${CATALINA_HOME} \
-Djava.endorsed.dirs=${JAVA_ENDORSED_DIRS} \
-Djava.io.tmpdir=${CATALINA_TMPDIR} \
-Djava.util.logging.config.file=${CATALINA_BASE}/conf/logging.properties \
-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
org.apache.catalina.startup.Bootstrap \
start

ExecStop=/bin/kill -15 $MAINPID
#ExecStop=/usr/bin/env ${JAVA_HOME}/bin/java \
#${JAVA_OPTS} \
#-classpath ${CATALINA_CLASSPATH} \
#-Dcatalina.base=${CATALINA_BASE} \
#-Dcatalina.home=${CATALINA_HOME} \
#-Djava.endorsed.dirs=${JAVA_ENDORSED_DIRS} \
#-Djava.io.tmpdir=${CATALINA_TMPDIR} \
#-Djava.util.logging.config.file=${CATALINA_BASE}/conf/logging.properties \
#-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
#org.apache.catalina.startup.Bootstrap \
#stop

 
[Install]
WantedBy=multi-user.target
EOF

# 5. Enjoy

systemctl start tomcat
systemctl status tomcat
systemctl stop tomcat

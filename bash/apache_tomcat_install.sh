yum install httpd httpd-devel mod_ssl httpd-libtool
yum install httpd-devel
yum install mod_ssl
yum install httpd-libtool

wget http://mirror.navercorp.com/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
cd tomcat-connectors-1.2.48-src/native/
./buildconf.sh
./configure --with-apxs=/usr/bin/apxs
make
make install
/usr/lib64/httpd/modules/mod_jk.so

vim /etc/httpd/conf.d/workers.properties
worker.list=was
worker.was.type=ajp13
worker.was.host=localhost
worker.was.port=8009

vim /etc/httpd/conf.d/uriworkermap.properties
/*.do=was
/*.jsp=was

vi /etc/httpd/conf/httpd.conf
LoadModule jk_module modules/mod_jk.so

<IfModule jk_module>
  JkWorkersFile conf.d/workers.properties
  JkLogFile logs/mod_jk.log
  JkLogLevel info
  JkShmFile run/mod_jk.shm
  JkMountFile conf.d/uriworkermap.properties
</IfModule>



server.xml
    <Connector protocol="AJP/1.3"
               secretRequired="false"
               address="0.0.0.0"
               port="8009"
               maxPostSize="-1"
               redirectPort="8443" />

vi /usr/java/jdk1.8.0_311-amd64/jre/lib/security/java.security
securerandom.source=file:/dev/./urandom




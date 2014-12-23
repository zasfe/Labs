
#### Mysql User Add  ####

groupadd -g 600 dba
useradd -g 600 -u 605 mysql
passwd mysql


#### Linux Session Configure ####
## User Session Limits
# /etc/security/limits.conf
echo "" >> /etc/security/limits.conf
echo "mysql            soft    nproc           8192" >> /etc/security/limits.conf
echo "mysql            hard    nproc           16384" >> /etc/security/limits.conf
echo "mysql            soft    nofile          8192" >> /etc/security/limits.conf
echo "mysql            hard    nofile          16384" >> /etc/security/limits.conf
echo "session    required     pam_limits.so" >> /etc/pam.d/login


## User Default Limits
# /etc/profile
echo "" >> /etc/profile
echo "if [ \$USER = \"mysql\" ]; then" >> /etc/profile
echo "if [ \$SHELL = \"\/bin\/ksh\" ]; then" >> /etc/profile
echo "ulimit -p 16384" >> /etc/profile
echo "ulimit -n 65536" >> /etc/profile
echo "else" >> /etc/profile
echo "ulimit -u 16384 -n 65536" >> /etc/profile
echo "fi" >> /etc/profile
echo "fi" >> /etc/profile


## Mysql Store Create
mkdir -p /data/mysql/mysql-data
mkdir -p /data/mysql/mysql-tmp
mkdir -p /data/mysql/mysql-iblog
mkdir -p /data/mysql/mysql-binlog

#### Mysql Source Download ####
cd /usr/local/src

processor=`uname -p`;
if [ $processor = "x86_64" ]; then
wget http://dev.mysql.com/get/Downloads/MySQL-5.1/mysql-5.1.73-linux-x86_64-glibc23.tar.gz
tar xzvf mysql-5.1.73-linux-x86_64-glibc23.tar.gz
mv mysql-5.1.73-linux-x86_64-glibc23 /usr/local/
cd /usr/local
ln -s mysql-5.1.73-linux-x86_64-glibc23 mysql
else
wget http://dev.mysql.com/get/Downloads/MySQL-5.1/mysql-5.1.73-linux-i686-glibc23.tar.gz
tar xzvf mysql-5.1.73-linux-i686-glibc23.tar.gz
mv mysql-5.1.73-linux-i686-glibc23 /usr/local/
cd /usr/local
ln -s mysql-5.1.73-linux-i686-glibc23 mysql
fi

wget --no-check-certificate -O /etc/my.cnf https://raw.githubusercontent.com/mysonnet/CentOS/MySQL//master/Mysql5.1_My.cnf_Sample1

chown -R mysql.dba /usr/local/mysql*
cp mysql/support-files/mysql.server /etc/init.d/mysqld
chown -R mysql.dba /data/mysql/*
chown mysql.dba /etc/my.cnf
chown mysql.dba /usr/local/mysql*

cp mysql/support-files/mysql.server /etc/init.d/mysqld


# /home/mysql/.bash_profile
echo "" >> /home/mysql/.bash_profile
echo "export MYSQL_HOME=/usr/local/mysql" >> /home/mysql/.bash_profile
echo "export PATH=\$PATH:\$MYSQL_HOME/bin:." >> /home/mysql/.bash_profile
echo "export ADMIN_PWD=\"P@ssw0rd\"" >> /home/mysql/.bash_profile
echo "" >> /home/mysql/.bash_profile
echo "alias ll=\"ls -al --color=auto\"" >> /home/mysql/.bash_profile
echo "alias mydba=\"mysql -uroot -p\$ADMIN_PWD\"" >> /home/mysql/.bash_profile
echo "alias mymaster=\"mysql -uroot -p\$ADMIN_PWD -e'show master status;'\"" >> /home/mysql/.bash_profile
echo "alias myslave=\"mysql -uroot -p\$ADMIN_PWD -e'show slave status\G'\"" >> /home/mysql/.bash_profile
echo "alias mh=\"cd \$MYSQL_HOME\"" >> /home/mysql/.bash_profile
echo "alias md=\"cd /data/mysql/mysql-data\"" >> /home/mysql/.bash_profile
echo "alias mt=\"cd /data/mysql/mysql-tmp\"" >> /home/mysql/.bash_profile
echo "alias mb=\"cd /data/mysql/mysql-binlog\"" >> /home/mysql/.bash_profile
echo "alias mi=\"cd /data/mysql/mysql-data\"" >> /home/mysql/.bash_profile
echo "alias dp=\"cd /data/mysql/mysql-data\"" >> /home/mysql/.bash_profile

. /home/mysql/.bash_profile



## Mysql Start ##


cd /usr/local/mysql
## 기본 데이터베이스 설치
./scripts/mysql_install_db
## MySQL 데몬 Startup
/etc/init.d/mysqld start


## 

cd /usr/local/mysql
./bin/mysql_secure_installation


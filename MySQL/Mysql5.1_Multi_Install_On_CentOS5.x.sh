##### Mysqld_Multi #####


#### Mysql User Add  ####

groupadd -g 600 dba
useradd -g 600 -u 605 mysql

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
echo "if [ \$USER = \"mysql\" \|\| \$USER = \"mysql2\" ]; then" >> /etc/profile
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
  /bin/cp mysql-5.1.73-linux-x86_64-glibc23 /usr/local/mysql
else
  wget http://dev.mysql.com/get/Downloads/MySQL-5.1/mysql-5.1.73-linux-i686-glibc23.tar.gz
  tar xzvf mysql-5.1.73-linux-i686-glibc23.tar.gz
  /bin/cp mysql-5.1.73-linux-i686-glibc23 /usr/local/mysql
fi

wget --no-check-certificate -O /etc/my.cnf https://raw.githubusercontent.com/zasfe/Labs/MySQL/master/Mysql5.1_Multi_My.cnf_Sample1

chown -R mysql.dba /usr/local/mysql

cp mysql/support-files/mysql.server /etc/init.d/mysqld


chown -R mysql.dba /data/mysql/*
chown mysql.dba /etc/my.cnf
chown mysql.dba /usr/local/mysql*



# /home/mysql/.bash_profile
PROFILE_MYSQL="/home/mysql/.bash_profile";
echo "" >> ${PROFILE_MYSQL}
echo "export MYSQL_HOME=/usr/local/mysql" >> ${PROFILE_MYSQL}
echo "export PATH=\$PATH:\$MYSQL_HOME/bin:." >> ${PROFILE_MYSQL}
echo "export ADMIN_PWD=\"P@ssw0rd\"" >> ${PROFILE_MYSQL}
echo "" >> ${PROFILE_MYSQL}
echo "alias ll=\"ls -al --color=auto\"" >> ${PROFILE_MYSQL}
echo "alias mydba=\"mysql -uroot -p\$ADMIN_PWD\"" >> ${PROFILE_MYSQL}
echo "alias mymaster=\"mysql -uroot -p\$ADMIN_PWD -e'show master status;'\"" >> ${PROFILE_MYSQL}
echo "alias myslave=\"mysql -uroot -p\$ADMIN_PWD -e'show slave status\G'\"" >> ${PROFILE_MYSQL}
echo "alias mh=\"cd \$MYSQL_HOME\"" >> ${PROFILE_MYSQL}
. ${PROFILE_MYSQL}

#### Mysql Start ####
cd /usr/local/mysql
## 기본 데이터베이스 설치
./scripts/mysql_install_db --user=mysql

## MySQL 데몬 Startup 
/etc/init.d/mysqld start

## Mysql Security
cd /usr/local/mysql
./bin/mysql_secure_installation


##### Mysqld_Multi Expansion #####

## MySQL 데몬 Stop
/etc/init.d/mysqld stop

#### Mysql Config Download ####
cd /usr/local/src
wget --no-check-certificate -O /etc/my.cnf https://raw.githubusercontent.com/zasfe/Labs/master/Mysql5.1_Multi_My.cnf_Sample1
chown mysql.dba /etc/my.cnf


## Mysql2 Store Create
mkdir -p /data/mysql2/mysql-data
mkdir -p /data/mysql2/mysql-tmp
mkdir -p /data/mysql2/mysql-iblog
mkdir -p /data/mysql2/mysql-binlog

cd /usr/local/mysql
cp mysql/support-files/mysqld_multi.server /etc/init.d/mysqld_multi

chown -R mysql.dba /data/mysql2/*

cat /data/mysql2/mysql-binlog | sed -e "s/\/data\/mysql\/mysql-binlog/\/data\/mysql2\/mysql-binlog/g" > /data/mysql2/mysql-binlog.tmp
/bin/cp -pa /data/mysql2/mysql-binlog.tmp /data/mysql2/mysql-binlog

## MySQL 데몬 Startup
/etc/init.d/mysqld_multi start



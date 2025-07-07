#!/bin/bash


cat <<EOF > ./sql_create_user_zbx_monitor
CREATE OR REPLACE USER 'zbx_monitor'@'%' IDENTIFIED BY '<password>';
GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW,SLAVE MONITOR ON *.* TO 'zbx_monitor'@'%';
FLUSH PRIVILEGES;
EOF

/usr/bin/mariadb -uroot < ./sql_create_user_zbx_monitor

mkdir -p /var/lib/zabbix
cat <<EOF > /var/lib/zabbix/.my.cnf
[client]
protocol=tcp
user='zbx_monitor'
password='zabbix!!'
EOF

cat << 'EOF' > /etc/zabbix/zabbix_agentd.d/template_db_mysql.conf
UserParameter=mysql.ping[*], mysqladmin -h"$1" -P"$2" ping
UserParameter=mysql.get_status_variables[*], mysql -h"$1" -P"$2" -sNX -e "show global status"
UserParameter=mysql.version[*], mysqladmin -s -h"$1" -P"$2" version
UserParameter=mysql.db.discovery[*], mysql -h"$1" -P"$2" -sN -e "show databases"
UserParameter=mysql.dbsize[*], mysql -h"$1" -P"$2" -sN -e "SELECT COALESCE(SUM(DATA_LENGTH + INDEX_LENGTH),0) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$3'"
UserParameter=mysql.replication.discovery[*], mysql -h"$1" -P"$2" -sNX -e "show slave status"
UserParameter=mysql.slave_status[*], mysql -h"$1" -P"$2" -sNX -e "show slave status"
EOF

systemctl restart zabbix-agent

## Mysql Master backup
mysql -uroot -p --host=127.0.0.1 --port=3306 -e "GRANT REPLICATION SLAVE ON *.* TO replicant@'%' IDENTIFIED BY 'secretslave';"
mysqldump -uroot -p --host=127.0.0.1 --port=3306 --all-databases --master-data=2 > master_a.sql

## Mysql Slave Restore
MASTER_LOG_FILE=`grep "MASTER\_LOG\_POS\=" master_a.sql | grep MASTER_LOG_FILE | head -n 1 | awk -F= '{print$2}' | sed -e "s/'//g" | awk -F, '{print$1}'`;
MASTER_LOG_POS=`grep "MASTER\_LOG\_POS\=" master_a.sql | grep MASTER_LOG_FILE | head -n 1 | awk -F= '{print$3}' | sed -e 's/;//g'`;
mysql -uroot -p --host=127.0.0.1 --port=3307 -e "CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_USER='replicant', MASTER_PASSWORD='secretslave', MASTER_LOG_FILE='${MASTER_LOG_FILE}', MASTER_LOG_POS=${MASTER_LOG_POS};";

## Mysql Slave Start
mysql -uroot -p --host=127.0.0.1 --port=3307 -e "START SLAVE;"

## Mysql Slave Status
mysql -uroot -p --host=127.0.0.1 --port=3307 -e "SHOW SLAVE STATUS \G"

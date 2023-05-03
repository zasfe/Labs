#!/bin/bash
# - tomcat log archive

folder_tomcat_logs="/usr/local/tomcat/logs"
folder_backup="/data/tomcat8_log/"

# 3 Days old file move
find ${folder_tomcat_logs} -type f -name "catalina*.out-*" -mtime +3 -exec mv {} ${folder_backup} \;
  
# 30 Days old file move
find ${folder_tomcat_logs} -maxdepth 1 -type f -name "*.log" -mtime +30 -exec mv {} ${folder_backup} \;
 
# 60 Days old file compressed
cd ${folder_backup}
find ${folder_backup} -maxdepth 1 -type f -name "*" -and ! -name "*.tar.gz" -mtime +60 -exec sh -c "tar -zcvf {}.tar.gz {}; rm -f {};" \;
 
exit 0
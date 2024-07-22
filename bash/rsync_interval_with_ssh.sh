#!/bin/bash
  
if [[ -z ""${SYNC_INTERVAL}"" ]]; then
  export SYNC_INTERVAL=2
fi

while :
do
    rsync -avz -e ""sshpass -p '{SSH USER PASSWORD}' ssh -p {SSH 포트}"" {SSH USER ID}@{SSH HOST}:/src_mount_dir /dist_mount_dir
    sleep ${SYNC_INTERVAL}
done

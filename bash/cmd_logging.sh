#!/bin/sh

LV=`cat /etc/redhat-release | awk '{print $3}' | awk -F "." '{print $1}'`

if [[ $LV < 6 ]]
then
SYSLOGD="syslog"
else
SYSLOGD="rsyslog"
fi

cat <<EEE>> /etc/profile.d/cmd_logging.sh
function logging
{
  stat="\$?"
    cmd=\$(history|tail -1)
    if [ "\$cmd" != "$cmd_old" ]; then
      logger -p local1.notice "[2] 1-RESULT_CODE=\$stat"
      logger -p local1.notice "[1] PID=\$\$, PWD=\$PWD, CMD=\$cmd"
    fi
  cmd_old=\$cmd
}
trap logging DEBUG
EEE

chmod 755 /etc/profile.d/cmd_logging.sh
echo "local1.notice                                /var/log/.hi/cmd.log" >> /etc/${SYSLOGD}.conf

sleep 3

service ${SYSLOGD} restart

mkdir /var/log/.hi
chmod 700 /var/log/.hi

sed -i 's#/var/log/cron#/var/log/cron /var/log/.hi/cmd.log#' /etc/logrotate.d/syslog


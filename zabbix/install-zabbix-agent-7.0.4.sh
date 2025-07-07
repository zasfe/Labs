#!/bin/bash

cd /usr/local/src
wget https://repo.zabbix.com/zabbix/7.0/rocky/8/x86_64/zabbix-agent-7.0.4-release1.el8.x86_64.rpm
rpm -Uvh zabbix-agent-7.0.4-release1.el8.x86_64.rpm

PidFile=/run/zabbix/zabbix_agentd_managed.pid
LogFile=/dev/null
DebugLevel=1
ServerActive=45.115.154.252:10051
StartAgents=0
HostMetadata=linux gcloud gen1 classic
UserParameter=web.response.time[*],curl -o /dev/null -s -w "%{time_total}" "$1"
EOF
echo "Hostname=vm-gen1-classic-$(hostname -I | awk '{print $1}' | sed -e 's/\./-/g')" | tee -a /etc/zabbix/zabbix_agentd_managed.conf

echo << 'EOF' > /usr/lib/systemd/system/zabbix-agent-managed.service
[Unit]
Description=Zabbix Agent Custom
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_agentd_managed.conf"
EnvironmentFile=-/etc/sysconfig/zabbix-agent
Type=forking
Restart=on-failure
PIDFile=/run/zabbix/zabbix_agentd_managed.pid
KillMode=control-group
ExecStart=/usr/sbin/zabbix_agentd -c $CONFFILE
ExecStop=/bin/kill -SIGTERM $MAINPID
RestartSec=10s
User=zabbix
Group=zabbix

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload
systemctl --now enable zabbix-agent-managed
systemctl status zabbix-agent-managed

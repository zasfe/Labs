#!/bin/bash

cd /usr/local/src
wget https://repo.zabbix.com/zabbix/7.0/rocky/8/x86_64/zabbix-agent-7.0.4-release1.el8.x86_64.rpm
rpm -Uvh zabbix-agent-7.0.4-release1.el8.x86_64.rpm

echo << 'EOF' > /etc/zabbix/zabbix_agentd_managed.conf
PidFile=/run/zabbix/zabbix_agentd_managed.pid
LogFile=/dev/null
DebugLevel=1

# Active 체크 전용 설정
Server=                               # Passive 방식 비활성화
ListenPort=0                          # Passive 리스닝 포트 비활성화
StartAgents=0                         # Passive 워커 비활성화

ServerActive=127.0.0.1:10051
RefreshActiveChecks=30                # Active 체크 주기(초)
BufferSize=200                        # Active 응답 버퍼 크기

# 타임아웃 확장: 복잡한 스크립트 처리 대비
Timeout=20

HostMetadata=linux seroul
UserParameter=web.response.time[*],curl -o /dev/null -s -w "%{time_total}" "$1"
EOF
echo "Hostname=vm-seoul1-$(hostname -I | awk '{print $1}' | sed -e 's/\./-/g')" | tee -a /etc/zabbix/zabbix_agentd_managed.conf

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

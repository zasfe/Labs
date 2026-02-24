# How To Rocky Linux

1. 환경파일 생성

```bash
sudo tee /etc/sysconfig/tomcat >/dev/null <<'EOF'
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.482.b08-1.el9.x86_64
CATALINA_HOME=/data/tomcat
CATALINA_BASE=/data/tomcat
CATALINA_PID=/data/tomcat/temp/tomcat.pid

# 필요 시만 사용 (없어도 최소 구동 가능)
# CATALINA_OPTS="-Xms512m -Xmx1024m -Djava.awt.headless=true"
EOF
```

2. systemd 유닛 파일 생성

```ini
# /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat 8.5 (Standalone)
After=network.target

[Service]
Type=forking
User=root
Group=root

EnvironmentFile=-/etc/sysconfig/tomcat
Environment="PATH=/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

ExecStart=/data/tomcat/bin/startup.sh
ExecStop=/data/tomcat/bin/shutdown.sh

SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

3. 적용

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat
sudo systemctl restart tomcat
```

4. 확인(서비스 환경변수 포함)

```bash
systemctl show tomcat -p Environment
/data/tomcat/bin/version.sh
```

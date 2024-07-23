#!/bin/bash
LANG=C

groupadd -r prometheus
useradd -r -g prometheus -s /sbin/nologin -d /home/prometheus/ -c "prometheus Daemons" prometheus

mkdir -p /data/monitor/
mkdir -p /data/monitor/data/

cd /data/monitor/
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar -xf node_exporter-1.8.2.linux-amd64.tar.gz
ln -s node_exporter-1.8.2.linux-amd64 node_exporter

test -f /etc/systemd/system/node_exporter.service && cp -pa /etc/systemd/system/node_exporter.service /data/monitor/node_exporter/node_exporter.service.$(date '+%Y-%m-%dZ%H:%M:%S')
cat <<EOF > /etc/systemd/system/node_exporter.service
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/data/monitor/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo chown -R prometheus:prometheus /data/monitor/node_exporter

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
systemctl status node_exporter.service

curl http://127.0.0.1:9100/metrics




cd /data/monitor/
wget https://github.com/prometheus/prometheus/releases/download/v2.45.6/prometheus-2.45.6.linux-amd64.tar.gz
tar -xf prometheus-2.45.6.linux-amd64.tar.gz

ln -s prometheus-2.45.6.linux-amd64 prometheus

test -f /data/monitor/prometheus/prometheus.yml && cp -pa /data/monitor/prometheus/prometheus.yml /data/monitor/prometheus/prometheus.yml.$(date '+%Y-%m-%dZ%H:%M:%S')
cat <<EOF > /data/monitor/prometheus/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  #- job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

        #  static_configs:
        #  - targets: ["localhost:9090"]

  - job_name: "web-server"

    static_configs:
      - targets: ["127.0.0.1:9100"]
EOF

test -f /etc/systemd/system/prometheus.service && cp -pa /etc/systemd/system/prometheus.service /data/monitor/prometheus/prometheus.service.$(date '+%Y-%m-%dZ%H:%M:%S')

cat <<EOF > /etc/systemd/system/prometheus.service
## /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/data/monitor/prometheus/prometheus \
  --config.file=/data/monitor/prometheus/prometheus.yml \
  --storage.tsdb.path=/data/monitor/prometheus_data \
  --web.console.templates=/data/monitor/prometheus/consoles \
  --web.console.libraries=/data/monitor/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:8989 \
  --web.enable-admin-api
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /data/monitor/prometheus_data
chown -R prometheus:prometheus /data/monitor/prometheus
chown -R prometheus:prometheus /data/monitor/prometheus_data
chown -R prometheus:prometheus /data/monitor/prometheus-*

systemctl daemon-reload
systemctl enable prometheus.service
systemctl restart prometheus.service





cd /data/monitor/
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-11.1.0.linux-amd64.tar.gz
tar -zxvf grafana-enterprise-11.1.0.linux-amd64.tar.gz
ln -s grafana-v11.1.0 grafana

cat <<EOF > /usr/lib/systemd/system/grafana-server.service
[Unit]
Description=Grafana instance
Documentation=http://docs.grafana.org
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=grafana
Group=grafana
ExecStart=/data/monitor/grafana/bin/grafana-server \
  --config=/data/monitor/grafana/conf/defaults.ini \
  --homepath=/data/monitor/grafana \
Restart=always

[Install]
WantedBy=multi-user.target
EOF


groupadd -r grafana
useradd -r -g grafana -s /sbin/nologin -d /home/grafana/ -c "grafana Daemons" grafana
chown -R grafana:grafana /data/monitor/grafana
chown -R grafana:grafana /data/monitor/grafana-v*

systemctl daemon-reload
systemctl enable grafana-server.service
systemctl restart grafana-server.service


# Adding datasource without using the web gui (https://github.com/grafana/grafana/issues/1789)
curl --user admin:admin ' http://127.0.0.1:3000/api/datasources ' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"prometheusLocal","isDefault":true ,"type":"prometheus","url":" http://127.0.0.1:9090","access":"proxy","basicAuth":false} '


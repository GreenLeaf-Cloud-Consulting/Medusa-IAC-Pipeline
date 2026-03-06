#!/bin/bash
set -e

# Install Docker via official Docker repo (Debian 12)
apt-get update -y
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker

# Create monitoring directory structure
mkdir -p /opt/monitoring/prometheus
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/grafana/dashboards

# Create Prometheus configuration with all monitored instances
cat > /opt/monitoring/prometheus/prometheus.yml <<'PROMCFG'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
%{ for instance in monitored_instances ~}
      - targets: ['${instance.private_ip}:9100']
        labels:
          instance: '${instance.name}'
%{ endfor ~}
PROMCFG

# Create Grafana datasource provisioning
cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml <<'DSCFG'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
DSCFG

# Create Grafana dashboard provisioning config
cat > /opt/monitoring/grafana/provisioning/dashboards/dashboards.yml <<'DBCFG'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: false
DBCFG

# Download the standard Node Exporter Full dashboard JSON
curl -o /opt/monitoring/grafana/dashboards/node-exporter-full.json \
  https://grafana.com/api/dashboards/1860/revisions/37/download

# Fix the datasource reference in the downloaded dashboard
sed -i 's/$${DS_PROMETHEUS}/Prometheus/g' /opt/monitoring/grafana/dashboards/node-exporter-full.json

# Create Docker Compose file
cat > /opt/monitoring/docker-compose.yml <<'COMPOSE'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    depends_on:
      - prometheus

volumes:
  prometheus_data:
  grafana_data:
COMPOSE

# Start the monitoring stack
cd /opt/monitoring
docker compose up -d

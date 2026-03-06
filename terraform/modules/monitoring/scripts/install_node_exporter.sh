#!/bin/bash
set -e

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
  aarch64) ARCH_SUFFIX="arm64" ;;
  x86_64)  ARCH_SUFFIX="amd64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Update system packages
apt-get update -y

# Install node_exporter
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH_SUFFIX}.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH_SUFFIX}.tar.gz"
cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH_SUFFIX}/node_exporter" /usr/local/bin/
rm -rf node_exporter-*

# Create a dedicated user for node_exporter
useradd --no-create-home --shell /bin/false node_exporter || true

# Create systemd service
cat > /etc/systemd/system/node_exporter.service <<'UNIT'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
UNIT

# Start node_exporter
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

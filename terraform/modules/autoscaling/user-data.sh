#!/bin/bash
# ==========================================
# USER DATA SCRIPT FOR AUTO SCALING INSTANCES
# ==========================================

set -e

# Variables
REGION="${region}"
ENVIRONMENT="${environment}"

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "==========================================
Starting instance initialization
Environment: $ENVIRONMENT
Region: $REGION
=========================================="

# Update system
apt-get update
apt-get upgrade -y

# Install basic tools
apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  python3 \
  python3-pip

# Install CloudWatch Agent (pour monitoring avancé)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Install Node.js (pour Medusa)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Docker (si besoin)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Add admin user to docker group
usermod -aG docker admin || true

echo "Instance initialization complete!"

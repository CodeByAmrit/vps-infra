#!/bin/bash

set -e

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y docker.io docker-compose-plugin ufw fail2ban curl

sudo systemctl enable docker
sudo systemctl start docker

echo "Creating Docker proxy network..."
docker network create proxy || true

# -----------------------------
# UFW Basic Rules
# -----------------------------
echo "Configuring UFW..."

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow OpenSSH

# Allow Cloudflare IP ranges for HTTP/HTTPS
echo "Fetching Cloudflare IP ranges..."

CF_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

for ip in $CF_IPV4; do
    sudo ufw allow from $ip to any port 80
    sudo ufw allow from $ip to any port 443
done

for ip in $CF_IPV6; do
    sudo ufw allow from $ip to any port 80
    sudo ufw allow from $ip to any port 443
done

sudo ufw --force enable

# -----------------------------
# Fail2Ban Configuration
# -----------------------------
echo "Configuring Fail2Ban..."

sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

echo "Hardened VPS setup complete."

cd /home/ubuntu/
git clone https://github.com/codebyamrit/vps-infra.git
cd vps-infra
mkdir -p secrets

echo "CF_TOKEN_FOR_AMRIT_DOMAIN" > secrets/cf_main_token
echo "CF_TOKEN_FOR_STREAM_DOMAIN" > secrets/cf_stream_token

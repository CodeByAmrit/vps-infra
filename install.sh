#!/bin/bash

set -e

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing Docker..."
sudo apt install -y docker.io docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "Creating proxy network..."
docker network create proxy || true

echo "Configuring firewall..."
sudo apt install -y ufw

sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "Installation complete."
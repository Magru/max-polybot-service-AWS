#!/bin/bash

# Update the package index
sudo apt-get update -y

# Install Docker
sudo apt-get install -y docker.io

# Enable Docker service to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: Docker installation failed' >&2
  exit 1
fi

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: Docker Compose installation failed' >&2
  exit 1
fi

# Create the directory for the docker-compose and .env files
mkdir -p /home/ubuntu/polybot

# Write the docker-compose.yaml file
cat <<EOL > /home/ubuntu/polybot/docker-compose.yaml
version: '3'
services:
  polybot:
    image: \${POLYBOT_IMG_NAME}
    container_name: polybot
    env_file:
      - .env
    ports:
      - "8443:8443"
    tty: true
    stdin_open: true
    restart: always
EOL

# Write the .env file
cat <<EOL > /home/ubuntu/polybot/.env
POLYBOT_IMG_NAME=magrufol/polybot:2.0.7
EOL

# Change directory to where docker-compose.yaml is located and run docker-compose up
cd /home/ubuntu/polybot
sudo docker-compose up -d
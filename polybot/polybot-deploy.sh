#!/bin/bash

# Navigate to the polybot directory
cd /home/ubuntu/polybot

# Generate .env file
cat <<EOT > .env
POLYBOT_IMAGE_NAME=${POLYBOT_IMAGE_NAME}
POLYBOT_IMAGE_VERSION=${POLYBOT_IMAGE_VERSION}
IMAGES_BUCKET_NAME=${IMAGES_BUCKET_NAME}
EOT

# Start the Docker containers
sudo docker-compose up -d

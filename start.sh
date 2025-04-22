#!/bin/bash

# Show usage
usage() {
  echo "Usage: $0 <MAIL_HOSTNAME> <MAIL_DOMAIN>"
  echo "Example: $0 mail.example.com example.com"
  exit 1
}

# Check args
if [ $# -lt 2 ]; then
  echo "Error: Missing arguments."
  usage
fi

# Set variables
MAIL_HOSTNAME=$1
MAIL_DOMAIN=$2
CONTAINER_NAME="postfix-container"

echo "Using MAIL_HOSTNAME=$MAIL_HOSTNAME and MAIL_DOMAIN=$MAIL_DOMAIN"

# Check if container exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "Container $CONTAINER_NAME exists. Stopping and removing..."
  docker kill $CONTAINER_NAME
  docker rm $CONTAINER_NAME
else
  echo "Container $CONTAINER_NAME not found. Creating..."
fi

# Build
docker build -t postfix-container .

# Run container with passed envs
docker run \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -e MAIL_HOSTNAME="$MAIL_HOSTNAME" \
  -e MAIL_DOMAIN="$MAIL_DOMAIN" \
  -p 25:25 \
  postfix-container

echo "Container $CONTAINER_NAME is running."

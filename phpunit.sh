#!/bin/bash

# Colors
RD='\033[0;31m'
GR='\033[0;32m'
YL='\033[0;33m'
BL='\033[0;34m'
NC='\033[0m'

IMAGE_TAG=""
if [ -n "$PHP_IMAGE_TAG" ]; then
  IMAGE_TAG="$PHP_IMAGE_TAG"
fi

if [ -n "$INPUT_PHP_IMAGE_TAG" ]; then
  IMAGE_TAG="$INPUT_PHP_IMAGE_TAG"
fi

if [ -z "$IMAGE_TAG" ]; then
  echo -e "${RD}ERROR:${NC} No PHP image tag provided"
  exit 1
fi

IMAGE="quay.io/adoreme/nginx-fpm-alpine:$IMAGE_TAG"

echo -e "${BL}INFO:${NC} Running PHPUnit with image: ${GR}nginx-fpm-alpine:$IMAGE${NC}"
docker run \
  --platform linux/amd64 \
  -v "$PWD":/var/www \
  "$IMAGE" \
  /bin/bash -c "./vendor/bin/phpunit --configuration=./phpunit.xml --log-junit=${INPUT_REPORT_PATH}"

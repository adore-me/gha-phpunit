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
  echo "::error::No PHP image tag provided"
  exit 1
fi

IMAGE="quay.io/adoreme/nginx-fpm-alpine:$IMAGE_TAG"

addHost=""
if [ "$INPUT_ENABLE_MYSQL" == "true" ]; then
  if [ -z "$DB_HOST" ]; then
    echo "::error:: No DB_HOST provided, but MySql is enabled. Please checks logs above for errors."
    exit 1
  fi

  addHost="--add-host=mysql.local:$DB_HOST"
  echo -e "${BL}Info:${NC} MySql host provided: $DB_HOST"
  echo -e "${BL}Info:${NC} Running PHP container with \`$addHost\`"

  echo -e "${BL}Info:${NC} Running migrations with image: ${GR}nginx-fpm-alpine:$IMAGE${NC}"
  docker run \
    --platform linux/amd64 \
    --network=bridge "$addHost" \
    --add-host=mysql.gha:"$DB_HOST" \
    -e DB_HOST=mysql.gha -e DB_HOST_WRITE=mysql.gha -e DB_HOST_READ=mysql.gha -e DB_DATABASE=adoreme -e DB_USERNAME=adoreme -e DB_PASSWORD=secret \
    -v "$PWD":/var/www \
    "$IMAGE" \
    "/bin/bash" "-c" "php artisan migrate -n --force"
fi

echo -e "${BL}Info:${NC} Running PHPUnit with image: ${GR}nginx-fpm-alpine:$IMAGE${NC}"
docker run \
  --platform linux/amd64 \
  --network=bridge "$addHost" \
  --add-host=mysql.gha:"$DB_HOST" \
  -v "$PWD":/var/www \
  "$IMAGE" \
  "/bin/bash" "-c" "./vendor/bin/phpunit --configuration=./phpunit.xml --log-junit=${INPUT_REPORT_PATH}"

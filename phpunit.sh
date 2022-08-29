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
  if [ -z "$MYSQL_HOST" ]; then
    echo "::error:: No MYSQL_HOST provided, but MySql is enabled. Please checks logs above for errors."
    exit 1
  fi

  addHost="--add-host=mysql.gha:$MYSQL_HOST"
  echo -e "${BL}Info:${NC} MySql host provided: $MYSQL_HOST"
  echo -e "${BL}Info:${NC} Running PHP container with \`$addHost\`"

  echo -e "${BL}Info:${NC} Running migrations with image: ${GR}nginx-fpm-alpine:$IMAGE${NC}"
  docker run \
    --platform linux/amd64 \
    --network=bridge "$addHost" \
    --add-host=mysql.gha:"$MYSQL_HOST" \
    -e MYSQL_HOST=mysql.gha -e DB_HOST_WRITE=mysql.gha -e DB_HOST_READ=mysql.gha -e DB_DATABASE=adoreme -e DB_USERNAME=adoreme -e DB_PASSWORD=secret \
    -v "$PWD":/var/www \
    "$IMAGE" \
    "/bin/bash" "-c" "php artisan migrate -n --force"
fi

if [ "$INPUT_ENABLE_REDIS" == "true" ]; then
  if [ -z "$REDIS_HOST" ]; then
    echo "::error:: No REDIS_HOST provided, but Redis is enabled. Please checks logs above for errors."
    exit 1
  fi

  addHost+=" --add-host=redis.gha:$REDIS_HOST"
  echo -e "${BL}Info:${NC} Redis host provided: $REDIS_HOST"
  echo -e "${BL}Info:${NC} Running PHP container with \`$addHost\`"
fi

echo -e "${BL}Info:${NC} Running PHPUnit with image: ${GR}nginx-fpm-alpine:$IMAGE${NC}"
docker run \
  --platform linux/amd64 \
  --network=bridge "$addHost" \
  -v "$PWD":/var/www \
  "$IMAGE" \
  "/bin/bash" "-c" "./vendor/bin/phpunit --configuration=./phpunit.xml --log-junit=${INPUT_REPORT_PATH}"

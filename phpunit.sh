#!/bin/bash

# Colors
RD='\033[0;31m'
GR='\033[0;32m'
YL='\033[0;33m'
BL='\033[0;34m'
NC='\033[0m'

# Constants
mysqlHost="mysql.gha"
redisHost="redis.gha"

if [ -z "$INPUT_PHP_IMAGE" ]; then
  echo "::error::No PHP image provided"
  exit 1
fi

phpUnitCmd="./vendor/bin/phpunit --configuration=./phpunit.xml --log-junit=$INPUT_REPORT_PATH"
if [ "$INPUT_WITH_COVERAGE" == "true" ]; then
  INPUT_PHP_IMAGE="${INPUT_PHP_IMAGE}-dev"
  phpUnitCmd="php -d xdebug.mode=coverage ./vendor/bin/phpunit --configuration=./phpunit.xml --log-junit=$INPUT_REPORT_PATH --whitelist app/ --coverage-clover '$INPUT_COVERAGE_PATH'"
fi

addHostMysql="--add-host=$mysqlHost:127.0.0.1"
if [ "$INPUT_ENABLE_MYSQL" == "true" ]; then
  if [ -z "$MYSQL_CONTAINER_IP" ]; then
    echo "::error:: No MYSQL_CONTAINER_IP provided, but MySql is enabled. Please checks logs above for errors."
    exit 1
  fi

  addHostMysql="--add-host=$mysqlHost:$MYSQL_CONTAINER_IP"
  echo -e "${BL}Info:${NC} MySql host provided: $MYSQL_CONTAINER_IP"
fi

addHostRedis="--add-host=$redisHost:127.0.0.1"
if [ "$INPUT_ENABLE_REDIS" == "true" ]; then
  if [ -z "$REDIS_CONTAINER_IP" ]; then
    echo "::error:: No REDIS_CONTAINER_IP provided, but Redis is enabled. Please checks logs above for errors."
    exit 1
  fi

  addHostRedis="--add-host=$redisHost:$REDIS_CONTAINER_IP"
  echo -e "${BL}Info:${NC} Redis host provided: $REDIS_CONTAINER_IP"
fi

echo -e "${BL}Info:${NC} Running PHPUnit with image: ${GR}$INPUT_PHP_IMAGE${NC} and hosts $GR\`$addHostMysql $addHostRedis\`${NC}"
docker run \
  -d \
  --platform linux/amd64 \
  --name nginx-fpm-alpine \
  --network=bridge \
  "$addHostMysql" \
  "$addHostRedis" \
  --env-file ./.env.testing \
  -v "$PWD":/var/www \
  "${INPUT_PHP_IMAGE}"

if [ "$INPUT_ENABLE_MYSQL" == "true" ]; then
  echo -e "${BL}Info:${NC} Bootstrap fresh DB"
  docker exec nginx-fpm-alpine bash -c "php artisan migrate:fresh -n --force && php artisan db:seed --force"
fi

if [ "$INPUT_ENABLE_WORKERS" == "true" ]; then
  echo -e "${BL}Info:${NC} Starting workers"
  docker exec nginx-fpm-alpine bash -c "ln -sf /var/www/$INPUT_WORKERS_CONF_PATH /etc/supervisor.d/conf.d/worker.conf && supervisorctl reread && supervisorctl update && supervisorctl restart all"
fi

docker exec nginx-fpm-alpine bash -c "$phpUnitCmd"
UNIT_TEST_EXIT_CODE=$?

if [ "$UNIT_TEST_EXIT_CODE" != "0" ]; then
  echo "::error::PHPUnit failed with exit code: $UNIT_TEST_EXIT_CODE"
  exit $UNIT_TEST_EXIT_CODE
fi

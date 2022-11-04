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

ACTION_IMAGE=""
if [ -n "$PROJECT_IMAGE" ]; then
  echo -e "${BL}Info:${NC} Project image found in env var PROJECT_IMAGE: ${GR}$PROJECT_IMAGE${NC}"
  ACTION_IMAGE="$PROJECT_IMAGE"
fi

if [ -n "$INPUT_PHP_IMAGE" ]; then
  echo -e "${BL}Info:${NC} Project image found in input. Using ${GR}$INPUT_PHP_IMAGE${NC}"
  ACTION_IMAGE="$INPUT_PHP_IMAGE"
fi

if [ -z "$ACTION_IMAGE" ]; then
  echo "::error::No image provided"
  exit 1
fi

if [ -z "$INPUT_RUN_SUITES" ]; then
  echo "::error::No test suites provided"
  exit 1
fi

phpUnitCmd="./vendor/bin/phpunit --configuration=./phpunit.xml --testsuite $INPUT_RUN_SUITES --log-junit=$INPUT_PHPUNIT_REPORT_PATH"
if [ "$INPUT_WITH_COVERAGE" == "true" ]; then
  ACTION_IMAGE="${ACTION_IMAGE}-dev"
  phpUnitCmd="php -d xdebug.mode=coverage ./vendor/bin/phpunit --configuration=./phpunit.xml --testsuite $INPUT_RUN_SUITES --log-junit=$INPUT_PHPUNIT_REPORT_PATH --whitelist app/ --coverage-clover $INPUT_COVERAGE_REPORT_PATH"
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

echo -e "${BL}Info:${NC} Checking for .env.testing file..."
if [ ! -f ".env.testing" ]; then
  errorMessage=".env.testing file not found! Please commit your .env.testing file to your repository."
  echo "::error::$errorMessage"
  echo "phpunit-error-message=$errorMessage" >> "$GITHUB_OUTPUT"
  echo "phpunit-error=true" >> "$GITHUB_OUTPUT"
  exit 1
else
  echo -e "${BL}Info:${NC} .env.testing file found! All good..."
fi

echo -e "${BL}Info:${NC} Running PHPUnit with image: ${GR}$ACTION_IMAGE${NC} and hosts $GR\`$addHostMysql $addHostRedis\`${NC}"
docker run \
  -d \
  --platform linux/amd64 \
  --name nginx-fpm-alpine \
  --network=bridge \
  "$addHostMysql" \
  "$addHostRedis" \
  --env-file ./.env.testing \
  -v "$PWD":/var/www \
  "${ACTION_IMAGE}"

if [ "$INPUT_ENABLE_MYSQL" == "true" ]; then
  echo -e "${BL}Info:${NC} Bootstrap fresh DB"
  docker exec nginx-fpm-alpine bash -c "php artisan migrate:fresh -n --force && php artisan db:seed --force"
  MIGRATIONS_EXIT_CODE=$?
  if [ "$MIGRATIONS_EXIT_CODE" != "0" ]; then
    errorMessage="Migrations failed with exit code: $MIGRATIONS_EXIT_CODE. Check logs for more info."
    echo "::error::$errorMessage"
    echo "phpunit-error-message=$errorMessage" >> "$GITHUB_OUTPUT"
    echo "phpunit-error=true" >> "$GITHUB_OUTPUT"
    exit $MIGRATIONS_EXIT_CODE
  fi
fi

if [ "$INPUT_ENABLE_WORKERS" == "true" ]; then
  echo -e "${BL}Info:${NC} Starting workers"
  docker exec nginx-fpm-alpine bash -c "ln -sf /var/www/$INPUT_WORKERS_CONF_PATH /etc/supervisor.d/conf.d/worker.conf && supervisorctl reread && supervisorctl update && supervisorctl restart all"
fi

docker exec nginx-fpm-alpine bash -c "$phpUnitCmd"
UNIT_TEST_EXIT_CODE=$?

if [ "$UNIT_TEST_EXIT_CODE" != "0" ]; then
  errorMessage="PHPUnit failed with exit code: $UNIT_TEST_EXIT_CODE. Check logs for more info."
  echo "::error::$errorMessage"
  echo "phpunit-error-message=$errorMessage" >> "$GITHUB_OUTPUT"
  echo "phpunit-error=true" >> "$GITHUB_OUTPUT"
  exit $UNIT_TEST_EXIT_CODE
fi

echo "phpunit-error=false" >> "$GITHUB_OUTPUT"
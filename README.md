# gha-phpunit

## Description

Run phpunit with custom PHP image.

## Inputs

| Key                   | Required | Default                                            | Description                                                                                    |
|-----------------------|----------|----------------------------------------------------|------------------------------------------------------------------------------------------------|
| **php-image**         | **true** | `''`                                               | PHP image to use (fully qualified image address. ex: quay.io/adoreme/nginx-fpm-alpine:v0.0.1). |
| **report-path**       | **true** | `./build/reports/phpunit-junit.xml`                | Report file path (where phpunit results will be saved).                                        |
| **enable-mysql**      | **true** | `false`                                            | Enable/disable MySql deploy.                                                                   |
| **enable-redis**      | **true** | `false`                                            | Enable/disable Redis deploy.                                                                   |
| **enable-workers**    | **true** | `false`                                            | Enable/disable workers in PHP container.                                                       |
| **workers-conf-path** | **true** | `ci/worker-confs/supervisor_dev_test_workers.conf` | File path for supervisor config.                                                               |
| **with-coverage**     | **true** | `true`                                             | Run also code coverage when running unit tests.                                                |
| **coverage-path**     | **true** | `./build/reports/coverage-clover.xml`              | Code coverage report file path.                                                                |

## Outputs

**N/A**

## Notes

ℹ This action doesn't handle docker registry authentication (e.g. for private images).
You can run [docker/login-action@v1](https://github.com/docker/login-action) before this step.  
ℹ Also, if **MySql** is enabled `migrations` and `seeds` will run automatically.  
ℹ It uses [publish-unit-test-result-action](https://github.com/EnricoMi/publish-unit-test-result-action) for publishing test results.  
ℹ It uses [comment-coverage-clover](https://github.com/lucassabreu/comment-coverage-clover) for publishing code coverage.

⚠ Configuring the `.env` should be done through `.env.testing` file. 
Laravel PHPUnit already sets the env to `testing` so it will be used automatically (we also set it on containers as env variables source: `--env-file .env.testing`). 

Other tests related configurations should be done through `phpunit.xml` file. This way we avoid duplicating functionality, and you can run the same setup locally.

🗒 **List of default config values**

**MySql**
- host: `mysql.gha`
- database: `adoreme`
- user: `adoreme`
- password: `secret`

**Redis**
- host: `redis.gha`

### Example of step configuration and usage:

For the most basic usage (fallback on all defaults) you can just add the following step to your workflow:

```yaml
steps:
  - name: 'Run PHPUnit'
    uses: adore-me/phpunit-action@master
```

If you want to override some defaults you can do it like this:

```yaml
steps:
  - name: 'Run PHPUnit Install'
    uses: adore-me/phpunit-action@master
    with:
      php-image: SOME_IMAGE # Should be a fully qualified image tag (e.g. `quay.io/adore-me/nginx-fpm-alpine:php-7.4.3-c2-v1.1.1`)
      report-path: ./build/reports/phpunit-junit.xml
      enable-mysql: true
      enable-redis: true
      enable-workers: true
      workers-conf-path: ci/worker-confs/supervisor_dev_test_workers.conf
      with-coverage: true
      coverage-path: ./build/reports/coverage-clover.xml
```
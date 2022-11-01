# gha-phpunit

## Description
Run phpunit with custom PHP image.  
ℹ The PHP image used can be passed through `php-image` input or through `PROJECT_IMAGE` env variable.  
**NOTE:** If you use [gha-image-setup](https://github.com/adore-me/gha-image-setup) in a previous step you don't need to worry about it, as it already sets the `PROJECT_IMAGE` 👌    
**Input** takes precedence!

## Inputs
| Key                           | Required | Default                                            | Description                                                                                               |
|-------------------------------|----------|----------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| **php-image**                 | **true** | `''`                                               | PHP image to use (fully qualified image address. ex: quay.io/adoreme/nginx-fpm-alpine:v0.0.1).            |
| **reports-dir**               | **true** | `build/reports`                                    | Report files directory (no trailing `/`).                                                                 |
| **phpunit-report-file-name**  | **true** | `phpunit-junit.xml`                                | PHPUnit report file name.                                                                                 |
| **enable-mysql**              | **true** | `false`                                            | Enable/disable MySql deploy.                                                                              |
| **enable-redis**              | **true** | `false`                                            | Enable/disable Redis deploy.                                                                              |
| **enable-workers**            | **true** | `false`                                            | Enable/disable workers in PHP container.                                                                  |
| **workers-conf-path**         | **true** | `ci/worker-confs/supervisor_dev_test_workers.conf` | File path for supervisor config.                                                                          |
| **with-coverage**             | **true** | `true`                                             | Run also code coverage when running unit tests.                                                           |
| **coverage-report-file-name** | **true** | `coverage-clover.xml`                              | Code coverage report file name.                                                                           |
| **run-suites**                | **true** | `UnitTests`                                        | Run specific suites. Pass suites as a comma separated list, no spaces (e.g. "UnitTests,IntegrationTests") |

## Outputs
None.

## Notes
ℹ This action doesn't handle docker registry authentication (e.g. for private images).
You can run [docker/login-action@v1](https://github.com/docker/login-action) before this step.  
ℹ If **MySql** is enabled `migrations` and `seeds` will run automatically.  
ℹ It uses [publish-unit-test-result-action](https://github.com/EnricoMi/publish-unit-test-result-action) for publishing test results.  
ℹ It uses [comment-coverage-clover](https://github.com/lucassabreu/comment-coverage-clover) for publishing code coverage.

Automatically handles uploading artifacts to GitHub Actions.

## Notes on using coverage
⚠ If `with-coverage` is enabled, it will automatically append the `-dev` suffix to the PHP image tag (internally, this image has xdebug, needed for coverage report).  
Otherwise, it will use the image tag as is (without xdebug), for faster running time.

## Notes on configuring `.env`
⚠ Configuring the `.env` should be done through `.env.testing` file. 
Laravel PHPUnit already sets the env to `testing` so it will be used automatically (we also set it on containers as env variables source: `--env-file .env.testing`). 

Other tests related configurations should be done through `phpunit.xml` file.   
This way we avoid duplicating functionality, and you can run the same setup locally.

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
      reports-dir: 'build/reports'
      phpunit-report-file-name: phpunit-junit.xml
      enable-mysql: true
      enable-redis: true
      enable-workers: true
      workers-conf-path: ci/worker-confs/supervisor_dev_test_workers.conf
      with-coverage: true
      coverage-report-file-name: coverage-clover.xml
      run-suites: 'IntegrationTests,UnitTests'
```
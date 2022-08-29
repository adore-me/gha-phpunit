# gha-phpunit

## Description
Run phpunit with custom PHP image.

## Inputs
| Key                | Default                             | Description                                                                         |
|--------------------|-------------------------------------|-------------------------------------------------------------------------------------|
| **php-image-tag**  | `''`                                | PHP image tag to use. Takes precedence over the PHP_IMAGE_TAG environment variable. |
| **report-path**    | `./build/reports/phpunit-junit.xml` | Report file path.                                                                   |
| **enable-mysql**   | `false`                             | Enable/disable MySql deploy.                                                        |

## Outputs
None.

ℹ If **MySql** is enabled the host in the PHP container will be set as `mysql.gha`.

ℹ Also, if **MySql** is enabled `migrations` will be run automatically.

⚠ All your configs for this action should be set in `phpunit.xml` config file since no `.env` file is provisioned.

**List of default config values**
- mysql host: `mysql.gha`
- mysql database: `adoreme`
- mysql user: `adoreme`
- mysql password: `secret`

### Example of step configuration and usage:
```yaml
steps:
  - name: 'Run Composer Install'
    uses: adore-me/phpunit-action@master
    with:
      php-image-tag: SOME_IMAGE_TAG # Not needed if `env.PHP_IMAGE_TAG` is set.
      gh-oauth-token: ${{ secrets.GH_PRIVATE_ACTIONS_TOKEN }} # Needed if you want to pull private dependencies.
```

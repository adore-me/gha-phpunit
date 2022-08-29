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

⚠ If **MySql** is enabled the host in the PHP container will be set as `mysql.gha`, so you will need to set your `.env`'s `DB_HOST(_READ/WRITE)` to `mysql.gha`.
Ex:
```
DB_HOST=mysql.gha
DB_HOST_READ=mysql.gha
DB_HOST_WRITE=mysql.gha
```


### Example of step configuration and usage:
```yaml
steps:
  - name: 'Run Composer Install'
    uses: adore-me/phpunit-action@master
    with:
      php-image-tag: SOME_IMAGE_TAG # Not needed if PHP_IMAGE_TAG is set.
      gh-oauth-token: ${{ secrets.GH_PRIVATE_ACTIONS_TOKEN }}
```

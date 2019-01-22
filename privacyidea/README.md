
privacyidea
---------

Forked from: https://hub.docker.com/r/solipsist01/privacyidea  https://github.com/solipsist01/dockerfiles

# Summary

This is the docker image for privacyidea project
(https://github.com/privacyidea).

# Build and run

* `git clone` this project  
* Create `privacyidea.env` file with a `KEY=VALUE` content
  (don't quote the values!) inside the cloned directory. The keys are below:

```
# Required
PI_PEPPER - used for encrypting admin passwords
PI_SECRET_KEY - This is used to encrypt the auth_token
PI_DB_PASSWORD - password to database
PI_DB_HOST - database host
PI_ADMIN_USER - name of admin user
PI_ADMIN_PASSWORD - password for admin user

# Optional
PI_ENCFILE - used to encrypt the token data and token passwords
PI_AUDIT_KEY_PRIVATE - used to sign the audit log
PI_AUDIT_KEY_PUBLIC - used to sign the audit log
PI_LOGFILE - location of log file
PI_LOGLEVEL - log level of app
PI_SSL_CERT_NAME - name of certificate in /usr/local/share/ca-certificates/ used for encrypted connection to DB
SUPERUSER_REALM - realm, where users are allowed to login as administrators
PI_AUDIT_MODULE - lets you specify an alternative auditing module

```
* Run `docker-compose up`

Make sure the container will be able to reach all required services
(SQL database).

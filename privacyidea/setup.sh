#!/bin/bash

# wait for mysql server to start (max 30 seconds)
    timeout=30
    echo -n "Waiting for database server to accept connections"
    while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
    do
      timeout=$(($timeout - 1))
      if [ $timeout -eq 0 ]; then
        echo -e "\nCould not connect to database server. Aborting..."
        exit 1
      fi
      echo -n "."
      sleep 1
    done
mysql -u root -e "create database if not exists pi;" || true

#Set the SECRET_KEY and PI_PEPPER to a random value for this instance
sed -i 's!t0p s3cr3t!'$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-24};echo;)'!' /etc/privacyidea/pi.cfg
sed -i 's!Never know...!'$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-24};echo;)'!' /etc/privacyidea/pi.cfg

cd /opt/privacyIDEA

pi-manage create_enckey
pi-manage create_audit_keys
pi-manage createdb
pi-manage admin add admin -e admin@localhost -p 'test'

pi-manage runserver -h 0.0.0.0 -p 80

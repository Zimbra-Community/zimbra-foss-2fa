#!/bin/sh
set -x

mysqld &

USERNAME=privacyidea

create_user() {
  useradd -r $USERNAME -m || true
}

create_files() {
  mkdir -p /var/log/privacyidea
  mkdir -p /var/lib/privacyidea
  touch /var/log/privacyidea/privacyidea.log
  pi-manage create_enckey || true
  pi-manage createdb || true
  pi-manage create_audit_keys || true
  chown -R $USERNAME /var/log/privacyidea
  chown -R $USERNAME /var/lib/privacyidea
  chown -R $USERNAME /etc/privacyidea
  chmod 600 /etc/privacyidea/enckey
  chmod 600 /etc/privacyidea/private.pem
  # we need to change access right, otherwise each local user could call
  # pi-manage
  chgrp root /etc/privacyidea/pi.cfg
  chmod 640 /etc/privacyidea/pi.cfg
}

create_certificate() {
  if [ ! -e /etc/privacyidea/server.pem ]; then
    # This is the certificate when running with paster...
    cd /etc/privacyidea
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -out server.csr -subj "/CN=privacyidea"
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    cat server.crt server.key > server.pem
    rm -f server.crt server.key
    chown privacyidea server.pem
    chmod 400 server.pem
  fi

  if [ ! -e /etc/ssl/certs/privacyideaserver.pem ]; then
    # This is the certificate when running with apache or nginx
    KEY=/etc/ssl/private/privacyideaserver.key
    CSR=`mktemp`
    CERT=/etc/ssl/certs/privacyideaserver.pem
    openssl genrsa -out $KEY 2048
    openssl req -new -key $KEY -out $CSR -subj "/CN=`hostname`"
    openssl x509 -req -days 365 -in $CSR -signkey $KEY -out $CERT
    rm -f $CSR
    chmod 400 $KEY
  fi
}

adapt_pi_cfg() {
  if [ !$(grep "^PI_PEPPER" /etc/privacyidea/pi.cfg) ]; then
    # PEPPER does not exist, yet
    PEPPER="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
    echo "PI_PEPPER = '$PEPPER'" >> /etc/privacyidea/pi.cfg
  fi
  if [ !$(grep "^SECRET_KEY" /etc/privacyidea/pi.cfg || true) ]; then
    # SECRET_KEY does not exist, yet
    SECRET="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c24)"
    echo "SECRET_KEY = '$SECRET'" >> /etc/privacyidea/pi.cfg
  fi
}

create_database() {
  # create the MYSQL database
  if [ !$(grep "^SQLALCHEMY_DATABASE_URI" /etc/privacyidea/pi.cfg || true) ]; then
    USER="debian-sys-maint"
    PASSWORD=$(grep "^password" /etc/mysql/debian.cnf | sort -u | cut -d " " -f3)
    NPW="$(tr -dc A-Za-z0-9_ </dev/urandom | head -c12)"
    mysql -u $USER --password=$PASSWORD -e "create database pi;" || true
    mysql -u $USER --password=$PASSWORD -e "grant all privileges on pi.* to 'pi'@'localhost' identified by '$NPW';"
    echo "SQLALCHEMY_DATABASE_URI = 'mysql://pi:$NPW@localhost/pi'" >> /etc/privacyidea/pi.cfg
  fi
}

enable_nginx_uwsgi() {
  rm -f /etc/nginx/sites-enabled/*
  rm -f /etc/uwsgi/apps-enabled/*
  ln -s /etc/nginx/sites-available/privacyidea /etc/nginx/sites-enabled/
  ln -s /etc/uwsgi/apps-available/privacyidea.xml /etc/uwsgi/apps-enabled/

  ln -s /etc/ssl/certs/privacyideaserver.pem /etc/ssl/certs/privacyidea-bundle.crt || true
  ln -s /etc/ssl/private/privacyideaserver.key /etc/ssl/private/privacyidea.key || true
}

update_db() {
  # Set the version to the first PI 2.0 version
  pi-manage db stamp 4f32a4e1bf33 -d /usr/lib/privacyidea/migrations

  # Upgrade the database
  #pi-manage db upgrade -d /usr/lib/privacyidea/migrations
}

create_user
adapt_pi_cfg
create_database
enable_nginx_uwsgi
create_files
create_certificate
update_db

PRIVACYIDEA_ADMIN_USER=${PRIVACYIDEA_ADMIN_USER:-}
PRIVACYIDEA_ADMIN_PASS=${PRIVACYIDEA_ADMIN_PASS:-}

if [ -n "${PRIVACYIDEA_ADMIN_USER}" -o -n "${PRIVACYIDEA_ADMIN_PASS}" ]; then
  pi-manage admin add ${PRIVACYIDEA_ADMIN_USER} -p ${PRIVACYIDEA_ADMIN_PASS}
fi

DATABASE=/etc/privacyidea/users.global.sqlite
echo "create table users (id INTEGER PRIMARY KEY ,\
username TEXT UNIQUE,\
surname TEXT, \
givenname TEXT, \
email TEXT, \
password TEXT, \
description TEXT, \
mobile TEXT, \
  phone TEXT);" | sqlite3 ${DATABASE}

USERDB=/etc/privacyidea/users.global.install
cat <<END > $USERDB
{'Server': '/',
'Driver': 'sqlite',
'Database': '${DATABASE}',
'Table': 'users',
'Limit': '500',
'Editable': '1',
'Map': '{"userid": "id", "username": "username", "email":"email", "password": "password", "phone":"phone", "mobile":"mobile", "surname":"name", "givenname":"givenname", "description": "description"}'
}
END
pi-manage resolver create GLOBAL sqlresolver ${USERDB}
chown $USERNAME $DATABASE

for GROUP in hosting network vpn; do
  DATABASE=/etc/privacyidea/users.${GROUP}.sqlite
  echo "create table users (id INTEGER PRIMARY KEY ,\
	username TEXT UNIQUE,\
	surname TEXT, \
	givenname TEXT, \
	email TEXT, \
	password TEXT, \
	description TEXT, \
	mobile TEXT, \
    phone TEXT);" | sqlite3 ${DATABASE}

  USERDB=/etc/privacyidea/users.${GROUP}.install
  cat <<END > ${USERDB}
{'Server': '/',
 'Driver': 'sqlite',
 'Database': '${DATABASE}',
 'Table': 'users',
 'Limit': '500',
 'Editable': '1',
 'Map': '{"userid": "id", "username": "username", "email":"email", "password": "password", "phone":"phone", "mobile":"mobile", "surname":"name", "givenname":"givenname", "description": "description"}'
}
END
  chown $USERNAME ${DATABASE}
  pi-manage resolver create ${GROUP} sqlresolver ${USERDB}

  pi-manage realm create $GROUP ${GROUP}
done

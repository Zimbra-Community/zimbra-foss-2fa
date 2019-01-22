#!/usr/bin/env sh
#

# Apply database migrations
echo "Apply database migrations"
. $PRIVACYIDEA_HOME/venv/bin/activate

pi-manage createdb || exit 1
pi-manage db stamp 4f32a4e1bf33 -d "$PRIVACYIDEA_HOME/venv/lib/privacyidea/migrations" || exit 1
pi-manage db upgrade -d "${PRIVACYIDEA_HOME}/venv/lib/privacyidea/migrations" || exit 1
pi-manage admin add -p ${PI_ADMIN_PASSWORD} ${PI_ADMIN_USER} || exit 1

if [ ! -f $PI_AUDIT_KEY_PRIVATE_SECRET ]
then
  pi-manage create_audit_keys
  openssl rsa -in $PI_AUDIT_KEY_PRIVATE -pubout -out $PI_AUDIT_KEY_PUBLIC
else
  echo -e $PI_AUDIT_KEY_PRIVATE_SECRET > $PI_AUDIT_KEY_PRIVATE
  echo -e $PI_AUDIT_KEY_PUBLIC_SECRET > $PI_AUDIT_KEY_PUBLIC
fi

if [ ! -f $PI_ENCFILE_SECRET ]
then
  pi-manage create_enckey
else
  echo $PI_ENCFILE_SECRET > $PI_ENCFILE
fi

# Start server
echo "Starting server"
$PRIVACYIDEA_HOME/python/bin/uwsgi \
    --home $PRIVACYIDEA_HOME/venv \
    --manage-script-name \
    --mount /=privacyidea.app:heroku_app

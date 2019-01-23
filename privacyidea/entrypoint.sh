#!/bin/bash
set -x

# Setup privacyIDEA
. /sbin/setup.sh

cp /privacyidea.xml /etc/uwsgi/apps-available/privacyidea.xml

exec /usr/bin/supervisord -n -c /etc/supervisord.conf

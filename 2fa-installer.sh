#!/bin/bash

# Copyright (C) 2014-2019  Barry de Graaff
# 
# Bugs and feedback: https://github.com/Zimbra-Community/zimbra-foss-2fa/issues
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.

set -e
# if you want to trace your script uncomment the following line
#set -x

echo "Zimbra Open Source Edition 2FA Installer"

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cat << EOF
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.


If you have a single server Zimbra running on CentOS or Ubuntu 
AND you want to use Zimbra's internal LDAP to store usernames 
and password you can use this automated installer.

Otherwise follow the manual install guide:
https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/README-MANUAL-INSTALL.md

(any key to continue or CTRL+C to abort)
EOF
read DUMMY;

# is there an easier way to do this, whiptail sucks?
domains=$(su zimbra -c "/opt/zimbra/bin/zmprov -l gad | sed -r 's/(.*)/\1 \1/'")

OPTION2FAINST=$(whiptail --notags --backtitle "Zimbra 2FA Installer" --menu "Select domain to configure for 2FA" 20 80 10 $domains 3>&1 1>&2 2>&3)

exitstatus=$?
[[ "$exitstatus" = 1 ]] && exit 0;

echo "Check if yum/apt installed."
set +e
YUM_CMD=$(which yum)
APT_CMD=$(which apt-get)
set -e 

if [[ ! -z $YUM_CMD ]]; then
echo "Removing Docker distro packages"
yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine   

echo "Installing Docker dependancies"
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2 wget net-tools sed gawk curl

echo "Installing Docker"
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
yum install -y docker-ce docker-ce-cli containerd.io
else
echo "Removing Docker distro packages"
apt-get remove -y docker docker-engine docker.io containerd runc

echo "Installing Docker dependancies"
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common wget net-tools sed gawk curl

echo "Installing Docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
fi
   
echo "Enable Docker on boot, start Docker"   
systemctl enable docker
systemctl start docker

echo "Creating Docker volumes and config folder"
docker volume create --name ${OPTION2FAINST//[-._]/}_privacyidea_data
docker volume create --name ${OPTION2FAINST//[-._]/}_privacyidea_log
docker volume create --name ${OPTION2FAINST//[-._]/}_privacyidea_mariadb

mkdir -p /opt/privacyIdeaLDAPProxy/$OPTION2FAINST
wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/config.ini -O /opt/privacyIdeaLDAPProxy/$OPTION2FAINST/config.ini

LDAPIP=$(netstat -tulpn | grep -v tcp6 | grep -v 127.0.0.1 | grep :389 | awk '{ print $4 }' | awk -F ":" '{ print $1 }')

echo "Setting LDAP IP"
if (whiptail --title "Zimbra LDAP IP" --yesno "Is this the IP for your Zimbra LDAP? $LDAPIP:389" 8 78); then
    sed -i 's!your-zimbra-ip-here-it-must-not-be-127.0.0.1-and-also-not-172.*.0.*!'$LDAPIP':port=389!' /opt/privacyIdeaLDAPProxy/$OPTION2FAINST/config.ini
else
    echo "Cannot continue at this point"
    exit 0
fi

echo "Setting LDAP password"
ZMLDAPPASS2FA=$(su zimbra -c "source /opt/zimbra/bin/zmshutil; zmsetvars; env" | grep ldap_root_password= | awk -F  "=" '{ print $2 }')
sed -i 's!zimbra-ldap-pass-here!'$ZMLDAPPASS2FA'!' /opt/privacyIdeaLDAPProxy/$OPTION2FAINST/config.ini

echo "Creating Docker network"
docker network inspect zimbradocker &>/dev/null || docker network create --subnet=172.18.0.0/16 zimbradocker

#Find free IP / is there an easier way?
for ((i = 2 ; i < 255 ; i++ )); do 
   FREEIP=$(docker network inspect zimbradocker | grep 172.18.0.$i/16 | wc -l)
   if [[ $FREEIP = "0" ]]; then
      DOCKERIP2FA="172.18.0."$i
      export DOCKERIP2FA
      break;
   fi
done

echo "Starting Docker container"
docker pull zetalliance/privacy-idea:latest

# Check if commercial.key exists
if [ -f /opt/zimbra/ssl/zimbra/commercial/commercial.key ]
then
  echo "Running Container with zimbra commercial certificate"
  additional_volumes="-v /opt/zimbra/ssl/zimbra/commercial/commercial.key:/opt/privacyIdeaLDAPProxy/$OPTION2FAINST/server.key:ro \
             -v /opt/zimbra/conf/nginx.crt:/opt/privacyIdeaLDAPProxy/$OPTION2FAINST/server.crt:ro"
else
  echo "Running Container with zimbra server.key"
  additional_volumes="-v /opt/zimbra/ssl/zimbra/server/server.key:/opt/privacyIdeaLDAPProxy/$OPTION2FAINST/server.key:ro \
             -v /opt/zimbra/conf/nginx.crt:/opt/privacyIdeaLDAPProxy/$OPTION2FAINST/server.crt:ro"
fi

# Execute docker run command
docker run --init --net zimbradocker \
             --ip $DOCKERIP2FA \
             --name privacyidea_${OPTION2FAINST//[-._]/} \
             --restart=always \
             -v ${OPTION2FAINST//[-._]/}_privacyidea_data:/etc/privacyidea \
             -v ${OPTION2FAINST//[-._]/}_privacyidea_log:/var/log/privacyidea \
             -v ${OPTION2FAINST//[-._]/}_privacyidea_mariadb:/var/lib/mysql \
             -v /opt/privacyIdeaLDAPProxy/$OPTION2FAINST:/opt/privacyIdeaLDAPProxy \
             $additional_volumes \
             -d zetalliance/privacy-idea:latest


set +e
echo "Configuring firewallD, if you do not have firewallD, or see some errors here, configure the firewall manually"
firewall-cmd --permanent --zone=public --add-rich-rule='
   rule family="ipv4"
   source address="'$DOCKERIP2FA'/32"
   port protocol="tcp" port="389" accept'
firewall-cmd --reload
set -e

echo "Waiting for PrivacyIDEA to initialize"
until $(curl --output /dev/null --silent --head --fail http://$DOCKERIP2FA:8000); do
    printf '.'
    sleep 5
done

echo ""

echo "Generating PrivacyIDEA API Token"
AUTHTOKENPI=$(docker container exec -it privacyidea_${OPTION2FAINST//[-._]/} /usr/bin/pi-manage api createtoken -r admin -d 7200 | grep Auth-Token | awk -F  ": " '{ print $2 }')

echo "Configuring PrivacyIDEA LDAP resolver"
curl http://$DOCKERIP2FA:8000/resolver/zimbra -H "PI-Authorization: "$AUTHTOKENPI"" -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*'  --data-binary '{"BINDDN":"uid=zimbra,cn=admins,cn=zimbra","AUTHTYPE":"Simple","LDAPBASE":"ou=people,dc='${OPTION2FAINST//./,dc=}'","LDAPURI":"ldap://'$LDAPIP'","START_TLS":false,"EDITABLE":false,"LDAPSEARCHFILTER":"(uid=*)(objectClass=inetOrgPerson)","SERVERPOOL_SKIP":"30","SERVERPOOL_ROUNDS":"2","UIDTYPE":"entryUUID","TLS_VERIFY":true,"BINDPW":"'$ZMLDAPPASS2FA'","USERINFO":"{ \"phone\" : \"telephoneNumber\", \"mobile\" : \"mobile\", \"email\" : \"mail\", \"surname\" : \"sn\", \"givenname\" : \"givenName\" }","TIMEOUT":"5","SIZELIMIT":"500","SCOPE":"SUBTREE","NOREFERRALS":true,"CACHE_TIMEOUT":"120","LOGINNAMEATTRIBUTE":"uid","NOSCHEMAS":false,"type":"ldapresolver"}' 
echo ""

echo "Configuring PrivacyIDEA Realm"
curl http://$DOCKERIP2FA:8000/realm/zimbra -H "PI-Authorization: "$AUTHTOKENPI"" -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*' --data-binary '{"priority.zimbra":10,"resolvers":"zimbra"}' 
echo ""

echo "Configuring PrivacyIDEA Authentication Policy"
curl http://$DOCKERIP2FA:8000/policy/auth -H "PI-Authorization: "$AUTHTOKENPI"" -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*'  --data-binary '{"action":["passthru=userstore","otppin=userstore"],"scope":"authentication","realm":["zimbra"],"resolver":["zimbra"],"user":"","active":true,"check_all_resolvers":false,"client":"","time":"","priority":1,"adminrealm":[]}'
echo ""

echo "Configuring PrivacyIDEA Enroll Policy"
curl http://$DOCKERIP2FA:8000/policy/enroll -H "PI-Authorization: "$AUTHTOKENPI"" -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*'  --data-binary '{"action":["tokenissuer=Zimbra","tokenlabel=<u>'$OPTION2FAINST' <s>"],"scope":"enrollment","realm":["zimbra"],"resolver":["zimbra"],"user":"","active":true,"check_all_resolvers":false,"client":"","time":"","priority":1,"adminrealm":[]}'
echo ""

echo "Deploying Zimbra Zimlets"
cd /tmp
wget https://github.com/Zimbra-Community/zimbra-foss-2fa/releases/download/0.0.1/tk_barrydegraaff_2fa.zip -O /tmp/tk_barrydegraaff_2fa.zip
wget https://github.com/Zimbra-Community/zimbra-foss-2fa/releases/download/0.0.1/tk_barrydegraaff_2fa_admin.zip -O /tmp/tk_barrydegraaff_2fa_admin.zip
su zimbra -c "/opt/zimbra/bin/zmzimletctl deploy /tmp/tk_barrydegraaff_2fa.zip"
su zimbra -c "/opt/zimbra/bin/zmzimletctl deploy /tmp/tk_barrydegraaff_2fa_admin.zip"

echo "Installing Zimbra Java Extension"
set +e
mkdir /opt/zimbra/lib/ext/zimbraprivacyidea
set -e
wget https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/extension/out/artifacts/zimbraprivacyIdea_jar/privacyIdeazimbra.jar -O /opt/zimbra/lib/ext/zimbraprivacyidea/privacyIdeazimbra.jar

echo "Clean up existing Zimbra Java Extension configuration for $OPTION2FAINST if needed"
set +e
cat /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties | grep -v _$OPTION2FAINST > /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties_
cat /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties_ > /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties
rm -Rf /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties_
set -e

echo "Configure Zimbra Java Extension"
cat >> /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties << EOF
apiURI_$OPTION2FAINST = http://$DOCKERIP2FA:8000
initJSON_$OPTION2FAINST = {"timeStep":30,"otplen":6,"genkey":true,"description":"zimbratokendescr","type":"totp","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}
deviceJSON_$OPTION2FAINST = {"otpkey":"zimbradevicepasscode","description":"zimbratokendescr","type":"pw","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}
accountname_with_domain_$OPTION2FAINST = false
token_$OPTION2FAINST = $AUTHTOKENPI
EOF

echo "Setting up Zimbra domain configuration for $OPTION2FAINST"
SERVICEACCT_PWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-24};echo;)
PROFFILE="$(mktemp /tmp/2fa-prof.XXXXXXXX.txt)"
echo "md $OPTION2FAINST zimbraAuthLdapSearchBase \"ou=people,dc=${OPTION2FAINST//./,dc=}\"" > "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthLdapSearchBindDn \"uid=sa-ldap-2fa,ou=people,dc=${OPTION2FAINST//./,dc=}\"" >> "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthLdapSearchBindPassword \"$SERVICEACCT_PWD\"" >> "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthLdapSearchFilter \"(uid=%u)\"" >> "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthLdapURL \"ldap://$DOCKERIP2FA:1389\"" >> "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthMech \"ldap\"" >> "$PROFFILE"
echo "md $OPTION2FAINST zimbraAuthFallbackToLocal FALSE" >> "$PROFFILE"
echo "da sa-ldap-2fa@$OPTION2FAINST" >> "$PROFFILE"
echo "ca sa-ldap-2fa@$OPTION2FAINST $SERVICEACCT_PWD" >> "$PROFFILE"
chown zimbra:zimbra "$PROFFILE"
su zimbra -c "/opt/zimbra/bin/zmprov < ${PROFFILE}"

echo "Patching login screen"
if grep -q "Zeta Alliance" /opt/zimbra/jetty/webapps/zimbra/public/login.jsp; then
    echo "Already patched, skipping"
else
   wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/patches/login-jsp-patch.js -O /tmp/zimbra2f-login-jsp.patch
   sed $'/<\/body>/{e cat /tmp/zimbra2f-login-jsp.patch\n}' /opt/zimbra/jetty/webapps/zimbra/public/login.jsp > /tmp/zimbra2f-login-jsp.prepped.patch
   rm -f /opt/zimbra/jetty/webapps/zimbra/public/login.jsp
   cp -f /tmp/zimbra2f-login-jsp.prepped.patch /opt/zimbra/jetty/webapps/zimbra/public/login.jsp
   rm -f /tmp/zimbra2f-login-jsp.prepped.patch
   rm -f /tmp/zimbra2f-login-jsp.patch
fi

echo "Patching change password screen"
if grep -q "Zeta Alliance" /opt/zimbra/jetty/webapps/zimbra/h/changepass; then
    echo "Already patched, skipping"
else
   wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/patches/changepass-patch.js -O /tmp/zimbra2f-changepass.patch
   sed $'/<\/body>/{e cat /tmp/zimbra2f-changepass.patch\n}' /opt/zimbra/jetty/webapps/zimbra/h/changepass > /tmp/zimbra2f-changepass.prepped.patch
   rm -f /opt/zimbra/jetty/webapps/zimbra/h/changepass
   cp -f /tmp/zimbra2f-changepass.prepped.patch /opt/zimbra/jetty/webapps/zimbra/h/changepass
   rm -f /tmp/zimbra2f-changepass.prepped.patch
   rm -f /tmp/zimbra2f-changepass.patch
fi

echo "Restarting Zimbra mailboxd"
su zimbra -c "/opt/zimbra/bin/zmmailboxdctl restart"

# Manual Install Guide Zimbra Open Source Two Factor Authentication with PrivacyIDEA

[![2FA install steps](https://img.youtube.com/vi/PDhrvFGMtjQ/0.jpg)](https://www.youtube.com/watch?v=PDhrvFGMtjQ)

Install guide: https://www.youtube.com/watch?v=PDhrvFGMtjQ

These steps will set-up your Zimbra Open Source Edition server with Two Factor Authentication. The 2FA parts are powered by PrivacyIDEA and will run in a Docker container on your Zimbra server.

Technically this makes Zimbra support all 2FA tokens PrivacyIDEA supports. This includes TOTP, HOTP, and Yubikey. 

This project uses an LDAP Proxy provided by PrivacyIDEA. So the usernames and passwords are read by PrivacyIDEA from the Zimbra LDAP (or ActiveDirectory if you want). And the 2FA tokens are read from PrivacyIDEA database. The user can log in using 2FA by typing the username and the password and token. 

For now there is no separate login screen for the 2FA token, so the user must append the 2FA code to the password. Also we do not have a Zimbra integrated user UI yet. So for now you can proxy the PrivacyIDEA UI with Zimbra proxy. So the user can add/remove tokens that way.

The installation takes around 1GB of space.

1. Install docker-ce (you cannot use your distro's docker) see:
   https://docs.docker.com/install/linux/docker-ce/centos/
   https://docs.docker.com/install/linux/docker-ce/ubuntu/
   
   Enable docker on server startup: `systemctl enable docker`
   Start docker now: `systemctl start docker`

   Make sure to have NTP running on your Host (Zimbra server) or wherever your docker containers run, so they all get the correct time. 
   
       yum install -y ntpdate
       ntpdate 0.us.pool.ntp.org
       which ntpdate  #remember the full path
   
   and then add to crontab using `crontab -e`
   
         1 * * * * (add full path here)/ntpdate 0.us.pool.ntp.org
   
   for CentOS it will be:
   
         1 * * * * /usr/sbin/ntpdate 0.us.pool.ntp.org

2. (optional) If you want, you can build your own Docker image, that way you have the latest version of everything and get some know-how along the way. See https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/privacyidea/README.md
   
3. Create storage volumes

        docker volume create --name privacyidea_data
        docker volume create --name privacyidea_log
        docker volume create --name privacyidea_mariadb

4. Prepare your ldap proxy configuration

   On your Zimbra server find out on what IP ldap listens `netstat -tulpn | grep 389` and find out your LDAP settings (run as zimbra user):

       source ~/bin/zmshutil 
       zmsetvars 
       echo $zimbra_ldap_password
       echo $zimbra_ldap_userdn

   As root:

       mkdir -p /opt/privacyIdeaLDAPProxy
       cd /opt/privacyIdeaLDAPProxy
       wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/config.ini
        
   Open the config.ini and set the `password` under `service-account` and set the correct IP in `endpoint` under `ldap-backend`. It is the IP from the netstat result, it must not be 127.0.0.1 or 172.* or so. If your ldap listens on 127.0.0.1, do a `zmcontrol stop` set the correct ip in /etc/hosts and then `zmcontrol start`.


5. Add your SSL certificates

   If you use a Zimbra self signed SSL cert:
   
        cp /opt/zimbra/ssl/zimbra/server/server.key /opt/privacyIdeaLDAPProxy/server.key
        cp /opt/zimbra/conf/nginx.crt /opt/privacyIdeaLDAPProxy/server.crt

   If you have deployed a real certificate:
   
        cp /opt/zimbra/ssl/zimbra/commercial/commercial.key /opt/privacyIdeaLDAPProxy/server.key
        cp /opt/zimbra/conf/nginx.crt /opt/privacyIdeaLDAPProxy/server.crt

6. Run the privacy-idea container

        docker network create --subnet=172.18.0.0/16 zimbradocker
        docker run --init --net zimbradocker --ip 172.18.0.2 -p 5000:443 --name privacyidea --restart=always -v privacyidea_data:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_mariadb:/var/lib/mysql -v /opt/privacyIdeaLDAPProxy:/opt/privacyIdeaLDAPProxy -d zetalliance/privacy-idea:latest

   You should be able to see PrivacyIDEA at https://yourzimbra:5000/ it can take a couple of minutes for it to start. 

7. Configure PrivacyIDEA

    Create a new admin user on PrivacyIDEA `docker exec -it privacyidea /usr/bin/pi-manage admin add admin -e admin@example.com`.

    On your Zimbra allow the docker container to access the Zimbra ldap.

       firewall-cmd --permanent --zone=public --add-rich-rule='
          rule family="ipv4"
          source address="172.18.0.2/32"
          port protocol="tcp" port="389" accept'
       firewall-cmd --reload

   Do not create the Initial Realm if PrivacyIDEA asks you! On your Zimbra server find out on what IP ldap listens `netstat -tulpn | grep 389` and configure PrivacyIDEA as in the screenshots. To find out your LDAP settings (run as zimbra user):

       source ~/bin/zmshutil 
       zmsetvars 
       echo $zimbra_ldap_password
       echo $zimbra_ldap_userdn
       ldapsearch -x -H $ldap_master_url -D $zimbra_ldap_userdn -w $zimbra_ldap_password "mail=*"

   This will allow you to find your base DN as well. Usually something like `ou=people,dc=example,dc=com` don't forget to hit the `Preset OpenLDAP`.


![01-pi-ldap.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/01-pi-ldap.png)

   Only use alpabethical characters for resolver/realm name no special characters (including .-) etc, or it will break.

![02-pi-resolver.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/02-pi-resolver.png)

   Only use alpabethical characters for resolver/realm name no special characters (including .-) etc, or it will break.

![03-pi-users.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/03-pi-users.png)

   Go to config -> policies -> create new policy and set a policy with scope `authentication` and set passthru->userstore and otppin->userstore. Realm: Zimbra, Resolver: Zimbra. See the documentation: https://privacyidea.readthedocs.io/en/latest/policies/authentication.html
   
![04-pi-policy.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/04-pi-policy.png)   

8. You can now enroll TOTP tokens for the users

9. Try and see if it works by doing LDAP searches

   You must append to OTP code to the password like so:

       ldapsearch -x -H ldap://zimbraserver:389 -D uid=user2,ou=people,dc=zimbradev,dc=barrydegraaff,dc=tk -w "PASSWORD HERE" "mail=*"
       ldapsearch -x -H ldap://172.18.0.2:1389 -D uid=user2,ou=people,dc=zimbradev,dc=barrydegraaff,dc=tk -w "PASSWORD HERE***OTP HERE***" "mail=*"

   If it does not work, check if PrivacyIDEA works directly using the API `curl -d "user=user1&pass=testabc387223" -X POST https://zimbraserver:5000/validate/check` or from the Zimbra server `curl -d "user=user1&pass=testabc944412" -X POST http://172.18.0.2:8000/validate/check`.
     
10. Debug and reading the logs

   You can run commands in the docker container by doing `docker exec -it privacyidea bash` and you can see the logs using `tail -f /var/lib/docker/volumes/privacyidea_log/_data/privacyidea.log` on the Zimbra server. And `docker container logs privacyidea`.
    
11. Now you can configure your Zimbra Domain with external authentication, basically pointing it to the LDAP Proxy

    Follow the steps in the screenshots like so, you must set Zimbra to use a bind dn, even a bind dn that is not privileged will work. You may need to create one in the correct domain. And you should repeat these steps for each domain you want to have 2FA.

    ![11-zimbra-auth-external.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/11-zimbra-auth-external.png)
![12-zimbra-ldap-filter.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/12-zimbra-ldap-filter.png)
![13-zimbra-ldap-binddn.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/13-zimbra-ldap-binddn.png)

   Please note there is a bug in Zimbra, if the test keeps failing, just continue and finish the setup wizard. Then try again. Usually that is when the test starts working.

   ![14-zimbra-ldap-test.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/14-zimbra-ldap-test.png)
![15-zimbra-ldap-test2.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/15-zimbra-ldap-test2.png)
![15-zimbra-ldap-test3.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/15-zimbra-ldap-test3.png)
![16-zimbra-ldap-done.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/16-zimbra-ldap-done.png)

12. If it all works, don't forget to run as Zimbra user: `zmprov md example.com zimbraAuthFallbackToLocal FALSE`

13. Create the following optional PrivacyIDEA policies

    ![21-policy-token-name.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/21-policy-token-name.png)
![22-policy-hide-pi-banners.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/22-policy-hide-pi-banners.png)

14. Admin account and 2FA

   At this time, Zimbra will still allow using only a password for admin accounts, this is a bug. See https://github.com/Zimbra/zm-mailbox/pull/448 and https://bugzilla.zimbra.com/show_bug.cgi?id=80485 this means, you need to create a separate admin account, put a long password on it, and don't use it for day-to-day work.

15. Update the Zimbra login screen

   Open the file https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/patches/login-jsp-patch.js the patch needs to go in /opt/zimbra/jetty/webapps/zimbra/public/login.jsp the patch needs to be added just before the </body> tag. You need to repeat this whenever you upgrade Zimbra to a new version.

16. Update the Zimbra change password dialog

   Open the file https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/patches/changepass-patch.js the patch needs to go in /opt/zimbra/jetty/webapps/zimbra/h/changepass the patch needs to be added just before the </body> tag. You need to repeat this whenever you upgrade Zimbra to a new version.

17. Install the Zimlets
   
   The admin Zimlet only contains a patch that will enable the `Change password` right-click menu option, that is otherwise disabled for external authentication.
   As Zimbra user:
   
      cd /tmp
      wget https://github.com/Zimbra-Community/zimbra-foss-2fa/releases/download/0.0.1/tk_barrydegraaff_2fa.zip -O /tmp/tk_barrydegraaff_2fa.zip
      wget https://github.com/Zimbra-Community/zimbra-foss-2fa/releases/download/0.0.1/tk_barrydegraaff_2fa_admin.zip -O /tmp/tk_barrydegraaff_2fa_admin.zip
      zmzimletctl deploy tk_barrydegraaff_2fa.zip
      zmzimletctl deploy tk_barrydegraaff_2fa_admin.zip

18. Install Java extension

   As root:
   
      mkdir /opt/zimbra/lib/ext/zimbraprivacyidea
      wget https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/extension/out/artifacts/zimbraprivacyIdea_jar/privacyIdeazimbra.jar -O /opt/zimbra/lib/ext/zimbraprivacyidea/privacyIdeazimbra.jar
      
   If you want to set-up a single domain
   
      cd /opt/zimbra/lib/ext/zimbraprivacyidea
      wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/extension/config/config.properties -O /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties

   If you want to set-up multiple domains
   
      cd /opt/zimbra/lib/ext/zimbraprivacyidea
      wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/extension/config/config-multi-domain.properties -O /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties
      
   As zimbra `zmmailboxdctl restart` to load the extension.

19. Configure the Java extension

      Open /opt/zimbra/lib/ext/zimbraprivacyidea/config.properties using nano or vi and add admin tokens for each of your PrivacyIDEA docker containers. You can get an admin token by running. `docker container exec -it privacyidea /usr/bin/pi-manage api createtoken -r admin -d 7200`

      In the properties file you can set the following properties
      
      | Property  | Description  | Example/comments   |
      |---|---|---|
      | apiURI  | the url to the PrivacyIDEA instance | http://172.28.0.2:8000  |
      | token   | the admin token  | `docker container exec -it privacyidea /usr/bin/pi-manage api createtoken -r admin -d 7200` |
      | initJSON  | the JSON string that holds the settings for creation of the token  | `{"timeStep":30,"otplen":6,"genkey":true,"description":"zimbratokendescr","type":"totp","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}`  |
      | deviceJSON  | the JSON string that holds the settings for creation of device/application passcodes | `{"otpkey":"zimbradevicepasscode","description":"zimbratokendescr","type":"pw","radius.system_settings":true,"2stepinit":false,"validity_period_start":"","validity_period_end":"","user":"zimbrauserdonotchangethis","realm":"zimbra"}`  |
      | accountname_with_domain  | boolean, if set to false, the username will be passed to PrivacyIDEA excluding the domainname. Aka info@example.com will be looked up as info. When set to true, info@example.com needs to exist as a user in PrivacyIDEA  |   |
                 
       In case you want/need a configuration per domain, you can add the properties by appending the domain name like so:
       apiURI_example.com
       token_example.com
      
       The extension will first look for property_domain.com if that cannot be found, it will use property. So if apiURI_example.com is present, it will use that for users in example.com. If there is no apiURI_example.com it will use apiURI for users in example.com. See the example config files https://github.com/Zimbra-Community/zimbra-foss-2fa/tree/master/extension/config.

20. How to revoke API tokens created with `pi-manage api createtoken`

      You cannot remove individual tokens, but you can invalidate them all by changing the "SECRET_KEY" in pi.cfg by running `docker container exec -it privacyidea nano /etc/privacyidea/pi.cfg` and then `docker container restart privacyidea`.
 
21. Hide PrivacyIDEA UI

    Since all tokens can be added/removed via Zimbra, you do not need the PrivacyIDEA web interface. You can remove the open port like so:

         docker container stop privacyidea
         docker container rm privacyidea
         docker run --init --net zimbradocker --ip 172.18.0.2 --name privacyidea --restart=always -v privacyidea_data:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_mariadb:/var/lib/mysql -v /opt/privacyIdeaLDAPProxy:/opt/privacyIdeaLDAPProxy -d zetalliance/privacy-idea:latest


### License

Copyright (C) 2015-2019  Barry de Graaff [Zeta Alliance](https://zetalliance.org/)

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

   



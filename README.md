# Installing Zimbra Open Source Two Factor Authentication with PrivacyIDEA

These steps will set-up your Zimbra Open Source Edition server with Two Factor Authentication. The 2FA parts are powered by PrivacyIDEA and will run in a Docker container on your Zimbra server.

Technically this makes Zimbra support all 2FA tokens PrivacyIDEA supports. This includes TOTP, HOTP, Yubikey and U2F. This is much more than the Zimbra Network edition, which only supports TOTP.

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

2. If you want, you can build your own Docker image, that way you have the latest version of everything and get some know-how along the way. See https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/privacyidea/README.md
   
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

   You should be able to connect to PrivacyIDEA at https://yourzimbra:5000/ it can take a couple of minutes for it to start. Default username: admin/test (you change it now by running `docker exec -it privacyidea /usr/bin/pi-manage admin change -p admin`). Do not create the Initial Realm if PrivacyIDEA asks you when you log in to the web interface!

7. Configure PrivacyIDEA

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

   This will allow you to find your base DN as well. Usually something like `ou=people,dc=example,dc=com` don't forget to hit the `Preset OpenLDAP` and set `Loginname Attribute` to `mail`.


![01-pi-ldap.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/01-pi-ldap.png)

   If you need to support multiple domains, you must create an ldap-resolver for each domain. (Just repeat as screenshot) To tell them apart choose a resolver name that contains the domain name (example: examplecom).

![02-pi-resolver.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/02-pi-resolver.png)

   You MUST use only one REALM and it should include all your resolvers. If you do something else, the ldap-proxy will not work.

![03-pi-users.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/03-pi-users.png)

   Go to config -> policies -> create new policy and set a policy with scope `authentication` and set passthru->userstore and otppin->userstore. Realm: Zimbra, Resolver: SELECT THEM ALL! See the documentation: https://privacyidea.readthedocs.io/en/latest/policies/authentication.html
   
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

   Open the file https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/patches/login-jsp-patch.js the patch needs to go in /opt/zimbra/jetty/webapps/zimbra/public/login.jsp the patch needs to be added just before the final </script> tag. You need to repeat this whenever you upgrade Zimbra to a new version.

16. Update the Zimbra change password dialog

   Open the file https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/patches/changepass-patch.js the patch needs to go in /opt/zimbra/jetty/webapps/zimbra/h/changepass the patch needs to be added just before the final </body> tag. You need to repeat this whenever you upgrade Zimbra to a new version.

## To-do's

- Implement Zimlet to add/remove token? using https://privacyidea.readthedocs.io/en/latest/modules/api/validate.html?highlight=transaction_id#post--validate-check
- Proxy using wsgi instead of http https://privacyidea.readthedocs.io/en/latest/installation/system/wsgiscript.html
- Dockerize https://www.stefanseidel.info/Z-Push_on_Zimbra_8

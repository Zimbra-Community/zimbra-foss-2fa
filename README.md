# Installing PrivacyIDEA Docker Containers

These steps will install privacyidea and privacyidea-ldap-proxy using Docker. You can use privacyidea-ldap-proxy to add OTP features to systems that normally only support LDAP authentication. This Docker container can be run on a Zimbra mailbox node, combined with a PrivacyIDEA server this adds 2FA to Zimbra. 

1. Install docker-ce (you cannot use your distro's docker) see:
   https://docs.docker.com/install/linux/docker-ce/centos/
   https://docs.docker.com/install/linux/docker-ce/ubuntu/
   
   Enable docker on server startup: `systemctl enable docker`
   Start docker now: `systemctl start docker`

   Make sure to have NTP running on your Host (Zimbra server) or wherever your docker containers run, so they all get the correct time. 
   
   `yum install -y ntpdate`
   `ntpdate 0.us.pool.ntp.org`
   `which ntpdate` (remember full path)
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
       ldapsearch -x -H $ldap_master_url -D $zimbra_ldap_userdn -w $zimbra_ldap_password "mail=*"

   This will allow you to find your base DN as well. Usually something like `ou=people,dc=example,dc=com` don't forget to hit the `Preset OpenLDAP`.

        mkdir -p /opt/privacyIdeaLDAPProxy
        cd /opt/privacyIdeaLDAPProxy
        wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/config.ini
        
   Open the config.ini and set the `password` under `service-account` and set the correct IP in `endpoint` under `ldap-backend`. It is the IP from the netstat result.

5. Run the privacy-idea container

        docker run --init -p 5000:80 -p 1389:1389 --name privacyidea --restart=always -v privacyidea_data:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_mariadb:/var/lib/mysql -v /opt/privacyIdeaLDAPProxy:/opt/privacyIdeaLDAPProxy -d zetalliance/privacy-idea:latest

   You should be able to connect to a UI at port 5000 it can take a couple of minutes for it to start. Default username: admin/test (you change it!!)

6. Configure PrivacyIDEA

   On your Zimbra server find out on what IP ldap listens `netstat -tulpn | grep 389` and configure PrivacyIDEA as in the screenshots. To find out your LDAP settings (run as zimbra user):

       source ~/bin/zmshutil 
       zmsetvars 
       echo $zimbra_ldap_password
       echo $zimbra_ldap_userdn
       ldapsearch -x -H $ldap_master_url -D $zimbra_ldap_userdn -w $zimbra_ldap_password "mail=*"

   This will allow you to find your base DN as well. Usually something like `ou=people,dc=example,dc=com` don't forget to hit the `Preset OpenLDAP`.


![01-pi-ldap.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/01-pi-ldap.png)
![02-pi-resolver.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/02-pi-resolver.png)
![03-pi-users.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/03-pi-users.png)

   Go to config -> policies -> create new policy and set a policy with scope `authentication` and set passthru->userstore and otppin->userstore. See the documentation: https://privacyidea.readthedocs.io/en/latest/policies/authentication.html
   
![04-pi-policy.png](https://github.com/Zimbra-Community/zimbra-foss-2fa/raw/master/screenshots/04-pi-policy.png)   

7. You can now enroll TOTP tokens for the users

8. Try and see if it works by doing LDAP searches

   You must append to OTP code to the password like so:

       ldapsearch -x -H ldap://zimbraserver:389 -D uid=user2,ou=people,dc=zimbradev,dc=barrydegraaff,dc=tk -w "PASSWORD HERE" "mail=*"
       ldapsearch -x -H ldap://172.17.0.2:1389 -D uid=user2,ou=people,dc=zimbradev,dc=barrydegraaff,dc=tk -w "PASSWORD HERE***OTP HERE***" "mail=*"

   If it does not work, check if PrivacyIDEA works directly using the API `curl -d "user=user1&pass=testabc387223" -X POST http://zimbraserver:5000/validate/check`, don't forget your firewall.
     
9. Debug and reading the logs

   You can run commands in the docker container by doing `docker exec -it privacyidea bash` and you can see the logs using `tail -f /var/lib/docker/volumes/privacyidea_log/_data/privacyidea.log` on the Zimbra server. And `docker container logs privacyidea`.
    
10. Now you can configure your Zimbra Domain with external authentication, basically pointing it to the LDAP Proxy

11. If it all works, don't forget to run as Zimbra user: `zmprov md example.com zimbraAuthFallbackToLocal FALSE`

to-do implement api: https://privacyidea.readthedocs.io/en/latest/modules/api/validate.html?highlight=transaction_id#post--validate-check

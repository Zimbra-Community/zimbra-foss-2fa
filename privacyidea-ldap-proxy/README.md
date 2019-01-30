# Installing PrivacyIDEA Docker Containers

These steps will install privacyidea and privacyidea-ldap-proxy using Docker. You can use privacyidea-ldap-proxy to add OTP features to systems that normally only support LDAP authentication. This Docker container can be run on a Zimbra mailbox node, combined with a PrivacyIDEA server this adds 2FA to Zimbra. 

1. Install docker-ce (you cannot use your distro's docker) see:
   https://docs.docker.com/install/linux/docker-ce/centos/
   https://docs.docker.com/install/linux/docker-ce/ubuntu/
   
   Enable docker on server startup: systemctl enable docker
   Start docker now: systemctl start docker

   Make sure to have NTP running on your Host (Zimbra server) or wherever your docker containers run, so they all get the correct time. 
   
   yum install -y ntpdate
   ntpdate 0.us.pool.ntp.org
   which ntpdate (remember full path)
   and then add to crontab using `crontab -e`
   1 * * * * (add full path here)/ntpdate 0.us.pool.ntp.org
   
   for CentOS it will be:
   1 * * * * /usr/sbin/ntpdate 0.us.pool.ntp.org
   
2. Create storage volumes

        docker volume create --name privacyidea_data
        docker volume create --name privacyidea_log
        docker volume create --name privacyidea_mariadb

6. Test run the privacy-idea container

        docker run --init -p 5000:80 --name privacyidea --restart=always -v privacyidea_data:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_mariadb:/var/lib/mysql -d privacy-idea



      
      
3. Prepare your configuration

        mkdir -p /opt/privacyIdeaLDAPProxy
        cd /opt/privacyIdeaLDAPProxy
        wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/config.ini


5. Build your docker image

        docker image build -t privacy-idea-ldap-proxy .   

6. Do a test run for your PrivacyIDEA LDAP Proxy

        docker container run -v /opt/privacyIdeaLDAPProxy:/opt/privacyIdeaLDAPProxy privacy-idea-ldap-proxy


7. Configure your network in docker-compose.yml run it via

        docker-compose up -d

8. Try and resolve the LDAP

       ldapsearch -x -H ldap://192.168.17.250:1389 -D "uid=admin,ou=people,dc=zimbradev,dc=barrydegraaff,dc=tk" -w "PASSWORD HERE"

9. Try and read the logs

       docker-compose logs -f privacy-idea-ldap-proxy

       
    

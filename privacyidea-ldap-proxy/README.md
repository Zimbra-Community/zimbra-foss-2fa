# Installing PrivacyIDEA LDAP Proxy

These steps will install privacyidea-ldap-proxy using Docker. You can use privacyidea-ldap-proxy to add OTP features to systems that normally only support LDAP authentication. This Docker container can be run on a Zimbra mailbox node, combined with a PrivacyIDEA server this adds 2FA to Zimbra. 

1. Install docker-ce (you cannot use your distro's docker) see:
   https://docs.docker.com/install/linux/docker-ce/centos/
   https://docs.docker.com/install/linux/docker-ce/ubuntu/

2. Clean existing docker, optional step if you run into problems, it will remove all your existing docker data:

        docker container rm -f $(docker container ls -aq)
        docker rmi $(docker images -a -q)
        docker system prune -a -f

3. Prepare your configuration

        mkdir -p /opt/privacyIdeaLDAPProxy
        cd /opt/privacyIdeaLDAPProxy
        wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/config.ini

4.  Get the installer

        git clone https://github.com/Zimbra-Community/zimbra-foss-2fa
        cd zimbra-foss-2fa

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

       
       
# Installing PrivacyIDEA

These steps will install privacyidea in a Docker container that can be run on a Zimbra mailbox node, combined with PrivacyIDEA LDAP Proxy from above this adds 2FA to Zimbra.

10. Build the docker image

        cd ..
        cd privacyidea
        docker image build -t privacy-idea .  

11. Test run the privacy-idea container

        docker container run privacy-idea

# Docker image for PrivacyIDEA

These are the steps to build a fresh docker image, it is basically the source for our image at Docker Hub.

1. Clean existing docker, optional step if you run into problems, it will remove all your existing docker data. So suggest you do it on a development machine. Not prod!

        docker container rm -f $(docker container ls -aq)
        docker rmi $(docker images -a -q)
        docker system prune -a -f
        docker volume rm $(docker volume ls -q | grep privacyidea_)

2.  Get the installer

        yum -y install git / apt -y install git
        git clone https://github.com/Zimbra-Community/zimbra-foss-2fa
        cd zimbra-foss-2fa

3. Build the docker image

        cd privacyidea
        docker image build -t privacy-idea .  

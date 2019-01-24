# docker container rm -f $(docker container ls -aq)
# docker rmi $(docker images -a -q)
# docker system prune -a -f
# docker volume rm $(docker volume ls -q | grep privacyidea_)
 
# docker image build -t privacy-idea .

# docker volume create --name privacyidea_data
# docker volume create --name privacyidea_log
# docker volume create --name privacyidea_mariadb

# docker run --init -p 5000:80 --name privacyidea --restart=always -v privacyidea_data:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_mariadb:/var/lib/mysql -d privacy-idea

#  --init changes the pid of supervisord, allowing to pass arguments

# docker container logs --follow privacyidea
# docker exec -it privacyidea bash

# docker container stop privacyidea
# docker container ls -a
# docker container start privacyidea

FROM centos:centos7

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
RUN yum -y update \
   &&  yum -y install epel-release \
   && yum -y install yum-priorities

RUN yum -y install net-tools
RUN yum -y install wget curl

RUN sed -i 's|^enabled=1|enabled=1\npriority=10|' /etc/yum.repos.d/epel.repo

RUN yum -y update
RUN yum -y groupinstall 'Development Tools'
#RUN yum -y install open-vm-tools net-tools
RUN yum -y install supervisor
RUN yum -y install libxslt-devel libxml2-devel python-pip

RUN yum install -y mariadb-server httpd mod_wsgi mod_ssl python-devel gcc mariadb-devel libjpeg-devel \
openldap-devel perl-libwww-perl perl-Config-IniFiles \
perl-Try-Tiny perl-Data-Dump perl-JSON perl-LWP-Protocol-http* libffi-devel \
freetype-devel libpng-devel

#We could include apache if we want to do https...
#RUN echo -e "[program:apache2]\ncommand=/usr/sbin/apachectl -D \"FOREGROUND\" -k start\nredirect_stderr=true" > /etc/supervisord.d/httpd.ini
RUN echo -e "[program:mysqld]\ncommand=/usr/bin/mysqld_safe --basedir='/usr' --datadir='/var/lib/mysql'\nredirect_stderr=true" > /etc/supervisord.d/mysqld.ini

#FIXME: run this only once
RUN echo -e "[program:init]\ncommand=/setup.sh\nredirect_stderr=true" > /etc/supervisord.d/init.ini


#FIXME: move to docker-compose.yml
EXPOSE 80/tcp

ADD setup.sh /setup.sh
RUN chmod +rx /setup.sh

#FIXME: passwordless root log-in
RUN /usr/bin/mysql_install_db
RUN chown mysql:mysql /var/lib/mysql -R

RUN mkdir /opt/privacyIDEA
RUN mkdir /etc/privacyidea
RUN mkdir /var/log/privacyidea

#FIXME: fork requirement
#ADD https://raw.githubusercontent.com/privacyidea/privacyidea/master/requirements.txt /opt/privacyIDEA/requirements.txt
ADD requirements.txt /opt/privacyIDEA/requirements.txt
ADD pi.cfg /etc/privacyidea/pi.cfg

WORKDIR /opt/privacyIDEA
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN pip install MySQL-python
RUN pip install privacyidea

#Debug anyone?
#ENTRYPOINT ["sleep", "500"]
ENTRYPOINT ["/usr/bin/supervisord", "-n","-c","/etc/supervisord.conf"]

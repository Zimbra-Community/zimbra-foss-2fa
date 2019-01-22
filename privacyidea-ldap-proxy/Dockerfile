FROM centos:centos7

RUN yum -y update \
   && yum -y install epel-release \
   && yum -y install python-pip \
   && yum install -y which gcc python-devel git \ 
   && yum install -y openldap-devel

RUN pip install --upgrade pip

VOLUME /opt/privacyIdeaLDAPProxy/ /opt/privacyIdeaLDAPProxy/
ADD https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/privacyidea-ldap-proxy/requirements.txt /app/
WORKDIR /app
RUN pip install -r /app/requirements.txt

RUN git clone https://github.com/privacyidea/privacyidea-ldap-proxy
WORKDIR /app/privacyidea-ldap-proxy
RUN pip install .
ENTRYPOINT twistd -n ldap-proxy -c /opt/privacyIdeaLDAPProxy/config.ini
CMD ["/opt/privacyIdeaLDAPProxy/config.ini"]

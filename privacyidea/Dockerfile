# docker image build -t privacy-idea .
# docker container logs --follow privacyidea
# docker exec -it privacyidea bash


FROM zetalliance/mysql-zeta-pi:latest

RUN apt-get update
RUN apt-get install -y gnupg2

RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" > /etc/apt/sources.list.d/nginx.list && \
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:privacyidea/privacyidea

RUN apt-get update \
    && apt-get install -y -q --no-install-recommends --no-install-suggests \
        net-tools \
        tzdata \
        ca-certificates \
        supervisor \
        nginx \
        uwsgi \
        uwsgi-plugin-python \
        python-privacyidea \
        python-mysqldb \
        sqlite3 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/sites-enabled/
COPY conf/pi.cfg /etc/privacyidea/pi.cfg
COPY conf/supervisord.conf /etc/supervisord.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx-site.conf /etc/nginx/sites-available/privacyidea
COPY privacyideaapp.py /etc/privacyidea/privacyideaapp.py
COPY privacyidea.xml /privacyidea.xml

COPY setup.sh /sbin/setup.sh
COPY entrypoint.sh /sbin/entrypoint.sh

EXPOSE 5000

VOLUME /etc/privacyidea
VOLUME /var/log/privacyidea
VOLUME /var/lib/privacyidea
VOLUME /var/lib/mysql

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-n","-c", "/etc/supervisord.conf"]

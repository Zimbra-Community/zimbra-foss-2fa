# Original from: https://github.com/sameersbn/docker-mysql/blob/master/Dockerfile
# docker image build -t mysql .
# docker tag mysql:latest zetalliance/mysql-zeta-pi:latest
# docker push zetalliance/mysql-zeta-pi:latest

FROM ubuntu:xenial-20180525

ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server \
 && rm -rf ${MYSQL_DATA_DIR} \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3306/tcp
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/bin/mysqld_safe"]

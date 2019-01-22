FROM alpine:3.7

ARG PRIVACYIDEA_GIT_VERSION=v2.22
ARG PRIVACYIDEA_GIT_URL=git+https://github.com/privacyidea/privacyidea.git
ARG SSL_CERT_NAME=''
ARG PRIVACYIDEA_HOME=/PRIVACYIDEA
ARG UWSGI_VERSION=2.0.17.1
ARG PYTHON_VERSION=2.7.14
ARG PI_SSL_CRT_URL=''
ENV PRIVACYIDEA_HOME=${PRIVACYIDEA_HOME}
ENV PI_SSL_CERT_NAME=${SSL_CERT_NAME}
ENV PRIVACYIDEA_CONFIG_DIR=/etc/privacyidea

# # Install build deps, then run `pip install`, then remove unneeded build deps all in a single step. Correct the path to your production requirements file, if needed.
RUN apk add --no-cache \
  curl \
  pcre-dev \
	libxml2-dev \
	libxslt-dev

RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
            git \
            gcc \
            g++ \
            make \
            libc-dev \
            musl-dev \
            linux-headers \
            mariadb-client-libs \
            mariadb-dev \
            postgresql-dev \
            freetype-dev \
            libpng \
						jpeg-dev \
            libffi-dev \
						py2-pip \
						python2-dev \
    && mkdir $PRIVACYIDEA_HOME \
		&& mkdir $PRIVACYIDEA_CONFIG_DIR \
		&& mkdir $PRIVACYIDEA_HOME/python \
		&& curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o /tmp/Python-${PYTHON_VERSION}.tgz \
		&& tar -xvzf /tmp/Python-${PYTHON_VERSION}.tgz \
		&& cd Python-${PYTHON_VERSION} \
		&& ./configure \
				--enable-shared \
				--prefix=$PRIVACYIDEA_HOME/python \
				--with-ensurepip=install \
				--enable-unicode=ucs4 \
		&& make \
		&& make install \
		&& cd .. \
		&& rm -rf Python-${PYTHON_VERSION} \
		&& $PRIVACYIDEA_HOME/python/bin/pip install uwsgi==${UWSGI_VERSION} \
		# there were warning in logs that this module is not installed
    && $PRIVACYIDEA_HOME/python/bin/pip install virtualenv \
    && $PRIVACYIDEA_HOME/python/bin/virtualenv -p $PRIVACYIDEA_HOME/python/bin/python --no-site-packages $PRIVACYIDEA_HOME/venv \
    && source $PRIVACYIDEA_HOME/venv/bin/activate \
    && pip install ${PRIVACYIDEA_GIT_URL}@${PRIVACYIDEA_GIT_VERSION} \
    && runDeps="$( \
              scanelf --needed --nobanner --recursive /usr/local \
                      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                      | sort -u \
                      | xargs -r apk info --installed \
                      | sort -u \
      )" \
    && apk add --no-cache --virtual .python-rundeps $runDeps \
    && apk del .build-deps

RUN if [ $PI_SSL_CERT_NAME ]; \
    then \
	curl $PI_SSL_CRT_URL/${PI_SSL_CERT_NAME}.crt -o /usr/local/share/ca-certificates/${PI_SSL_CERT_NAME}.crt \
        && update-ca-certificates \
        && apk del curl; \
    fi;

# Copy your application code to the container (make sure you create a .dockerignore file if any large files or directories should be excluded)

ADD pi.cfg  $PRIVACYIDEA_CONFIG_DIR
ADD docker-entrypoint.sh $PRIVACYIDEA_CONFIG_DIR

# uWSGI will listen on this port
EXPOSE 8000

# Add any custom, static environment variables needed by Django or your settings file here:
ENV PRIVACYIDEA_CONFIGFILE=$PRIVACYIDEA_CONFIG_DIR/pi.cfg
ENV PI_AUDIT_KEY_PRIVATE=$PRIVACYIDEA_CONFIG_DIR/private.pem
ENV PI_AUDIT_KEY_PUBLIC=$PRIVACYIDEA_CONFIG_DIR/public.pem
ENV PI_LOGFILE=/var/log/privacyidea.log
ENV PI_ENCFILE=$PRIVACYIDEA_CONFIG_DIR/enckey

RUN chmod +x $PRIVACYIDEA_CONFIG_DIR/docker-entrypoint.sh \
    && addgroup -g 2000 privacyidea \
    && adduser -u 1000 -D -G privacyidea privacyidea \
    && chown -R 1000:2000 $PRIVACYIDEA_CONFIG_DIR \
		&& touch $PI_LOGFILE && chown 1000:2000 $PI_LOGFILE

WORKDIR $PRIVACYIDEA_CONFIG_DIR
USER 1000:2000

# uWSGI configuration (customize as needed):
ENV UWSGI_HTTP=:8000 UWSGI_MASTER=1 UWSGI_WORKERS=8 UWSGI_THREADS=1 UWSGI_UID=1000 UWSGI_GID=2000 UWSGI_LAZY_APPS=1 UWSGI_WSGI_ENV_BEHAVIOR=holy

#Start uWSGI
CMD ["./docker-entrypoint.sh"]

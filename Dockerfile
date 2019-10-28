FROM ubuntu:18.04

LABEL maintainer="frauhottelmann" \
      dockerfile-version="1.1" \
      description="Docker image with freeradius, daloradius, apache2, php \
                   You need to supply your own MySQL-Server."

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV MYSQL_USER radius
ENV MYSQL_PASSWORD dalodbpass
ENV MYSQL_HOST localhost
ENV MYSQL_PORT 3306
ENV MYSQL_DATABASE radius

ENV TZ Europe/Berlin

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
                    apt-utils \
                    tzdata \
                    apache2 \
                    libapache2-mod-php \
                    cron \
                    freeradius-config \
                    freeradius-utils \
                    freeradius \
                    freeradius-common \
                    freeradius-mysql \
                    net-tools \
                    php \
                    php-common \
                    php-gd \
                    php-curl \
                    php-mail \
                    php-mail-mime \
                    php-db \
                    php-pear \
                    php-mysql \
                    mariadb-client \
                    libmysqlclient-dev \
                    supervisor \
                    unzip \
                    wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && pear install -a DB \
 && pear install -a Mail \
 && pear install -a Mail_Mime

ENV DALO_VERSION 1.1-2

RUN wget https://github.com/lirantal/daloradius/archive/"$DALO_VERSION".zip \
 && unzip "$DALO_VERSION".zip \
 && rm "$DALO_VERSION".zip \
 && mv daloradius-"$DALO_VERSION" /var/www/html/daloradius \
 && chown -R www-data:www-data /var/www/html/daloradius \
 && chmod 644 /var/www/html/daloradius/library/daloradius.conf.php

EXPOSE 1812 1813 80

COPY supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor-freeradius.conf /etc/supervisor/conf.d/freeradius.conf
COPY freeradius-default-site /etc/freeradius/3.0/sites-available/default

COPY init.sh /cbs/
COPY supervisor.conf /etc/

CMD ["sh", "/cbs/init.sh"]

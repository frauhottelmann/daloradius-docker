FROM ubuntu:18.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ENV MYSQL_PASSWORD "dalodbpass"

RUN apt-get update \
 && echo debconf debconf/frontend select Noninteractive | debconf-set-selections \
 && echo tzdata tzdata/Areas select Europe | debconf-set-selections \
 && echo tzdata tzdata/Zones/Europe select Berlin | debconf-set-selections \
 && apt-get install --yes --no-install-recommends \
                    apt-utils tzdata \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
                    apache2 \
                    apg \
                    freeradius \
                    freeradius-common \
                    freeradius-utils \
                    freeradius-mysql \
                    libapache2-mod-php \
                    php \
                    php-common \
                    php-gd \
                    php-curl \
                    php-mail \
                    php-mail-mime \
                    php-db \
                    php-pear \
                    php-mysqlnd \
                    mysql-client \
                    libmysqlclient-dev \
                    unzip \
                    wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor-freeradius.conf /etc/supervisor/conf.d/freeradius.conf

COPY init.sh /cbs/
COPY supervisor-freeradius.conf /cbs/
COPY freeradius-default-site /cbs/

ENTRYPOINT ["sh", "/cbs/init.sh"]

EXPOSE 1812 1813 80

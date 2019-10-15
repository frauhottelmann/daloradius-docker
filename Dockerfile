FROM ubuntu:18.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && echo debconf debconf/frontend select Noninteractive | debconf-set-selections \
 && echo tzdata tzdata/Areas select Europe | debconf-set-selections \
 && echo tzdata tzdata/Zones/Europe select Berlin | debconf-set-selections \
 && apt-get install --yes --no-install-recommends \
                    apt-utils tzdata \
 && apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && echo mysql-server mysql-server/root_password password initial | debconf-set-selections \
 && echo mysql-server mysql-server/root_password_again password initial | debconf-set-selections \
 && apt-get install --yes --no-install-recommends \
                    apache2 libapache2-mod-php \
                    php php-common php-gd php-curl php-mail php-mail-mime php-db php-mysqlnd \
                    mysql-server mysql-client libmysqlclient-dev \
 && mkdir -p /var/run/mysqld \
 && chown mysql:mysql /var/run/mysqld \
 && apt-get clean

COPY supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor-mysql.conf /etc/supervisor/conf.d/mysql.conf

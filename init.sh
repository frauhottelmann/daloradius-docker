#!/bin/bash
set -e

echo '#!/bin/bash' > /cbs/init.sh
echo 'echo "Initialization error" 1>&2' >> /cbs/init.sh

DEBIAN_FRONTEND=noninteractive

ROOTDBPASS="$(apg -a 1 -n 1 -M ncl -c /dev/urandom -q -m 15 -x 15)" 
DALODBPASS="$(apg -a 1 -n 1 -M ncl -c /dev/urandom -q -m 15 -x 15)" 

apt-get update
apt-get upgrade --yes 
apt-get install --yes --no-install-recommends freeradius freeradius-common freeradius-utils freeradius-mysql
cat /cbs/supervisor-freeradius.conf > /etc/supervisor/conf.d/freeradius.conf

wget https://github.com/lirantal/daloradius/archive/master.zip 
unzip master.zip 
rm master.zip 
mv daloradius-master /var/www/html/daloradius 
chown -R www-data:www-data /var/www/html/daloradius 
chmod 644 /var/www/html/daloradius/library/daloradius.conf.php

service mysql start
mysql -u root --password=initial -e "SET PASSWORD = '$ROOTDBPASS'; FLUSH PRIVILEGES;" 
mysql -u root --password=$ROOTDBPASS -e "CREATE DATABASE radius; GRANT ALL ON radius.* TO radius@localhost IDENTIFIED BY '$DALODBPASS'; FLUSH PRIVILEGES;" 
mysql -u radius --password=$DALODBPASS radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql 
mysql -u radius --password=$DALODBPASS radius < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql 
service mysql stop

cat /cbs/freeradius-default-site > /etc/freeradius/3.0/sites-available/default
sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|dialect = "sqlite"|dialect = "mysql"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|#\s*login = "radius"|login = "radius"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|#\s*password = "radpass"|password = "'$DALODBPASS'"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|#\s*read_clients = yes|read_clients = yes|' /etc/freeradius/3.0/mods-available/sql 
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
ln -s /etc/freeradius/3.0/mods-available/sqlcounter /etc/freeradius/3.0/mods-enabled/sqlcounter
sed -i 's|instantiate {|instantiate {\nsql|' /etc/freeradius/3.0/radiusd.conf # mods-enabled does not ensure the right order

sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = '';/\$configValues\['CONFIG_DB_PASS'\] = '$DALODBPASS';/" /var/www/html/daloradius/library/daloradius.conf.php 
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = 'root';/\$configValues\['CONFIG_DB_USER'\] = 'radius';/" /var/www/html/daloradius/library/daloradius.conf.php

rm -r /cbs/*

echo '#!/bin/bash' > /cbs/init.sh
echo 'supervisord -c /etc/supervisor.conf' >> /cbs/init.sh

supervisord -c /etc/supervisor.conf

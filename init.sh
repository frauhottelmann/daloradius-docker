#!/bin/bash
set -e

echo '#!/bin/bash' > /cbs/init.sh
echo 'echo "Initialization error" 1>&2' >> /cbs/init.sh

DEBIAN_FRONTEND=noninteractive

cat /cbs/supervisor-freeradius.conf > /etc/supervisor/conf.d/freeradius.conf

# Download and unzip Daloradius
wget https://github.com/lirantal/daloradius/archive/v$DALO_VERSION.zip
unzip v$DALO_VERSION.zip
rm v$DALO_VERSION.zip
mv daloradius-$DALO_VERSION /var/www/html/daloradius
chown -R www-data:www-data /var/www/html/daloradius
chmod 644 /var/www/html/daloradius/library/daloradius.conf.php

# Seed Database
mysql -u $MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql 
mysql -u $MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql 

# Enable SQL in freeradius
cat /cbs/freeradius-default-site > /etc/freeradius/3.0/sites-available/default
sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|dialect = "sqlite"|dialect = "mysql"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|#\s*read_clients = yes|read_clients = yes|' /etc/freeradius/3.0/mods-available/sql 
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
ln -s /etc/freeradius/3.0/mods-available/sqlcounter /etc/freeradius/3.0/mods-enabled/sqlcounter
sed -i 's|instantiate {|instantiate {\nsql|' /etc/freeradius/3.0/radiusd.conf # mods-enabled does not ensure the right order

# Enable status in freeadius
ln -s /etc/freeradius/3.0/sites-available/status /etc/freeradius/3.0/sites-enabled/status

# Set Database connection
sed -i 's|^#\s*server = .*|server = "'$MYSQL_HOST'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*port = .*|port = "'$MYSQL_PORT'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^\s*radius_db = .*|radius_db = "'$MYSQL_DATABASE'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^\s*password = .*|password = "'$MYSQL_PASSWORD'"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|^\s*login = .*|login = "'$MYSQL_USER'"|' /etc/freeradius/3.0/mods-available/sql

sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '$MYSQL_PORT';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" /var/www/html/daloradius/library/daloradius.conf.php 
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" /var/www/html/daloradius/library/daloradius.conf.php

rm -r /cbs/*

echo '#!/bin/bash' > /cbs/init.sh
echo 'supervisord -c /etc/supervisor.conf' >> /cbs/init.sh

supervisord -c /etc/supervisor.conf

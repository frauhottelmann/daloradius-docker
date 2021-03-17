#!/bin/bash
set -ex

# set init failed flag, used for next running
echo '#!/bin/bash' > /cbs/init.sh
echo 'echo "Initialization error" 1>&2' >> /cbs/init.sh

DEBIAN_FRONTEND=noninteractive

# wait for MySQL-Server to be ready
while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
    sleep 20
done

# check if the database if empty
table_count=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -se "SELECT COUNT(DISTINCT \`table_name\`) FROM \`information_schema\`.\`columns\` WHERE \`table_schema\` = '$MYSQL_DATABASE'")
if [[ $table_count -gt 0 ]]
then
  echo "database is not empty, skip importing"
else
  echo "database is empty, go to importing"

  # Seed Database
  mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql 
  mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /var/www/html/contrib/db/mysql-daloradius.sql 
fi

# set Database connection
sed -i 's|^#\s*server = .*|server = "'$MYSQL_HOST'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*port = .*|port = "'$MYSQL_PORT'"|' /etc/freeradius/3.0/mods-available/sql
sed -i '1,$s/radius_db.*/radius_db="'$MYSQL_DATABASE'"/g' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*password = .*|password = "'$MYSQL_PASSWORD'"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|^#\s*login = .*|login = "'$MYSQL_USER'"|' /etc/freeradius/3.0/mods-available/sql

sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" /var/www/html/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '$MYSQL_PORT';/" /var/www/html/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" /var/www/html/library/daloradius.conf.php 
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" /var/www/html/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" /var/www/html/library/daloradius.conf.php
sed -i "s/\$configValues\['FREERADIUS_VERSION'\] = .*;/\$configValues\['FREERADIUS_VERSION'\] = '3';/" /var/www/html/library/daloradius.conf.php

# set crontab config
sed -i "s/\$configValues\['CONFIG_DB_ENGINE'\] = .*;/\$configValues\['CONFIG_DB_ENGINE'\] = 'mysqli';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php
sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php
sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '$MYSQL_PORT';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php
sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" /var/www/html/contrib/scripts/maintenance/cleanStaleSessions.php

# replace init.sh
rm -r /cbs/*
echo '#!/bin/bash' > /cbs/init.sh
echo 'supervisord -c /etc/supervisor.conf' >> /cbs/init.sh

# run supervisord after first init
supervisord -c /etc/supervisor.conf

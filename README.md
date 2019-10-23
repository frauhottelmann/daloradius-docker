# Daloradius

## About
* Docker image for Daloradius
* includes freeradius 3, Apache, php
* needs a separate MariaDB or MySQL server

## Environment variables

### MYSQL_USER
standard value: *radius*
### MYSQL_PASSWORD
standard value: *dalodbpass*
### MYSQL_HOST
standard value: *localhost*
### MYSQL_PORT
standard value: *3306*
### MYSQL_DATABASE
standard value: *radius*
### TZ
standard value: *Europe/Berlin* - (see List of tz time zones)[https://en.wikipedia.org/wiki/List_of_tz_database_time_zones]

---
### DALO_VERSION
used for version control

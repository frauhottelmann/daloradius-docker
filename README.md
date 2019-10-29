# Daloradius
## About

* Docker image for Daloradius based on Ubuntu 18.04
* includes freeradius 3, Apache, php, MariaDB-client
* needs a separate MariaDB

## Tags

* versions correspond to Daloradius verisons
* the tags are prefixed by the platform
* right now I build amd64 and aarch64

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
standard value: *Europe/Berlin* - [see List of tz time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

---
### DALO_VERSION
used for version control

---
## Docker-compose example

https://github.com/frauhottelmann/daloradius-docker/blob/9089d3a8e34183779ae156004bf30fb6d0e0fc1a/docker-compose.yaml#L1-L34

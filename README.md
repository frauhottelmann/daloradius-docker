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

```yaml
version: "3"
services:
  radius:
    image: frauhottelmann/daloradius-docker
    container_name: radius
    restart: always
    depends_on:
      - "radius-mysql" 
    ports:
      - '1812:1812/udp'
      - '1813:1813/udp'
      - '80:80'
    environment:
      - MYSQL_HOST=radius-mysql
      - MYSQL_PORT=3306
      - MYSQL_DATABASE=radius
      - MYSQL_USER=radius
      - MYSQL_PASSWORD=dalodbpass
#    volumes:
#      - ./radius/clients.conf:/etc/freeradius/3.0/clients.conf
#      - ./radius/eap:/etc/freeradius/3.0/mods-available/eap
#      - ./ssl/fullchain.pem:/etc/freeradius/3.0/certs/fullchain.pem
#      - ./ssl/privkey.pem:/etc/freeradius/3.0/certs/privkey.pem
  radius-mysql:
    image: mariadb:10.1.41
    container_name: radius-mysql
    restart: always
    environment:
      - MYSQL_DATABASE=radius
      - MYSQL_USER=radius
      - MYSQL_PASSWORD=dalodbpass
      - MYSQL_ROOT_PASSWORD=dalorootpass
    volumes:
      - "./radius-mysql:/var/lib/mysql"
```

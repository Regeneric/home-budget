#!/bin/bash

source ../docker/.env

docker exec mariadb mariadb -u root -p"${SQL_ROOT_PASS}" -e "CREATE USER '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASS}';"
docker exec mariadb mariadb -u root -p"${SQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON *.* TO '${SQL_USER}'@'%';"
docker exec mariadb mariadb -u root -p"${SQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

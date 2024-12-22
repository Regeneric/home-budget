#!/bin/bash

source ../docker/.env

docker exec mongodb mongosh --authenticationDatabase admin -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --eval "$(cat init/create_temp_admin.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_DATABASE" -u "$MONGO_INITDB_USER" -p "$MONGO_INITDB_ROOT_PASSWORD" --eval "$(cat init/create_role.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_DATABASE" -u "$MONGO_INITDB_USER" -p "$MONGO_INITDB_ROOT_PASSWORD" --eval "$(cat init/create_root.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_DATABASE" -u "$MONGO_INITDB_USER" -p "$MONGO_INITDB_ROOT_PASSWORD" --eval "$(cat init/grant_role.js)"  admin
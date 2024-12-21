#!/bin/bash

ENV_FILE=../docker/.env

docker exec mongodb mongosh --authenticationDatabase admin -u "$(grep 'MONGO_INITDB_ROOT_USERNAME=' "$ENV_FILE" | cut -d '=' -f2)" -p "$(grep 'MONGO_INITDB_ROOT_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2)" --eval "$(cat init/create_temp_admin.js)" admin
docker exec mongodb mongosh --authenticationDatabase admin -u admin -p "$(grep 'MONGO_INITDB_ROOT_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2)" --eval "$(cat init/create_role.js)" admin
docker exec mongodb mongosh --authenticationDatabase admin -u admin -p "$(grep 'MONGO_INITDB_ROOT_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2)" --eval "$(cat init/create_root.js)" admin
docker exec mongodb mongosh --authenticationDatabase admin -u admin -p "$(grep 'MONGO_INITDB_ROOT_PASSWORD=' "$ENV_FILE" | cut -d '=' -f2)" --eval "$(cat init/grant_role.js)"  admin
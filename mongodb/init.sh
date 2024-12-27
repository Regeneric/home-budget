#!/bin/bash

source ../docker/.env

read -p "MongoDB database name: " database_name

cat << EOF > init/create_database.js
db = db.getSiblingDB('${database_name}');
EOF

docker exec mongodb mongosh --authenticationDatabase admin -u "$MONGO_USER" -p "$MONGO_ROOT_PASS" --eval "$(cat init/create_temp_admin.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_NAME" -u "$MONGO_INITDB_USER" -p "$MONGO_PASS" --eval "$(cat init/create_role.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_NAME" -u "$MONGO_INITDB_USER" -p "$MONGO_PASS" --eval "$(cat init/create_root.js)" admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_NAME" -u "$MONGO_INITDB_USER" -p "$MONGO_PASS" --eval "$(cat init/grant_role.js)"  admin
docker exec mongodb mongosh --authenticationDatabase "$MONGO_INITDB_NAME" -u "$MONGO_INITDB_USER" -p "$MONGO_PASS" --eval "$(cat init/create_database.js)"
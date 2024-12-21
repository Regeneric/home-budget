#!/bin/bash

docker exec mongo mongosh --authenticationDatabase admin --eval "$(cat init/create_temp_admin.js)" admin
docker exec mongo mongosh --authenticationDatabase admin -u admin -p jollyRos329 --eval "$(cat init/create_role.js)" admin
docker exec mongo mongosh --authenticationDatabase admin -u admin -p jollyRos329 --eval "$(cat init/create_root.js)" admin
docker exec mongo mongosh --authenticationDatabase admin -u admin -p jollyRos329 --eval "$(cat init/grant_role.js)"  admin
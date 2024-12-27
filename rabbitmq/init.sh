#!/bin/bash

source ../docker/.env

echo "RabbitMQ Installation"
echo "Add user $RABBIT_USER"
docker exec -i rabbitmq rabbitmqctl add_user $RABBIT_USER $RABBIT_PASS
echo "Set Permissions to user $RABBIT_USER"
docker exec -i rabbitmq rabbitmqctl set_permissions $RABBIT_USER ".*" ".*" ".*"
echo "Set Administrator user tag to $RABBIT_USER"
docker exec -i rabbitmq rabbitmqctl set_user_tags $RABBIT_USER administrator
docker exec -i rabbitmq rabbitmq-plugins enable rabbitmq_management
docker exec -i rabbitmq rabbitmqctl delete_user guest

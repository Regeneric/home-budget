#!/bin/bash

ENV_FILE=../docker/.env

AMQP_USER="$(grep 'AMQP_USER=' "$ENV_FILE" | cut -d '=' -f2)"
AMQP_PASS="$(grep 'AMQP_PASS=' "$ENV_FILE" | cut -d '=' -f2)"

echo "AMQP Installation"
echo "Add user $AMQP_USER"
docker exec -i rabbitmq rabbitmqctl add_user $AMQP_USER $AMQP_PASS
echo "Set Permissions to user $AMQP_USER"
docker exec -i rabbitmq rabbitmqctl set_permissions $AMQP_USER ".*" ".*" ".*"
echo "Set Administrator user tag to $AMQP_USER"
docker exec -i rabbitmq rabbitmqctl set_user_tags $AMQP_USER administrator
docker exec -i rabbitmq rabbitmq-plugins enable rabbitmq_management
docker exec -i rabbitmq rabbitmqctl delete_user guest

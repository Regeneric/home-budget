#!/bin/bash

if [[ -f "docker/.env" ]]; then
    # We want Y/N only
    answer=-1
    while [[ ! ${answer,,} =~ ^y(es)?$ && ! ${answer,,} =~ ^n(o)?$ ]]; do
      read -p "Do you want to delete current docker/.env file? (Y/N): " answer
    done
    if [[ ${answer,,} =~ ^y(es)?$ ]]; then rm -f docker/.env
    else exit 0; fi
fi

read -p "Source code location: "                source_code_location
read -p "Enter domain name: "                   domain_name

read -p "Enter internal IP (eg. 192.168.1.5): " internal_ip
read -p "Enter internal IP mask (eg. 24): "     internal_mask

read -p "Enter external IP (eg. 192.168.1.5): " external_ip
read -p "Enter external IP mask (eg. 24): "     external_mask

# We want Y/N only
answer=-1
while [[ ! ${answer,,} =~ ^y(es)?$ && ! ${answer,,} =~ ^n(o)?$ ]]; do
    read -p "Would you like to run services on the internal IP? (Y/N): " answer
done
if [[ ${answer,,} =~ ^y(es)?$ ]]; then
    sql_host=$internal_ip
    mongo_host=$internal_ip
    rabbit_host=$internal_ip
else
    read -p "Enter MariaDB host (eg. 192.168.1.5): "  sql_host
    read -p "Enter MongoDB host (eg. 192.168.1.5): "  mongo_host
    read -p "Enter RabbitMQ host (eg. 192.168.1.5): " rabbit_host
fi

read -s -p "Enter MariaDB root password: "  mysql_root_password
echo ""
read -s -p "Enter MariaDB user password: "  mysql_user_password
echo ""

read -s -p "Enter MongoDB root password: "  mongo_root_password
echo ""
read -s -p "Enter MongoDB user password: "  mongo_user_password
echo ""

read -s -p "Enter RabbitMQ root password: " rabbitmq_root_password
echo ""
read -s -p "Enter RabbitMQ user password: " rabbitmq_user_password


echo "Creating Docker .env file..."

current_path=$(pwd)
cat << EOF > docker/.env
ENV_FILE=.env

CONFIG_FOLDER=${current_path%/setup}
NGINX_CONF_LOCATION=${current_path%/setup}/nginx
BIND_CONF_LOCATION=${current_path%/setup}/bind9
SOURCE_CODE_LOCATION=${current_path%/setup}/${source_code_location}

DOMAIN_NAME=${domain_name}

INTERNAL_IP=${internal_ip}
INTERNAL_MASK=${internal_mask}

EXTERNAL_IP=${external_ip}
EXTERNAL_MASK=${external_mask}

SQL_USER=root
SQL_PASS=${mysql_user_password}
SQL_ROOT_PASS=${mysql_root_password}
SQL_HOST=${sql_host}
SQL_PORT=3306

MONGO_USER=root
MONGO_PASS=${mongo_user_password}
MONGO_ROOT_PASS=${mongo_root_password}
MONGO_HOST=${mongo_host}
MONGO_PORT=27017
MONGO_REPL_SET_NAME=mongoreplicaset1
MONGO_INITDB_USER=admin
MONGO_INITDB_NAME=admin

RABBIT_USER=root
RABBIT_PASS=${rabbitmq_user_password}
RABBIT_ROOT_PASS=${rabbitmq_root_password}
RABBIT_HOST=${rabbit_host}
EOF

echo "Creating Docker .env file complete!"


echo "Creating MongoDB keyFile..."

if [[ ! -d "mongodb/init" ]]; then mkdir -p mongodb/init; fi
if [[ ! -d "mongodb/data" ]]; then mkdir -p mongodb/data; fi
if [[ ! -d "mognodb/backup" ]]; then mkdir -p mongodb/backup; fi

cat << EOF > mongodb/data/mongod.conf
storage:
  directoryPerDB: true
  journal:
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
security:
  authorization: enabled
  keyFile: /data/db/keyFile
net:
  port: 27017
  bindIp: 127.0.0.1,${internal_ip}
EOF

openssl rand -base64 756 > mongodb/data/keyFile

sudo chown $(whoami):$(whoami) mongodb/init.sh
sudo chown -R 1001:$(whoami) mongodb/data
sudo chown -R 1001:$(whoami) mongodb/backup
sudo chmod 400 mongodb/data/keyFile

echo "Creating MongoDB keyFile complete!"


echo "Initialising databases..."

cat << EOF > mongodb/init/create_temp_admin.js
db.createUser({
    user: 'admin',
    pwd: '${mongo_user_password}',
    roles: [{role: 'root', db: 'admin'}]
});
EOF

cat << EOF > mongodb/init/create_root.js
db.createUser({
    user: "root",
    pwd: "${mongo_root_password}",
    roles: [{role: "remote_role", db: "admin"}],
});
EOF

cat << EOF > mongodb/init/setup_replicaset.js
rs.initiate({
    _id: "mongoreplicaset1",
    version: 1,
    members: [{ _id: 0, host : "mongo-mongo1.${domain_name}:27017"}]
});
EOF

if [[ ! -d "mariadb/data" ]]; then mkdir -p mariadb/data; fi
if [[ ! -d "mariadb/backup" ]]; then mkdir -p mariadb/backup; fi
if [[ ! -d "mariadb/migration" ]]; then mkdir -p mariadb/migration; fi

if [[ "$(docker ps -aqf name=mariadb)" ]]; then
    docker rm -f mariadb
    docker-compose -f docker/docker-compose.yml up -d mariadb
else
    docker-compose -f docker/docker-compose.yml up -d mariadb
fi

sleep 5

if [[ "$(docker ps -aqf name=mongodb)" ]]; then
    docker rm -f mongodb
    docker-compose -f docker/docker-compose.yml up -d mongodb
else
    docker-compose -f docker/docker-compose.yml up -d mongodb
fi

sleep 15
cd mongodb
chmod +x init.sh
bash init.sh
cd ..

echo "Initialising databases complete!"


echo "Init RabbitMQ..."

if [[ "$(docker ps -aqf name=rabbitmq)" ]]; then
    docker rm -f rabbitmq
    docker-compose -f docker/docker-compose.yml up -d rabbitmq
else
    docker-compose -f docker/docker-compose.yml up -d rabbitmq
fi

sleep 15
cd rabbitmq
chmod +x init.sh
bash init.sh
cd ..

echo "Init RabbitMQ complete!"


echo "Creating simple reverse proxy site..."

if [[ ! -d "nginx/sites" ]]; then mkdir -p nginx/sites; fi

cat << EOF > nginx/sites/${domain_name}.conf
upstream 11b9509-6783478-bb37b70-f2617d0 {
        server ${internal_ip}:8989;
}
server {
    listen              ${external_ip}:443 ssl ;
    server_name         ${domain_name};
    ssl_certificate     /etc/ssl/certs/${domain_name}.crt;
    ssl_certificate_key /etc/ssl/private/${domain_name}.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://11b9509-6783478-bb37b70-f2617d0;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo "Your app should be listening on port 8989"
echo "Creating simple reverse proxy site complete!"


echo "Creating self signed SSL certificate..."

if [[ ! -d "nginx/ssl" ]]; then mkdir -p nginx/ssl; fi
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout nginx/ssl/${domain_name}.key -out nginx/ssl/${domain_name}.crt

if [[ "$(docker ps -aqf name=reverse_proxy)" ]]; then
    docker rm -f reverse_proxy
    docker-compose -f docker/docker-compose.yml up -d reverse_proxy
else
    docker-compose -f docker/docker-compose.yml up -d reverse_proxy
fi

echo "Creating self signed SSL certificate complete!"


echo "Creating simple local DNS zone..."

current_date=$(date +%Y%m%d)
zone_name="db.$domain_name"

cat << EOF > bind9/${zone_name}
\$TTL 300
@       IN     SOA    ns1.${domain_name}. root.${domain_name}. (
                       ${current_date}00 ; serial
                       300            ; refresh, seconds
                       300            ; retry, seconds
                       300            ; expire, seconds
                       300 )          ; minimum TTL, seconds

@       IN     NS     ns1.${domain_name}.
ns1     IN      A     ${internal_ip}

${domain_name}      IN A ${internal_ip};
*.${domain_name}    IN A ${internal_ip};
EOF

cat << EOF > bind9/named.conf.access_network
zone "${domain_name}" IN {
    type master;
    file "${zone_name}";
    allow-update { none; };
};
EOF

if [[ "$(docker ps -aqf name=bind9)" ]]; then
    docker rm -f bind9
    docker-compose -f docker/docker-compose.yml up -d bind9
else
    docker-compose -f docker/docker-compose.yml up -d bind9
fi

sleep 5

echo "Creating simple local DNS zone complete!"
echo "****************************************"
echo "Default port of the nginx site is :8989"

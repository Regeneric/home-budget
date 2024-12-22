#!/bin/bash

read -p "Source code location: " source_code_location
read -p "Enter domain name: " domain_name
read -p "Enter internal IP: " internal_ip
read -p "Enter internal IP mask: " internal_mask
read -p "Enter external IP: " external_ip
read -p "Enter external IP mask: " external_mask
read -s -p "Enter MySQL root password: " mysql_root_password
echo ""
read -s -p "Enter MongoDB root password: " mongo_root_password
echo ""
read -s -p "Enter RabbitMQ password: " rabbitmq_password
echo ""
read -s -p "Enter database user password: " db_user_pass
echo ""
read -p "Enter database host: " db_host
read -p "Enter AMQP host: " amqp_host
read -s -p "Enter AMQP password: " amqp_pass
echo ""

current_path=$(pwd)
echo "Creating Docker .env file..."
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

MYSQL_ROOT_PASSWORD=${mysql_root_password}

MONGO_INITDB_DATABASE=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${mongo_root_password}
REPL_SET_NAME=mongoreplicaset1

RABBITMQ_USER=root
RABBITMQ_PASSWORD=${rabbitmq_password}

DB_USER=root
DB_PASS=${db_user_pass}
DB_HOST=${db_host}
DB_PORT=3306

AMQP_HOST=${amqp_host}
AMQP_USER=root
AMQP_PASS=${amqp_pass}
EOF
echo "Creating Docker .env file complete!"

echo "Creating MongoDB keyFile..."
chmod +x mongodb/init.sh
openssl rand -base64 756 > mongodb/data/keyFile
mkdir mongodb/backup
sudo chown $(whoami):$(whoami) mongodb/init.sh
sudo chown -R 1001:1000 mongodb/data
sudo chown -R 1001:1000 mongodb/backup
sudo chmod 400 mongodb/data/keyFile
echo "Creating MongoDB keyFile complete!"

mkdir -p mariadb/data
mkdir mariadb/backup
mkdir mariadb/schemas
docker rm -f mariadb
docker-compose -f docker/docker-compose.yml up -d mariadb

docker rm -f mongodb
docker-compose -f docker/docker-compose.yml up -d mongodb
sleep 5

cd mongodb
bash init.sh
cd ..

echo "Init RabbitMQ..."
docker rm -f rabbitmq
docker-compose -f docker/docker-compose.yml up -d rabbitmq
sleep 5
cd rabbitmq
chmod +x init.sh
bash init.sh
cd ..
echo "Init RabbitMQ complete!"

echo "Creating simple reverse proxy site..."

mkdir nginx/sites
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

echo "Creating simple reverse proxy site complete!"
echo "Your app should be listening on port 8989"

echo "Creating self signed SSL certificate..."
mkdir nginx/ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout nginx/ssl/${domain_name}.key -out nginx/ssl/${domain_name}.crt
echo "Creating self signed SSL certificate complete!"

docker rm -f reverse_proxy
docker-compose -f docker/docker-compose.yml up -d reverse_proxy

current_date=$(date +%Y%m%d)
echo "Creating simple local DNS zone..."
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
echo "Creating simple local DNS zone complete!"

docker rm -f bind9
docker-compose -f docker/docker-compose.yml up -d bind9
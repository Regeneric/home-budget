#!/bin/bash

read -p "Source code location: "                    source_code_location
read -p "Enter domain name: "                       domain_name
read -p "Enter internal IP (eg. 192.168.1.5): "     internal_ip
read -p "Enter internal IP mask (eg. 24): "         internal_mask
read -p "Enter external IP (eg. 192.168.1.5): "     external_ip
read -p "Enter external IP mask (eg. 24): "         external_mask
read -p "Enter database host (eg. 192.168.1.5): "   db_host
read -p "Enter AMQP host (eg. 192.168.1.5): "       amqp_host

read -s -p "Enter MySQL root password: "            mysql_root_password
echo ""
read -s -p "Enter MongoDB root password: "          mongo_root_password
echo ""
read -s -p "Enter RabbitMQ password: "              rabbitmq_password
echo ""
read -s -p "Enter database user password: "         db_user_pass
echo ""
read -s -p "Enter AMQP password: "                  amqp_pass
echo ""


echo "Creating Docker .env file..."

current_path=$(pwd)

if [[ -f "docker/.env" ]]; then
    # We want Y/N only
    answer=-1
    while [[ ! ${answer,,} =~ ^y(es)?$ && ! ${answer,,} =~ ^n(o)?$ ]]; do
      read -p "Do you want to delete current docker/.env file? (Y/N): " answer
    done
    if [[ ${answer,,} =~ ^y(es)?$ ]]; then rm -f docker/.env; fi
fi

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

MONGO_INITDB_USER=admin
MONGO_INITDB_DATABASE=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${mongo_root_password}
REPL_SET_NAME=mongoreplicaset1

RABBITMQ_USER=root
RABBITMQ_PASSWORD=${rabbitmq_password}

DB_USER=root
DB_PASS=${mysql_root_password}
DB_HOST=${db_host}
DB_PORT=3306

AMQP_HOST=${amqp_host}
AMQP_USER=root
AMQP_PASS=${amqp_pass}
EOF

echo "Creating Docker .env file complete!"


echo "Creating MongoDB keyFile..."

if [[ ! -d "mongodb/data" ]];   then mkdir -p mongodb/data; fi
if [[ ! -d "mognodb/backup" ]]; then mkdir -p mongodb/backup; fi

openssl rand -base64 756 > mongodb/data/keyFile

sudo chown $(whoami):$(whoami) mongodb/init.sh
sudo chown -R 1001:1000 mongodb/data
sudo chown -R 1001:1000 mongodb/backup
sudo chmod 400 mongodb/data/keyFile

echo "Creating MongoDB keyFile complete!"


echo "Initialising databases..."

cat << EOF > mongodb/init/create_temp_admin.js
db.createUser({ 
    user: 'admin',
    pwd: '${mongo_root_password}',
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


if [[ ! -d "mariadb/data" ]];  then mkdir -p mariadb/data; fi
if [[ ! -d "mariadb/backup"]]; then mkdir -p mariadb/backup; fi
if [[ ! -d "mariadb/migration" ]]; then mkdir -p mariadb/migration; fi

if [[ "$(docker ps -aqf name=mariadb)" ]]; then 
    docker rm -f mariadb
    docker-compose -f docker/docker-compose.yml up -d mariadb
    sleep 5
fi

if [[ "$(docker ps -aqf name=mongodb)" ]]; then 
    docker rm -f mongodb
    docker-compose -f docker/docker-compose.yml up -d mongodb
    sleep 5
fi

cd mongodb
chmod +x init.sh
bash init.sh
cd ..

echo "Initialising databases complete!"


echo "Init RabbitMQ..."

if [[ "$(docker ps -aqf name=rabbitmq)" ]]; then 
    docker rm -f rabbitmq
    docker-compose -f docker/docker-compose.yml up -d rabbitmq
    sleep 5
fi

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
    sleep 5
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
    sleep 5
fi

echo "Creating simple local DNS zone complete!"
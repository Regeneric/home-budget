# Prompt user for inputs
$source_code_location = Read-Host "Source code location"
$domain_name = Read-Host "Enter domain name"
$internal_ip = Read-Host "Enter internal IP"
$internal_mask = Read-Host "Enter internal IP mask"
$external_ip = Read-Host "Enter external IP"
$external_mask = Read-Host "Enter external IP mask"
$mysql_root_password = Read-Host "Enter MySQL root password" -AsSecureString
$mongo_root_password = Read-Host "Enter MongoDB root password" -AsSecureString
$rabbitmq_password = Read-Host "Enter RabbitMQ password" -AsSecureString
$db_user_pass = Read-Host "Enter database user password" -AsSecureString
$db_host = Read-Host "Enter database host"
$amqp_host = Read-Host "Enter AMQP host"
$amqp_pass = Read-Host "Enter AMQP password" -AsSecureString

$current_path = Get-Location
$dockerEnvPath = "$current_path/docker/.env"

# Create Docker .env file
@"
ENV_FILE=.env
CONFIG_FOLDER=$current_path
NGINX_CONF_LOCATION=$($current_path)/nginx
BIND_CONF_LOCATION=$($current_path)/bind9
SOURCE_CODE_LOCATION=$source_code_location
DOMAIN_NAME=$domain_name
INTERNAL_IP=$internal_ip
INTERNAL_MASK=$internal_mask
EXTERNAL_IP=$external_ip
EXTERNAL_MASK=$external_mask
MYSQL_ROOT_PASSWORD=$($mysql_root_password.GetNetworkCredential().Password)
MONGO_INITDB_DATABASE=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=$($mongo_root_password.GetNetworkCredential().Password)
REPL_SET_NAME=mongoreplicaset1
RABBITMQ_USER=root
RABBITMQ_PASSWORD=$($rabbitmq_password.GetNetworkCredential().Password)
DB_USER=root
DB_PASS=$($db_user_pass.GetNetworkCredential().Password)
DB_HOST=$db_host
DB_PORT=3306
AMQP_HOST=$amqp_host
AMQP_USER=root
AMQP_PASS=$($amqp_pass.GetNetworkCredential().Password)
"@ | Set-Content $dockerEnvPath

# Creating MongoDB keyFile
$mongodbInitPath = "$current_path/mongodb/init.sh"
$mongodbKeyPath = "$current_path/mongodb/data/keyFile"
$mongodbBackupPath = "$current_path/mongodb/backup"

if (-not (Test-Path $mongodbBackupPath)) {
    New-Item -ItemType Directory -Path $mongodbBackupPath
}
Set-Content -Path $mongodbKeyPath -Value (openssl rand -base64 756)
Set-Acl -Path $mongodbInitPath -AclObject (Get-Acl -Path $mongodbInitPath)

# Docker compose commands
docker rm -f mariadb
docker-compose -f "$current_path/docker/docker-compose.yml" up -d mariadb

docker rm -f mongodb
docker-compose -f "$current_path/docker/docker-compose.yml" up -d mongodb
Start-Sleep -Seconds 5

Push-Location mongodb
& "./init.sh"
Pop-Location

# Init RabbitMQ
docker rm -f rabbitmq
docker-compose -f "$current_path/docker/docker-compose.yml" up -d rabbitmq
Start-Sleep -Seconds 5

Push-Location rabbitmq
& "./init.sh"
Pop-Location

# Creating simple reverse proxy site
$nginxSitesPath = "$current_path/nginx/sites"
if (-not (Test-Path $nginxSitesPath)) {
    New-Item -ItemType Directory -Path $nginxSitesPath
}

$nginxConfigPath = "$nginxSitesPath/${domain_name}.conf"
@"
upstream 11b9509-6783478-bb37b70-f2617d0 {
    server $internal_ip:8989;
}
server {
    listen $external_ip:443 ssl;
    server_name $domain_name;
    ssl_certificate /etc/ssl/certs/${domain_name}.crt;
    ssl_certificate_key /etc/ssl/private/${domain_name}.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    location / {
        proxy_pass http://11b9509-6783478-bb37b70-f2617d0;
        proxy_set_header Host `$host;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
    }
}
"@ | Set-Content $nginxConfigPath

# Create self-signed SSL certificate
$nginxSslPath = "$current_path/nginx/ssl"
if (-not (Test-Path $nginxSslPath)) {
    New-Item -ItemType Directory -Path $nginxSslPath
}
$sslCertPath = "$nginxSslPath/${domain_name}.crt"
$sslKeyPath = "$nginxSslPath/${domain_name}.key"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $sslKeyPath -out $sslCertPath

docker rm -f reverse_proxy
docker-compose -f "$current_path/docker/docker-compose.yml" up -d reverse_proxy

# Creating simple local DNS zone
$zone_name = "db.$domain_name"
$dnsZonePath = "$current_path/bind9/$zone_name"
$current_date = (Get-Date -Format "yyyyMMdd")
@"
$TTL 300
@ IN SOA ns1.$domain_name. root.$domain_name. (
    ${current_date}00 ; serial
    300              ; refresh, seconds
    300              ; retry, seconds
    300              ; expire, seconds
    300              ; minimum TTL, seconds
)
@ IN NS ns1.$domain_name.
ns1 IN A $internal_ip
$domain_name IN A $internal_ip
*.$domain_name IN A $internal_ip
"@ | Set-Content $dnsZonePath

$namedConfPath = "$current_path/bind9/named.conf.access_network"
@"
zone "$domain_name" IN {
    type master;
    file "$zone_name";
    allow-update { none; };
};
"@ | Set-Content $namedConfPath

docker rm -f bind9
docker-compose -f "$current_path/docker/docker-compose.yml" up -d bind9
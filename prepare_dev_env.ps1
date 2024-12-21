# Prompt user for inputs
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
$envFilePath = "$current_path/docker/.env"

# Create Docker .env file
$envContent = @"
ENV_FILE=.env

CONFIG_FOLDER=$current_path
NGINX_CONF_LOCATION=$current_path/nginx
BIND_CONF_LOCATION=$current_path/bind9
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
"@

Set-Content -Path $envFilePath -Value $envContent

# Create MongoDB keyFile
$mongodbKeyPath = "$current_path/mongodb/data/keyFile"
"$(openssl rand -base64 756)" | Set-Content -Path $mongodbKeyPath
# Assuming current user ownership is acceptable; adjust as necessary for your environment

# Execute Docker Compose for MariaDB and MongoDB
Start-Process "docker-compose" -ArgumentList "-f $current_path/docker/docker-compose.yml up -d mariadb" -NoNewWindow -Wait
Start-Process "docker-compose" -ArgumentList "-f $current_path/docker/docker-compose.yml up -d mongodb" -NoNewWindow -Wait

& "$current_path/mongodb/init.sh"

# Init RabbitMQ
Start-Process "docker-compose" -ArgumentList "-f $current_path/docker/docker-compose.yml up -d rabbitmq" -NoNewWindow -Wait
& "$current_path/rabbitmq/init.sh"

# Create Nginx reverse proxy configuration
New-Item -Path 'nginx/sites' -ItemType Directory
$nginxConfigPath = "$current_path/nginx/sites/${domain_name}.conf"
$nginxConfig = @"
upstream 11b9509-6783478-bb37b70-f2617d0 {
        server $internal_ip:8989;
}
server {
    listen              $external_ip:443 ssl;
    server_name         $domain_name;
    ssl_certificate     $current_path/ssl/certs/$domain_name.crt;
    ssl_certificate_key $current_path/ssl/private/$domain_name.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://11b9509-6783478-bb37b70-f2617d0;
        proxy_set_header Host `\$host`;
        proxy_set_header X-Forwarded-For `\$proxy_add_x_forwarded_for`;
    }
}
"@
Set-Content -Path $nginxConfigPath -Value $nginxConfig

# Create self-signed SSL certificate
New-Item -Path 'nginx/ssl' -ItemType Directory
$sslCmd = "openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $current_path/ssl/private/$domain_name.key -out $current_path/ssl/certs/$domain_name.crt"
Invoke-Expression $sslCmd

Start-Process "docker-compose" -ArgumentList "-f $current_path/docker/docker-compose.yml up -d reverse_proxy" -NoNewWindow -Wait

# Create simple local DNS zone
$dnsZonePath = "$current_path/bind9/db.$domain_name"
$current_date = Get-Date -Format "yyyyMMdd"
$dnsZoneContent = @"
`$TTL 300
@       IN     SOA    ns1.$domain_name. root.$domain_name. (
                       ${current_date}00 ; serial
                       300            ; refresh, seconds
                       300            ; retry, seconds
                       300            ; expire, seconds
                       300 )          ; minimum TTL, seconds

@       IN     NS     ns1.$domain_name.
ns1     IN      A     $internal_ip

$domain_name                                                   IN A $internal_ip;
*.$domain_name                                                 IN A $internal_ip;
"@
Set-Content -Path $dnsZonePath -Value $dnsZoneContent

Start-Process "docker-compose" -ArgumentList "-f $current_path/docker/docker-compose.yml up -d bind9" -NoNewWindow -Wait

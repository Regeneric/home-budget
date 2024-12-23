#!/bin/bash

current_path=$(pwd)
root_path=${current_path%/scripts}

if ! direnv --version; then echo "direnv must be installed first!"; fi

if [[ -f "${root_path}/.envrc" ]]; then
    # We want Y/N only
    answer=-1
    while [[ ! ${answer,,} =~ ^y(es)?$ && ! ${answer,,} =~ ^n(o)?$ ]]; do
      read -p "Do you want to delete current .envrc file? (Y/N): " answer
    done
    if [[ ${answer,,} =~ ^y(es)?$ ]]; then rm -f "${root_path}/.envrc"; fi
fi


read -p "APP_HOST (string): " app_host
read -p "APP_PORT (int): "    app_port
read -p "SQL_USER (string): " sql_user

read -s -p "SQL_PASS (string): " sql_pass
echo ""

read -p "SQL_HOST (string): "           sql_host
read -p "SQL_PORT (int): "              sql_port
read -p "SQL_DB_NAME (string): "        sql_db_name
read -p "SQL_MAX_OPEN_CONNS (int): "    sql_max_open_conns
read -p "SQL_MAX_IDLE_CONNS (int): "    sql_max_idle_conns
read -p "SQL_MAX_IDLE_TIME (string): "  sql_max_idle_time


cat << EOF > "${root_path}/.envrc"
APP_HOST="${app_host}"
APP_PORT="${app_port}"

SQL_USER="${sql_user}"
SQL_PASS="${sql_pass}"
SQL_HOST="${sql_host}"
SQL_PORT="${sql_port}"
SQL_DB_NAME="${sql_db_name}"

export APP_ADDRESS="\${APP_HOST}:\${APP_PORT}"
export SQL_ADDRESS="mysql://\${SQL_USER}:\${SQL_PASS}@tcp(\${SQL_HOST}:\${SQL_PORT})/\${SQL_DB_NAME}"

export SQL_MAX_OPEN_CONNS="${sql_max_open_conns}"
export SQL_MAX_IDLE_CONNS="${sql_max_idle_conns}"
export SQL_MAX_IDLE_TIME="${sql_max_idle_time}"
EOF


direnv allow "${root_path}/.envrc"
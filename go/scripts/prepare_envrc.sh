#!/bin/bash

current_path=$(pwd)
root_path=${current_path%/scripts}

if ! direnv --version; then echo "direnv must be installed first!"; exit 1
else
    if [[ $DIRENV_SET -ne 1 ]]; then
        case $SHELL in
            '/bin/zsh')
                echo 'eval "$(direnv hook zsh)"' >> $HOME/.zshrc
                echo 'export DIRENV_SET=1' >> $HOME/.zshrc
                zsh -c "source $HOME/.zshrc"
            ;;
            '/bin/bash')
                echo 'eval "$(direnv hook bash)"' >> $HOME/.bashrc
                echo 'export DIRENV_SET=1' >> $HOME/.bashrc
                bash -c "source $HOME/.bashrc"
            ;;
            '/bin/tcsh')
                echo 'eval `direnv hook tcsh`' >> $HOME/.cshrc
                echo 'export DIRENV_SET=1' >> $HOME/.cshrc
                tcsh -c "source $HOME/.cshrc"
            ;;
            '/bin/fish')
                echo 'direnv hook fish | source' >> $HOME/.config/fish.config
                echo 'set -x DIRENV_SET 1' >> $HOME/.config/fish.config
                fish -c "source $HOME/.config/fish.config"
            ;;
        esac
    fi
fi

if [[ -f "${root_path}/.envrc" ]]; then
    # We want Y/N only
    answer=-1
    while [[ ! ${answer,,} =~ ^y(es)?$ && ! ${answer,,} =~ ^n(o)?$ ]]; do
      read -p "Do you want to delete current .envrc file? (Y/N): " answer
    done
    if [[ ${answer,,} =~ ^y(es)?$ ]]; then rm -f "${root_path}/.envrc"
    else exit 0; fi
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
export APP_HOST="${app_host}"
export APP_PORT="${app_port}"

export SQL_USER="${sql_user}"
export SQL_PASS="${sql_pass}"
export SQL_HOST="${sql_host}"
export SQL_PORT="${sql_port}"
export SQL_DB_NAME="${sql_db_name}"

export APP_ADDRESS="\${APP_HOST}:\${APP_PORT}"
export SQL_ADDRESS="\${SQL_USER}:\${SQL_PASS}@tcp(\${SQL_HOST}:\${SQL_PORT})/\${SQL_DB_NAME}"

export SQL_MAX_OPEN_CONNS="${sql_max_open_conns}"
export SQL_MAX_IDLE_CONNS="${sql_max_idle_conns}"
export SQL_MAX_IDLE_TIME="${sql_max_idle_time}s"
EOF


direnv allow "${root_path}/.envrc"

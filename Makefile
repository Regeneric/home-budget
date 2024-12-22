include docker/.env
export


.PHONY: dev_env mariadb stop_mariadb restart_mariadb delete_mariadb recreate_mariadb \
        create_sql_db drop_sql_db migrate_sql_up migrate_sql_down all_sql_setup \
        mongodb stop_mongodb restart_mongodb delete_mongodb init_mongodb \
        recreate_mongodb create_nosql_db drop_nosql_db


dev_env:
	bash prepare_dev_env.sh


mariadb:
	docker-compose -f docker/docker-compose.yml up -d mariadb

stop_mariadb:
	docker stop mariadb

restart_mariadb:
	docker restart mariadb

delete_mariadb:
	docker rm -f mariadb
	
recreate_mariadb:
	docker rm -f mariadb && sleep 5 && mariadb

create_sql_db:
	docker exec mariadb mariadb -u${DB_USER} -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE budget_app;"

drop_sql_db:
	docker exec mariadb mariadb -u${DB_USER} -p${MYSQL_ROOT_PASSWORD} -e "DROP DATABASE budget_app;"

migrate_sql_up:
	migrate -path mariadb/migration -database "mysql://${DB_USER}:${MYSQL_ROOT_PASSWORD}@tcp(${DB_HOST}:${DB_PORT})/budget_app" -verbose up

migrate_sql_down:
	migrate -path mariadb/migration -database "mysql://${DB_USER}:${MYSQL_ROOT_PASSWORD}@tcp(${DB_HOST}:${DB_PORT})/budget_app" -verbose down

all_sql_setup:
	mariadb create_sql_db migrate_sql_up


mongodb:
	docker-compose -f docker/docker-compose.yml up -d mongodb && sleep 5 && cd mongodb && bash init.sh && cd ..

stop_mongodb:
	docker stop mongodb

restart_mongodb:
	docker restart mongodb

delete_mongodb:
	docker rm -f mongodb

init_mongodb:
	cd mongo && bash init.sh && cd ..
	
recreate_mongodb:
	docker rm -f mongodb && sleep 5 && mongodb

create_nosql_db:
	docker exec mongodb mongosh -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase ${MONGO_INITDB_DATABASE} --eval "use budget_app;"

drop_nosql_db:
	docker exec mongodb mongosh -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --authenticationDatabase ${MONGO_INITDB_DATABASE} --eval "use budget_app; db.dropDatabase();"

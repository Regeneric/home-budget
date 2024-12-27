include docker/.env
export


.PHONY: dev_env \
		mariadb stop_mariadb restart_mariadb delete_mariadb recreate_mariadb init_mariadb \
        mongodb stop_mongodb restart_mongodb delete_mongodb recreate_mongodb init_mongodb \
		rabbit  stop_rabbit  restart_rabbit  delete_rabbit  recreate_rabbit  init_rabbit  \
        proxy	stop_proxy	 restart_proxy	 delete_proxy	recreate_proxy	 init_proxy   \
		bind	stop_bind	 restart_bind	 delete_bind	recreate_bind	 init_bind	  \


dev_env:
	. prepare_dev_env.sh


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

init_mariadb:
	cd mariadb && bash init.sh && cd ..


mongodb:
	docker-compose -f docker/docker-compose.yml up -d mongodb && sleep 5 && cd mongodb && bash init.sh && cd ..

stop_mongodb:
	docker stop mongodb

restart_mongodb:
	docker restart mongodb

delete_mongodb:
	docker rm -f mongodb

recreate_mongodb:
	docker rm -f mongodb && sleep 5 && mongodb

init_mongodb:
	cd mongo && bash init.sh && cd ..
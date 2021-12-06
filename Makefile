up: docker-up
down: docker-down
restart: docker-down docker-up
full: docker-down-clear docker-pull docker-build docker-up app-init
init: app-network docker-down-clear docker-build docker-up app-init
init-auto-test: docker-down-clear docker-build docker-up app-init-auto-test

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull

docker-build:
	docker-compose build

app-init: app-composer-install app-wait-db app-create-test-db app-migrations app-migrations-test app-oauth-keys app-fixtures

app-init-auto-test: app-composer-install app-wait-db app-create-test-db app-migrations app-migrations-test app-oauth-keys app-fixtures-autotest

app-composer-install:
	docker-compose run --rm micro-php-cli composer install

app-network:
	docker network create micro-network || true

app-wait-db:
	until docker-compose exec -T micro-mysql /usr/bin/mysql -uroot -proot -e "SHOW DATABASES;" ; do sleep 1 ; done

app-create-test-db:
	docker-compose exec -T micro-mysql /usr/bin/mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS db_test;GRANT ALL ON db_test.* TO user@'%';FLUSH PRIVILEGES;"

app-migrations:
	docker-compose run --rm micro-php-cli php bin/console do:database:drop -nq --force --if-exists
	docker-compose run --rm micro-php-cli php bin/console do:database:create -nq
	docker-compose run --rm micro-php-cli php bin/console doctrine:migrations:migrate --no-interaction || true

app-migrations-test:
	docker-compose run --rm micro-php-cli php bin/console do:database:drop -nq --force --if-exists --env=test
	docker-compose run --rm micro-php-cli php bin/console do:database:create -nq --env=test
	docker-compose run --rm micro-php-cli php bin/console do:mi:mi -n --env=test || true

app-fixtures:
	docker-compose run --rm micro-php-cli php bin/console do:fixtures:load -n

app-fixtures-autotest:
	docker-compose run --rm micro-php-cli php bin/console do:fixtures:load -n --group=auto-test

app-filter-config:
	docker-compose run --rm micro-php-cli php bin/console filter:config:load

psalm:
	docker-compose run --rm micro-php-cli composer psalm

app-cs:
	docker-compose run --rm micro-php-cli composer cs-check

deep:
	docker-compose run --rm micro-php-cli php bin/deptrac.phar analyze bin/depfile.yml

app-test:
	docker-compose run --rm micro-php-cli vendor/bin/codecept run

app-oauth-keys:
	docker-compose run --rm micro-php-cli mkdir -p /var/www/app/var/oauth
	docker-compose run --rm micro-php-cli openssl genrsa -out /var/www/app/var/oauth/private.key 2048
	docker-compose run --rm micro-php-cli openssl rsa -in /var/www/app/var/oauth/private.key -pubout -out /var/www/app/var/oauth/public.key
	docker-compose run --rm micro-php-cli chmod 644 /var/www/app/var/oauth/private.key /var/www/app/var/oauth/public.key

schema-validate:
	docker-compose run --rm micro-php-cli php bin/console do:schema:validate
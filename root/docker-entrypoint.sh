#!/usr/bin/env sh

set -e

if [ -z "$DB_HOST" ]; then
	echo "*** DATABASE HOST ADDRESS NOT SPECIFIED, ABORTING... ***"
	exit 1
fi

wait4x mysql "$DB_USERNAME:$DB_PASSWORD@tcp($DB_HOST)/$DB_DATABASE"

if [ ! "$(ls -A /var/www/snipeit)" ]; then
	git clone --single-branch https://github.com/grokability/snipe-it.git /var/www/snipeit
	composer install -d /var/www/snipeit --no-dev

	mkdir /data/storage /data/public
	ln -sf /var/www/snipeit/storage /data/storage
	ln -sf /var/www/snipeit/public /data/public

	cd /var/www/snipeit

	php /var/www/bookstack/artisan migrate
fi

exec php-fpm84

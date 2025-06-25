#!/usr/bin/env sh

set -e

if [ -z "$DB_HOST" ]; then
	echo "*** DATABASE HOST ADDRESS NOT SPECIFIED, ABORTING... ***"
	exit 1
fi

wait4x mysql "$DB_USERNAME:$DB_PASSWORD@tcp($DB_HOST)/$DB_DATABASE"

if [ ! "$(ls -A /var/www/snipeit)" ]; then
	curl \
		--location \
		--remote-name \
		--output-dir /var/www/snipeit \
		https://api.github.com/repos/grokability/snipe-it/tarball/$SNIPEIT_VERSION

	tar x \
		-f /var/www/snipeit/$SNIPEIT_VERSION \
		-C /var/www/snipeit \
		--strip-components 1

	rm /var/www/snipeit/$SNIPEIT_VERSION
	composer install -d /var/www/snipeit --no-dev

	mkdir /data/storage /data/public
	ln -sf /var/www/snipeit/storage /data/storage
	ln -sf /var/www/snipeit/public /data/public

	php /var/www/snipeit/artisan migrate
fi

exec php-fpm84

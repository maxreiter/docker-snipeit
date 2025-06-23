FROM alpine:3.22

ARG BUILD_DATE

LABEL org.opencontainers.image.created = "$BUILD_DATE" \
	org.opencontainers.image.authors = "Max Reiter <mreiter@rtc.edu>" \
	org.opencontainers.image.url = "https://github.com/maxreiter/docker-snipeit" \
	org.opencontainers.image.documentation = "https://github.com/maxreiter/docker-snipeit" \
	org.opencontainers.image.source = "https://github.com/grokability/snipe-it" \
	org.opencontainers.image.version = "v8.1.16" \
	org.opencontainers.vendor = "Max Reiter" \
	org.opencontainers.image.license = "MIT" \
	org.opencontainers.image.title = "Snipe-IT" \
	org.opencontainers.image.description = "A free open source IT asset/license management system"

RUN <<EOF
	set -eux

	# Install tools we use
	apk add --no-cache git wait4x

	# Install PHP dependencies
	apk add --no-cache curl openssl gd openldap

	# Install PHP and extensions
	apk add --no-cache \
		php84 php84-fpm \
		php84-openssl php84-mbstring php84-curl php84-ldap php84-zip php84-bcmath \
		php84-exif php84-phar php84-iconv php84-simplexml php84-dom php84-fileinfo \
		php84-session php84-sodium php84-tokenizer php84-gd \
		php84-pdo php84-pdo_mysql php84-mysqlnd

	ln -sf /usr/bin/php84 /usr/bin/php

	SIG="$(curl -fsSL https://composer.github.io/installer.sig)"
	curl -fsSL https://getcomposer.org/installer -o composer-setup.php
	CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

	if [ "$CHECKSUM" != "$SIG" ]; then
		echo "*** COMPOSER CHECKSUM MISMATCH, ABORTING... ***"
		exit 1
	fi

	php composer-setup.php --quiet
	rm composer-setup.php
	mv composer.phar /usr/local/bin/composer

	adduser -u 82 -D -S -G www-data www-data

	mkdir /data
	chown www-data:www-data /data
	chmod 1777 /data

	mkdir -p /var/www/snipeit
	chown www-data:www-data /var/www/snipeit
EOF

USER www-data
WORKDIR /data
VOLUME /data

COPY root/etc/php84/php-fpm.conf /etc/php84/php-fpm.conf
COPY root/etc/php84/php-fpm.d/www.conf /etc/php84/php-fpm.d/www.conf
COPY root/docker-entrypoint.sh /usr/bin/docker-entrypoint

EXPOSE 9000

ENTRYPOINT [ "/usr/bin/docker-entrypoint" ]

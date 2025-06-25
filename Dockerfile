FROM alpine:3.22

# A date-time string as defined by RFC3339
ARG BUILD_DATE

# Version of Snipe-IT to install
ENV SNIPEIT_VERSION=v8.1.16

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.authors="Max Reiter <mreiter@rtc.edu>" \
	org.opencontainers.image.url="https://github.com/maxreiter/docker-snipeit" \
	org.opencontainers.image.documentation="https://github.com/maxreiter/docker-snipeit" \
	org.opencontainers.image.source="https://github.com/maxreiter/docker-snipeit" \
	org.opencontainers.image.version="${SNIPEIT_VERSION}" \
	org.opencontainers.image.vendor="Max Reiter" \
	org.opencontainers.image.license="MIT" \
	org.opencontainers.image.title="Snipe-IT" \
	org.opencontainers.image.description="A free open source IT asset/license management system"

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

	# Symlink to /usr/bin/php for ease of access
	ln -sf /usr/bin/php84 /usr/bin/php

	# Download, verify and install Composer by hand
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

	# Create the www-data user; defaults to 82 on Alpine
	adduser -u 82 -D -S -G www-data www-data

	# Create the data volume mount point and apply permissions
	mkdir /data
	chown www-data:www-data /data
	chmod 1777 /data

	# Create the entrypoint directory and apply permissions
	mkdir -p /var/www/snipeit
	chown www-data:www-data /var/www/snipeit
EOF

USER www-data
WORKDIR /data
VOLUME /data

# Copy PHP configurations and entrypoint script
COPY root/etc/php84/php-fpm.conf /etc/php84/php-fpm.conf
COPY root/etc/php84/php-fpm.d/www.conf /etc/php84/php-fpm.d/www.conf
COPY root/docker-entrypoint.sh /usr/bin/docker-entrypoint

# Expose the port FPM runs on
EXPOSE 9000

ENTRYPOINT [ "/usr/bin/docker-entrypoint" ]

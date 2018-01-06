FROM php:7.1-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		libjpeg-dev \
		libpng12-dev \
		zlib1g-dev \
		rsync \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip
# TODO consider removing the *-dev deps and only keeping the necessary lib* packages

RUN a2enmod rewrite expires

ENV PHPMYADMIN_VERSION 4.7.7
ENV PHPMYADMIN_SHA256 cd84108920159d40911c73d114d5fad819827fd5f63802436843cfdc283210ec

RUN set -ex; \
	curl -o phpmyadmin.tar.gz -fSL "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"; \
	echo "$PHPMYADMIN_SHA256 *phpmyadmin.tar.gz" | sha256sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf phpmyadmin.tar.gz -C /var/www/html/; \
	rm phpmyadmin.tar.gz; \
	chown -R www-data:www-data /var/www/html

RUN sed -i "/Listen 80/c Listen 8080"                     /etc/apache2/ports.conf && \
    sed -i "/<VirtualHost \*:80>/c <VirtualHost \*:8080>" /etc/apache2/sites-enabled/000-default.conf

EXPOSE 8080

RUN chown -R 1001:0 /var/www/html /var/lock/ /var/run/ .htaccess && \
    chmod -R g+w /var/www/html /var/lock/ /var/run/ .htaccess 

USER 1001

CMD ["apache2-foreground"]
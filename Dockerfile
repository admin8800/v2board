FROM php:8.1-fpm-alpine AS builder

ARG V2BOARD_REPO=https://github.com/wyx2685/v2board.git
ARG V2BOARD_BRANCH=master

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        git \
        unzip \
        curl \
        wget \
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        oniguruma-dev \
        libxml2-dev \
        curl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        zip \
        pcntl \
        bcmath \
        gd \
        curl \
        fileinfo \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /build

RUN git clone --depth=1 -b ${V2BOARD_BRANCH} ${V2BOARD_REPO} v2board

WORKDIR /build/v2board

RUN sed -i 's/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/g' .env.example \
    && sed -i '/^extension=igbinary\.so$/d;/^extension=redis\.so$/d' cli-php.ini \
    && composer install --no-dev --optimize-autoloader \
    && composer require joanhey/adapterman --no-interaction \
    && apk del .build-deps


FROM php:8.1-fpm-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache \
        nginx \
        supervisor \
        curl \
        tzdata \
        libzip \
        libpng \
        libjpeg-turbo \
        freetype \
        oniguruma \
        libxml2 \
    && rm -f /etc/nginx/http.d/default.conf

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /build/v2board /www

WORKDIR /www

RUN mkdir -p \
    /run/nginx \
    /var/lib/nginx/tmp \
    /var/log/nginx \
    /www/storage/app \
    /www/storage/logs \
    /www/storage/framework/cache \
    /www/storage/framework/sessions \
    /www/storage/framework/views \
    /www/bootstrap/cache \
    && chown -R nginx:nginx /var/lib/nginx \
    && chown -R www-data:www-data /www

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80 6600

ENTRYPOINT ["/entrypoint.sh"]

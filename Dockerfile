FROM php:8.1-fpm-bookworm AS builder

ARG V2BOARD_REPO=https://github.com/wyx2685/v2board.git
ARG V2BOARD_BRANCH=master

RUN apt-get update && apt-get install -y \
    git unzip curl wget \
    libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libxml2-dev libcurl4-openssl-dev \
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
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /build

RUN git clone --depth=1 -b ${V2BOARD_BRANCH} ${V2BOARD_REPO} v2board

WORKDIR /build/v2board

RUN sed -i 's/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/g' .env.example \
    && composer install --no-dev --optimize-autoloader \
    && composer require joanhey/adapterman --no-interaction


FROM php:8.1-fpm-bookworm

RUN apt-get update && apt-get install -y \
    nginx supervisor curl \
    libzip4 libpng16-16 libjpeg62-turbo libfreetype6 libonig5 libxml2 \
    && rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /build/v2board /www

WORKDIR /www

RUN mkdir -p \
    /run/php \
    /var/log/supervisor \
    /www/storage/app \
    /www/storage/logs \
    /www/storage/framework/cache \
    /www/storage/framework/sessions \
    /www/storage/framework/views \
    /www/bootstrap/cache \
    && chown -R www-data:www-data /www

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80 6600

ENTRYPOINT ["/entrypoint.sh"]
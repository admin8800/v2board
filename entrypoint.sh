#!/bin/sh
set -e

mkdir -p \
  /www/storage/app \
  /www/storage/logs \
  /www/storage/framework/cache \
  /www/storage/framework/sessions \
  /www/storage/framework/views \
  /www/bootstrap/cache

chown -R www-data:www-data /www/storage /www/bootstrap/cache

exec /usr/bin/supervisord -n
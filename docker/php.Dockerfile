# syntax=docker/dockerfile:1.7-labs

ARG COMPOSER_VERSION=2
ARG WORKDIR=/usr/local/app

FROM composer:${COMPOSER_VERSION} AS composer

ARG WORKDIR

WORKDIR ${WORKDIR}

COPY composer.json composer.lock artisan ${WORKDIR}/

COPY --parents app bootstrap config database Heart lang public resources routes storage ${WORKDIR}/

RUN set -xeu;\
  composer install --no-dev --ignore-platform-reqs --no-interaction --optimize-autoloader --no-progress;

FROM serversideup/php:8.3-fpm-nginx-alpine AS production

ARG WORKDIR

USER root

ENV TZ=America/Sao_Paulo LANG=C.UTF-8

RUN set -xeu; \
  apk update;\
  apk add --no-cache tzdata nano ca-certificates;\
  ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime;\
  echo "${TZ}" > /etc/timezone;\
  update-ca-certificates;\
  rm -rf /var/cache/apk/*;

COPY --chown=www-data:www-data --from=composer ${WORKDIR} /var/www/html

USER www-data
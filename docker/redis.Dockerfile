# syntax=docker/dockerfile:1.15.0

FROM redis:7-alpine3.21@sha256:bb186d083732f669da90be8b0f975a37812b15e913465bb14d845db72a4e3e08

ENV TZ=America/Sao_Paulo

RUN set -xeu; \
    apk update;\
    apk add --no-cache tzdata nano ca-certificates;\
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime;\
    echo "${TZ}" > /etc/timezone;\
    update-ca-certificates;\
    rm -rf /var/cache/apk/*;
# syntax=docker/dockerfile:1.15.0

ARG USER=node
ARG WORK_DIR=/usr/local/app
ARG INIT_PATH=/usr/local/bin/dumb-init
ARG INIT_URL=https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64

FROM node:22.17.0-alpine3.21 AS builder

ARG USER
ARG WORK_DIR
ARG INIT_PATH
ARG INIT_URL

ENV TZ=America/Sao_Paulo NODE_ENV=development CI=true LANG=C.UTF-8 HUSKY=0

WORKDIR ${WORK_DIR}

RUN set -xeu;\
  apk update;\
  apk add --no-cache ca-certificates curl;\
  curl --fail --silent --show-error --location ${INIT_URL} --output ${INIT_PATH};\
  chmod +x ${INIT_PATH};

COPY --chown=${USER}:${USER}\
  package.json\
  tsconfig.json\
  tsup.production.config.ts\
  ${WORK_DIR}/

COPY --chown=${USER}:${USER} src ${WORK_DIR}/src

RUN set -xeu;\
  npm install --global husky;\
  npm install --package-lock-only;\
  npm ci -ddd --no-optional --no-audit --prefer-offline --progress=false --no-fund;\
  npm run prod:build;\
  npm prune --omit=dev;

FROM node:22.17.0-alpine3.21 AS main

ARG USER
ARG WORK_DIR
ARG INIT_PATH

ENV TZ=America/Sao_Paulo NODE_ENV=production LANG=C.UTF-8

COPY --from=builder --chown=${USER}:${USER} ${INIT_PATH} ${INIT_PATH}

RUN set -xeu; \
  apk update; \
  apk add --no-cache tzdata ca-certificates;

WORKDIR ${WORK_DIR}

RUN [ "npm", "install", "-g", "npm@latest" ]

COPY --from=builder --chown=${USER}:${USER} ${WORK_DIR}/node_modules ${WORK_DIR}/node_modules
COPY --from=builder --chown=${USER}:${USER} ${WORK_DIR}/dist ${WORK_DIR}/dist

USER ${USER}

ENTRYPOINT [ "/usr/local/bin/dumb-init", "--" ]

CMD [ "node", "--enable-source-maps", "dist/index.js" ]

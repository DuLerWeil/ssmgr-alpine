FROM node:12-alpine

LABEL maintainer="DuLerWeil <dulerweil@gmail.com>"
ARG TZ='Asia/Shanghai'

ENV TZ $TZ
ENV SLV 3.3.3
ENV SSMGR 0.34.11

RUN apk upgrade --update \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && apk add bash tzdata libsodium \
    # Build environment setup
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        c-ares-dev \
        libev-dev \
        libtool \
        libsodium-dev \
        linux-headers \
        mbedtls-dev \
        pcre-dev \
        file \
        curl \
        tar \
        git \
    # Install shadowsocks-manager with npm
    && npm i -g shadowsocks-manager@$SSMGR --unsafe-perm \
    # Get shadowsocks-libev source code
    && cd /tmp \
    && curl -sSLO https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SLV/shadowsocks-libev-$SLV.tar.gz \
    && tar -xzf shadowsocks-libev-$SLV.tar.gz \
    && cd shadowsocks-libev-* \
    # Build & Install shadowsocks-libev
    && ./configure --prefix=/usr --disable-documentation \
    && make install \
    && apk del .build-deps \
    # Runtime dependencies setup
    && apk add --no-cache --virtual .runtime-deps \
          rng-tools \
          $(scanelf --needed --nobanner /usr/bin/ss-* \
          | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
          | sort -u) \
    # Clean
    && rm -rf /tmp/shadowsocks-libev-* /var/cache/apk/*

CMD ["ssmgr"]

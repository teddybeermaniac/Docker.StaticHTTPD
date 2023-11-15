FROM alpine:3.18.4 AS base

RUN apk add --no-cache \
    build-base \
    busybox-static

FROM base AS busybox

ARG BUSYBOX_VERSION=1.36.1

WORKDIR /build
#RUN wget -O "/build/busybox-${BUSYBOX_VERSION}.tar.bz2" "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" && \
RUN wget -O "/build/busybox-${BUSYBOX_VERSION}.tar.bz2" "https://web.archive.org/web/9999if_/https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" && \
    tar -xf "/build/busybox-${BUSYBOX_VERSION}.tar.bz2"

WORKDIR "/build/busybox-${BUSYBOX_VERSION}"
COPY .config "/build/busybox-${BUSYBOX_VERSION}/.config"
RUN make -j "$(nproc --all)" && \
    make busybox.links && \
    sed -i 's:/sbin/:/bin/:' busybox.links && \
    make install && \
    strip /install/bin/busybox

FROM base AS curl

RUN apk add --no-cache \
    brotli-dev \
    brotli-static \
    mbedtls-dev \
    mbedtls-static \
    nghttp2-dev \
    nghttp2-static \
    nghttp3-dev \
    perl \
    zlib-dev \
    zlib-static \
    zstd-dev \
    zstd-static

ARG CURL_VERSION=8.4.0

WORKDIR /
RUN wget -O "/curl-${CURL_VERSION}.tar.gz" "https://github.com/curl/curl/releases/download/curl-${CURL_VERSION//./_}/curl-${CURL_VERSION}.tar.gz" && \
    tar -xf "/curl-${CURL_VERSION}.tar.gz"

WORKDIR /build
RUN LDFLAGS="-static" PKG_CONFIG="pkg-config --static" "/curl-${CURL_VERSION}/configure" \
    --disable-aws \
    --disable-curldebug \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-dict \
    --disable-file \
    --disable-gopher \
    --disable-imap \
    --disable-kerberos-auth \
    --disable-libcurl-option \
    --disable-mqtt \
    --disable-netrc \
    --disable-ntlm \
    --disable-pop3 \
    --disable-progress-meter \
    --disable-proxy \
    --disable-rtsp \
    --disable-shared \
    --disable-smb \
    --disable-smtp \
    --disable-telnet \
    --disable-tftp \
    --disable-unix-sockets \
    --enable-optimize \
    --enable-static \
    --with-brotli \
    --with-mbedtls \
    --with-nghttp2 \
    --with-nghttp3 \
    --with-zlib \
    --with-zstd \
    --prefix / && \
    make -j "$(nproc --all)" DESTDIR=/install LDFLAGS="-static -all-static" install && \
    strip /install/bin/curl

FROM base AS jq

RUN apk add --no-cache \
    oniguruma-dev

ARG JQ_VERSION=1.7

WORKDIR /
RUN wget -O "/jq-${JQ_VERSION}.tar.gz" "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz" && \
    tar -xf "/jq-${JQ_VERSION}.tar.gz"

WORKDIR /build
RUN "/jq-${JQ_VERSION}/configure" \
    --disable-dependency-tracking \
    --disable-docs \
    --disable-shared \
    --disable-valgrind \
    --enable-all-static \
    --enable-static \
    --prefix / && \
    make -j "$(nproc --all)" DESTDIR=/install install && \
    strip /install/bin/jq

FROM ghcr.io/teddybeermaniac/docker.scratchbase:v0.1.1

COPY --from=busybox /install/bin /bin
COPY --from=curl /install/bin/curl /bin/curl
COPY --from=jq /install/bin/jq /bin/jq

COPY --from=base /bin/busybox.static /app/busybox
RUN [ "/app/busybox", "mkdir", "/app/cgi-bin" ]
RUN [ "/app/busybox", "rm", "/app/busybox" ]

CMD [ "httpd", "-f", "-vv" ]

FROM alpine:3.18.4 AS base

RUN apk add --no-cache \
    build-base \
    busybox-static \
    tini-static

FROM base AS busybox

ARG BUSYBOX_VERSION=1.36.1

WORKDIR /build
RUN wget "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
RUN tar -xf "busybox-${BUSYBOX_VERSION}.tar.bz2"

WORKDIR "/build/busybox-${BUSYBOX_VERSION}"
COPY .config .
RUN make -j "$(nproc --all)"
RUN make install

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

WORKDIR /build
RUN wget "https://github.com/curl/curl/releases/download/curl-${CURL_VERSION//./_}/curl-${CURL_VERSION}.tar.gz"
RUN tar -xf "curl-${CURL_VERSION}.tar.gz"

WORKDIR "/build/curl-${CURL_VERSION}"
RUN LDFLAGS="-static" PKG_CONFIG="pkg-config --static" ./configure \
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
    --prefix /
RUN make -j "$(nproc --all)" DESTDIR=/install LDFLAGS="-static -all-static" install
RUN strip /install/bin/curl

FROM base AS jq

RUN apk add --no-cache \
    oniguruma-dev

ARG JQ_VERSION=1.7

WORKDIR /build
RUN wget "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz"
RUN tar -xf "jq-${JQ_VERSION}.tar.gz"

WORKDIR "/build/jq-${JQ_VERSION}"
RUN ./configure \
    --disable-dependency-tracking \
    --disable-docs \
    --disable-shared \
    --disable-valgrind \
    --enable-all-static \
    --enable-static \
    --prefix /
RUN make -j "$(nproc --all)" DESTDIR=/install install
RUN strip /install/bin/jq

FROM scratch

WORKDIR /
COPY --from=base /sbin/tini-static sbin/tini
COPY --from=base /etc/ssl/certs etc/ssl/certs
COPY --from=busybox /install/bin bin
COPY --from=busybox /install/sbin sbin
COPY --from=curl /install/bin bin
COPY --from=jq /install/bin bin

COPY --from=base /bin/busybox.static .
RUN /busybox.static touch etc/group etc/passwd
RUN /busybox.static addgroup -g 65534 nobody
RUN /busybox.static adduser -D -G nobody -H -g "" -h / -s /bin/false -u 65534 nobody
RUN /busybox.static mkdir -p app/cgi-bin
RUN /busybox.static chown -R nobody:nobody app
RUN /busybox.static rm busybox.static

WORKDIR /app
EXPOSE 80

CMD [ "tini", "-g", "-s", "-v", "--", "httpd", "-f", "-u", "nobody:nobody", "-vv" ]

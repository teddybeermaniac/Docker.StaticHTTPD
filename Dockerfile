FROM alpine:3.18.2 AS base

RUN apk add --no-cache \
    build-base \
    busybox-static \
    oniguruma-dev \
    tini-static

FROM base as busybox

ARG BUSYBOX_VERSION=1.36.1

WORKDIR /build
RUN wget "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
RUN tar -xf "busybox-${BUSYBOX_VERSION}.tar.bz2"

WORKDIR "/build/busybox-${BUSYBOX_VERSION}"
COPY .config .
RUN make install

FROM base as jq

ARG JQ_VERSION=1.6

WORKDIR /build
RUN wget "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz"
RUN tar -xf "jq-${JQ_VERSION}.tar.gz"

WORKDIR "/build/jq-${JQ_VERSION}"
RUN ./configure \
    --disable-docs \
    --disable-dependency-tracking \
    --disable-maintainer-mode \
    --disable-shared \
    --disable-valgrind \
    --enable-static \
    --enable-all-static \
    --prefix /
RUN make DESTDIR=/install install

FROM scratch

WORKDIR /
COPY --from=base /sbin/tini-static sbin/tini
COPY --from=busybox /install/bin bin
COPY --from=busybox /install/sbin sbin
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

CMD [ "tini", "-g", "-s", "-v", "-w", "--", "httpd", "-f", "-u", "nobody:nobody", "-vv" ]

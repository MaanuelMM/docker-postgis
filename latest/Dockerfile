FROM postgres:9.6-alpine
LABEL maintainer="tmanubrio@gmail.com"

ENV POSTGIS_VERSION 2.3.9
ENV POSTGIS_SHA256 220072ed521850185cd3edaff91de9e67fbe03f4b4aaa7b45567ef1d2c74bbbb
ENV JSON_OBJECT_PRIVATE_SHA256 62ea32767300d8e28f744312cb231ef70a42f288f61605e32e0922224dc2984e

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && wget -O json_object_private.h "https://raw.githubusercontent.com/json-c/json-c/master/json_object_private.h" \
    && echo "$JSON_OBJECT_PRIVATE_SHA256 *json_object_private.h" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
    \
    && apk add --no-cache --virtual .build-deps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \    
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        gdal-dev \
        geos-dev \
        proj4-dev \
        protobuf-c-dev \
    \
    && cp json_object_private.h /usr/include/json-c/. \
    && rm json_object_private.h \
    \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \    
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \        
        geos \
        gdal \
        proj4 \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-edge

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./update-postgis.sh /usr/local/bin


#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

# adapted from https://github.com/openresty/docker-openresty

set -ex

# configuring, building and installing is not strictly necessary, since
# module development requires to rebuild nginx itself, but it's a good
# check to see if everything is ok
# configuring has the benefit that it builds and installs luajit, which
# can then be reused during development (see the additions to .bashrc)

# Docker Build Arguments
RESTY_VERSION=${RESTY_VERSION:-"1.21.4.1"}
RESTY_PREFIX=${HOME}/local/openresty
RESTY_CONFIG_OPTIONS="\
    --with-pcre-jit \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-threads \
    --with-compat \
    --prefix=${RESTY_PREFIX} "

cd
wget --quiet https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz
tar zxf openresty-${RESTY_VERSION}.tar.gz
cd openresty-${RESTY_VERSION}
./configure \
    --with-cc='ccache gcc -fdiagnostics-color=always' \
    --with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC" \
    --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
    ${RESTY_CONFIG_OPTIONS}
make
make install

# add the location of openresty executables to the PATH
# save resty configuration options for future reuse during development

cat << EOF > ${HOME}/openresty-env
PATH="${RESTY_PREFIX}/luajit/bin:${RESTY_PREFIX}/nginx/sbin:${RESTY_PREFIX}/bin:\${PATH}"
export RESTY_CONFIG_OPTIONS="${RESTY_CONFIG_OPTIONS} --with-luajit=${RESTY_PREFIX}/luajit"
EOF

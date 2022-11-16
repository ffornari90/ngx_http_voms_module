#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

ngxVersion=1.22.1

wget -O /nginx-$ngxVersion.tar.gz https://nginx.org/download/nginx-$ngxVersion.tar.gz
wget -O /ngx-http-echo-module.tar.gz https://github.com/openresty/echo-nginx-module/archive/refs/tags/v0.63.tar.gz
cd /
tar -xzf /nginx-$ngxVersion.tar.gz
tar xzf /ngx-http-echo-module.tar.gz

cd /nginx-$ngxVersion
./configure --prefix=/etc/nginx --with-compat --with-http_ssl_module --add-dynamic-module=/ngx-http-voms-module --add-dynamic-module=/echo-nginx-module-0.63
make modules
make install -j 8
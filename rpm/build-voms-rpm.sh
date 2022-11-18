#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

ngxVersion=1.22.1

# set environment to build rpm
rpmdev-setuptree
cat <<EOF > ${HOME}/.rpmmacros
%_topdir %{getenv:HOME}/rpmbuild
EOF

# set sources
cd ~/rpmbuild/SOURCES
wget -O nginx-$ngxVersion.tar.gz https://nginx.org/download/nginx-$ngxVersion.tar.gz
wget -O ./ngx-http-echo-module.tar.gz https://github.com/openresty/echo-nginx-module/archive/refs/tags/v0.63.tar.gz
tar xzf ngx-http-echo-module.tar.gz

# set voms modules sources
mkdir ngx-http-voms-module
cp ~/config ngx-http-voms-module/
cp ~/config.make ngx-http-voms-module/
cp -r ~/src ngx-http-voms-module/
cp ~/rpm/nginx-module-http-voms.spec ~/rpmbuild/SPECS

# build and install rpm
rpmlint ~/rpmbuild/SPECS/nginx-module-http-voms.spec
rpmbuild -ba ~/rpmbuild/SPECS/nginx-module-http-voms.spec

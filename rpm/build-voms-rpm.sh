#!/usr/bin/env bash

# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
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

# set voms modules sources
mkdir ngx-http-voms-module
cp ${CI_PROJECT_DIR}/config ngx-http-voms-module/
cp ${CI_PROJECT_DIR}/config.make ngx-http-voms-module/
cp -r ${CI_PROJECT_DIR}/src ngx-http-voms-module/
cp ${CI_PROJECT_DIR}/rpm/nginx-module-http-voms.spec ~/rpmbuild/SPECS

# build and install rpm
rpmlint ~/rpmbuild/SPECS/nginx-module-http-voms.spec
rpmbuild -ba ~/rpmbuild/SPECS/nginx-module-http-voms.spec

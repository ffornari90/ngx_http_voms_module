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

# download nginx sources
cd ~/rpmbuild/SOURCES/
wget http://nginx.org/packages/centos/7/SRPMS/nginx-$ngxVersion-1.el7.ngx.src.rpm
rpm2cpio nginx-$ngxVersion-1.el7.ngx.src.rpm | cpio -idm

# set the nginx spec file with the httpg patch
cp ~/nginx-httpg_no_delegation.patch ${HOME}/rpmbuild/SOURCES/
cp ~/rpm/nginx.spec ~/rpmbuild/SPECS

# build rpm
rpmlint ~/rpmbuild/SPECS/nginx.spec
rpmbuild -ba ~/rpmbuild/SPECS/nginx.spec

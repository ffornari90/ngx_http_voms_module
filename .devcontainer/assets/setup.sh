#!/bin/sh

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum -y install \
    hostname \
    epel-release \
    which \
    wget \
    tar \
    sudo \
    file

yum -y install \
    gcc-c++ \
    GeoIP-devel \
    gd-devel \
    gettext \
    ccache \
    libxslt-devel \
    lcov \
    perl-ExtUtils-Embed \
    perl-Test-Nginx \
    perl-Digest-SHA \
    readline-devel \
    boost-devel \
    voms-devel \
    make \
    patch \
    less

yum -y install https://repo.ius.io/ius-release-el7.rpm centos-release-scl

yum -y install \
    git224 \
    devtoolset-10

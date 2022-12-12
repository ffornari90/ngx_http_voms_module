#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum -y install \
    https://repo.ius.io/ius-release-el7.rpm \
    centos-release-scl \
    epel-release

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum -y install \
    hostname \
    which \
    wget \
    tar \
    sudo \
    file \
    less \
    git236 \
    devtoolset-10 \
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
    openssl \
    zlib-devel \
    pcre2-devel \
    rpmdevtools \
    rpmlint \
    cpan \
    voms-clients-java
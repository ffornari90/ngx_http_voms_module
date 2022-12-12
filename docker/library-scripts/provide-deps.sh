#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum -y install epel-release
yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum -y install \
    hostname \
    which \
    wget \
    tar \
    sudo \
    file \
    readline \
    gettext \
    less \
    openssl \
    zlib-devel \
    pcre2-devel \
    boost-devel \
    voms-devel \
    patch \
    gcc-c++ \
    rpmdevtools \
    rpmlint \
    perl-ExtUtils-Embed \
    perl-Test-Nginx \
    perl-Digest-SHA \
    cpan \
    voms-clients-java
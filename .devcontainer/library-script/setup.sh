#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum -y install \
    epel-release \
    https://repo.ius.io/ius-release-el7.rpm \
    centos-release-scl

yum -y install \
    hostname \
    which \
    wget \
    tar \
    sudo \
    file \
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
    less \
    git224 \
    devtoolset-10

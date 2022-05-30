#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum -y install epel-release

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
    patch

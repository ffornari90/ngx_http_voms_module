#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum -y install epel-release

yum -y install wget 
wget https://openresty.org/package/rhel/openresty.repo
mv openresty.repo /etc/yum.repos.d/

yum -y install \
    hostname \
    which \
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
    cpan \
    voms-clients-java
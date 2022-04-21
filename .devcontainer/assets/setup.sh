#!/bin/sh
set -ex

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

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

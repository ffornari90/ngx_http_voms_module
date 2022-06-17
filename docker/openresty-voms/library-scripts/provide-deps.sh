#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum -y install epel-release

yum -y install \
    hostname \
    which \
    wget \
    tar \
    sudo \
    file \
    voms \
    zlib \
    pcre \
    readline \
    gettext
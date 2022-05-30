#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

yum -y install \
    https://repo.ius.io/ius-release-el7.rpm \
    centos-release-scl

yum -y install \
    hostname \
    which \
    wget \
    tar \
    sudo \
    file \
    less \
    git236 \
    devtoolset-10

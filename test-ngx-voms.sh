#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

yum install -y faketime
cd /home/nginx/
faketime '2021-11-14 08:15:42' prove -v

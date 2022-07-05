#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

if [ -r "${HOME}/openresty-env" ]; then
    . ${HOME}/openresty-env
fi

module_root=${NGX_HTTP_VOMS_MODULE_ROOT:-${CI_PROJECT_DIR:-${HOME}/ngx_http_voms_module}}

if [ ! -d "${module_root}" ]; then
    >&2 echo 'Invalid ngx_http_voms_module environment ("'${module_root}'")'
    exit 1
fi

mkdir -p /tmp/t
prove ${module_root}/t

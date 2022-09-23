#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

# The script requires the locations of the openresty bundle and of the
# ngx_http_voms_module code (for example as checked-out from git). The locations
# are expressed by the environment variables OPENRESTY_ROOT and
# NGX_HTTP_VOMS_MODULE_ROOT respectively, if available. If they are not set,
# they are guessed:
# * a unique openresty bundle is looked for in ${HOME}
# * the ngx_http_voms_module code is looked for in the working directory of the
#   continuous integration environment first and then in ${HOME}

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

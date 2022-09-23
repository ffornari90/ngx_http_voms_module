#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

# This script builds in debug mode and installs openresty together with the
# ngx_http_voms_module.
#
# The script requires the locations of the openresty bundle and of the
# ngx_http_voms_module code (for example as checked-out from git). The locations
# are expressed by the environment variables OPENRESTY_ROOT and
# NGX_HTTP_VOMS_MODULE_ROOT respectively, if available. If they are not set,
# they are guessed:
# * a unique openresty bundle is looked for in ${HOME}
# * the ngx_http_voms_module code is looked for in the working directory of the
#   continuous integration environment first and then in ${HOME}
#
# The script works best (i.e. it is tested) if run within a docker container
# started from the .devcontainer

set -e

usage()
{
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "The default compilation options are '-g -O2'"
    echo
    echo "OPTIONS:"
    echo
    echo "-h|--help"
    echo "--optimize - compile in optimized mode"
    echo "--debug - compile in debug mode"
    echo "--coverage - compile in debug mode and enable coverage"
    echo "--enable-debug-log - enable nginx debug log"
    echo
}

debug=
cflags="-g -O2"
ldflags=

while [ "$1" != "" ]; do
  case $1 in
    --enable-debug-log)
      debug="--with-debug --with-poll_module"
      ;;
    --optimize)
      cflags="$cflags -O3 -DNDEBUG"
      ;;
    --debug)
      cflags="$cflags -O0"
      ;;
    --coverage)
      cflags="$cflags -O0 --coverage"
      ldflags="--coverage"
      ;;
    -h|--help)
      usage
      exit
      ;;
    *)
      echo Error: option $1 unrecognized
      exit 1
      ;;
  esac
  shift
done

if [ -f "${HOME}/openresty-env" ]; then
    . ${HOME}/openresty-env
fi

gcc --version

openresty_root=${OPENRESTY_ROOT:-$(ls -d ${HOME}/openresty-*/ 2> /dev/null)}

if [ $(echo ${openresty_root} | wc -w) != 1 -o ! -d "${openresty_root}" ]; then
    >&2 echo 'Invalid openresty environment ("'${openresty_root}'")'
    exit 1
fi

module_root=${NGX_HTTP_VOMS_MODULE_ROOT:-${CI_PROJECT_DIR:-${HOME}/ngx_http_voms_module}}

if [ ! -d "${module_root}" ]; then
    >&2 echo 'Invalid ngx_http_voms_module environment ("'${module_root}'")'
    exit 1
fi

if [ ! -f "${module_root}/nginx-httpg_no_delegation.patch" ]; then
    >&2 echo "nginx-httpg_no_delegation.patch not found in ${module_root} dir."
    exit 1
fi

cd ${openresty_root}
./configure \
  --with-cc="ccache gcc -fdiagnostics-color=always" \
  --with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC ${cflags}" \
  --with-ld-opt="${ldflags}" \
  --with-luajit-xcflags="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT" \
  ${RESTY_CONFIG_OPTIONS} \
  ${debug} \
  --add-module=${module_root}

nginx_version=$(find build -name nginx.h | xargs awk '/define NGINX_VERSION/ {print $3}' | tr -d '"')
cd build/nginx-${nginx_version}
patch -p1 < ${module_root}/nginx-httpg_no_delegation.patch
cd -

make -j $(nproc)
make install

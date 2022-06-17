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

usage()
{
    echo "USAGE: $0 [OPTIONS] [TEXT]"
    echo ""
    echo "The default optimization level is -O3"
    echo ""
    echo "OPTIONS"
    echo ""
    echo "-h|--help"
    echo "-o|--opt-log to enable the --with-debug option and the optimization level -O2"
    echo "-d|--debug to enable the --with-debug option and the optimization level -O0"
    echo "-c|--coverage to add the --coverage option to the --with-{ld|cc}-opt option and enable the debug options"
    echo ""
}

#The script at the moment allows only debug builds, i.e. "-O0". This option is kept in shell variables cc2, but there is no way to set it to something else. I propose that by default it is set to -O2 (or even -O3) and is set to -O0 only if the option --debug is passed to the script. Moreover --coverage should imply --debug.


cc1=-g
debug=""
cc3=""
cc2=-O2
ld=""

while [ "$1" != "" ]; do
  option=`echo $1 | awk -F= '{print $1}'`
  case $option in
    -o|--opt-log)
      debug='--with-debug'
      cc2=-O2
      echo Enabled the debug option $debug and the optimization level $cc2
      ;;
    -d|--debug)
      debug='--with-debug'
      cc2=-O0
      echo Enabled the debug option $debug and the optimization level $cc2
      ;;
    -c|--coverage)
      cc3=--coverage
      ld='--with-ld-opt=--coverage'
      echo Enabled the coverage options $cc3 $ld
      ;;
    -h|--help)
      usage
      exit
      ;;
    *)
      debug=""
      cc3=""
      cc2=-O2
      ld=""
      ;;
  esac
  shift
done

if [ ! -z "${cc3}" ]; then
    if [ -z "${debug}" ]; then
        debug="--with-debug"
        cc2=-O0
        echo Enabled the debug option $debug and the optimization level $cc2
    fi
fi

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

if [ ! -f "./nginx-httpg_no_delegation.patch" ]; then
    >&2 echo 'nginx-httpg_no_delegation.patch not found in current dir.'
    exit 1
fi

RESTY_PACKAGES_PREFIX=/usr/local/openresty
ZLIB_PREFIX=/usr
OPENSSL_PREFIX=/usr
PCRE_PREFIX=/usr

cd ${openresty_root}
./configure \
  --prefix=${RESTY_PREFIX} \
  --with-cc='ccache gcc -fdiagnostics-color=always' \
  --with-cc-opt="-DNGX_LUA_ABORT_AT_PANIC -I%{zlib_prefix}/include -I%{pcre_prefix}/include -I%{openssl_prefix}/include" \
  --with-ld-opt="-L%{zlib_prefix}/lib -L%{pcre_prefix}/lib -L%{openssl_prefix}/lib -Wl,-rpath,%{zlib_prefix}/lib:%{pcre_prefix}/lib:%{openssl_prefix}/lib" \
  --with-pcre-jit \
  --without-http_rds_json_module \
  --without-http_rds_csv_module \
  --without-lua_rds_parser \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-http_v2_module \
  --without-mail_pop3_module \
  --without-mail_imap_module \
  --without-mail_smtp_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_secure_link_module \
  --with-http_random_index_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-threads \
  --with-compat \
  --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' \
  ${debug} \
  --with-cc-opt="${cc1} ${cc2} ${cc3}" \
  ${ld} \
  --add-module=${module_root}

nginx_version=$(find build -name nginx.h | xargs awk '/define NGINX_VERSION/ {print $3}' | tr -d '"')
cd build/nginx-${nginx_version}
patch -p1 < nginx-httpg_no_delegation.patch
cd -

make -j $(nproc)
make install

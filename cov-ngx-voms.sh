#!/bin/sh

# Copyright 2018 Istituto Nazionale di Fisica Nucleare
#
# Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the
# European Commission - subsequent versions of the EUPL (the "Licence"). You may
# not use this work except in compliance with the Licence. You may obtain a copy
# of the Licence at:
#
# https://joinup.ec.europa.eu/software/page/eupl
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# Licence for the specific language governing permissions and limitations under
# the Licence.

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
# started from the storm2/ngx-voms-build image.

mkdir -p cov
cd cov

geninfo --base-directory ${HOME}/openresty-1.13.6.1/build/nginx-1.13.6/objs/addon/src/ --output-filename coverage.info ${HOME}/openresty-1.13.6.1/build/nginx-1.13.6/objs/addon/src/

genhtml --demangle-cpp coverage.info &>output
exit_status=$?
if [ ! $exit_status -eq 0 ]; then
   echo "check output"
fi
echo $exit_status


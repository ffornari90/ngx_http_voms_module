#!/bin/sh

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

set -ex

cat << EOF >> ${HOME}/.bashrc
if [ -f "\${HOME}/openresty-env" ]; then
    . \${HOME}/openresty-env
fi

if [ -d \${HOME}/bin ]; then
  PATH=\${HOME}/bin:\${PATH}
fi

if [ -n "\${PS1}" ]; then
    echo
    echo "To build and install openresty with the ngx_http_voms_module run 'build-install-ngx-voms.sh'"
    echo "'nginx-httpg_no_delegation.patch' is needed in the directory where the user runs the script"
    echo
fi
EOF

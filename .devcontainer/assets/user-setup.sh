#!/bin/sh
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
    echo
fi
EOF

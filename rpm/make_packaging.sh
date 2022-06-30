#!/usr/bin/env bash

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

voms_module_prefix=${HOME}/ngx_http_voms_module
if [ $# -eq 1 ]; then
    voms_module_prefix=$1
fi

if [ ! -d "$voms_module_prefix" ]; then
    echo "$voms_module_prefix doesn't exist" >&2
    exit 1
fi

mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cat <<EOF > ${HOME}/.rpmmacros
%_topdir %{getenv:HOME}/rpmbuild
%voms_module_prefix ${voms_module_prefix}
EOF

cat ${HOME}/.rpmmacros

cp ${voms_module_prefix}/nginx-httpg_no_delegation.patch ${HOME}/rpmbuild/SOURCES/

cp SOURCES/* ${HOME}/rpmbuild/SOURCES/
cp SPECS/*.spec ${HOME}/rpmbuild/SPECS/

spectool -g -R ${HOME}/rpmbuild/SPECS/openresty-voms.spec
rpmbuild -ba ${HOME}/rpmbuild/SPECS/openresty-voms.spec

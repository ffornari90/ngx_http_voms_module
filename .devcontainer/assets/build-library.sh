#!/usr/bin/env bash

# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

downloadNginx() {

# check if a version of nginx is specified
if [ -z ${ngxVersion} ]; then
    ngxVersion=1.24.0
fi
echo "nginx version required: ${ngxVersion}";

# check if ~/rpmbuild exists and is not empty
if [ "$(ls -A ${HOME}/rpmbuild)" ];
then
    echo "Error: ${HOME}/rpmbuild already exists and is not empty"
    return 1
fi

# setup rpmbuild dir
cat <<EOF > ${HOME}/.rpmmacros
%_topdir %{getenv:HOME}/rpmbuild
EOF
cd
rpmdev-setuptree

# download nginx sources
cd ~/rpmbuild/SOURCES/
wget http://nginx.org/packages/centos/7/SRPMS/nginx-$ngxVersion-1.el7.ngx.src.rpm
rpm2cpio nginx-$ngxVersion-1.el7.ngx.src.rpm | cpio -idm

if [ -z ${CI_PROJECT_DIR} ]; then
    CI_PROJECT_DIR="/workspaces/ngx_http_voms_module";
fi
cd $CI_PROJECT_DIR

}

buildHttpgNginxRPM() {

if [ -z ${CI_PROJECT_DIR} ]; then
    CI_PROJECT_DIR="/workspaces/ngx_http_voms_module";
fi

# set the nginx spec file with the httpg patch
cd ~/rpmbuild/SOURCES/
cp ${CI_PROJECT_DIR}/nginx-httpg_no_delegation.patch ${HOME}/rpmbuild/SOURCES/
cp ${CI_PROJECT_DIR}/rpm/nginx.spec ~/rpmbuild/SPECS

# build rpm
rpmlint ~/rpmbuild/SPECS/nginx.spec
rpmbuild -ba ~/rpmbuild/SPECS/nginx.spec

# include httpg in the rpm name
mv ~/rpmbuild/RPMS/x86_64/nginx-$ngxVersion-1.el7.ngx.x86_64.rpm  ~/rpmbuild/RPMS/x86_64/nginx-httpg-$ngxVersion-1.el7.ngx.x86_64.rpm
mv ~/rpmbuild/RPMS/x86_64/nginx-debuginfo-$ngxVersion-1.el7.ngx.x86_64.rpm  ~/rpmbuild/RPMS/x86_64/nginx-httpg-debuginfo-$ngxVersion-1.el7.ngx.x86_64.rpm
mv ~/rpmbuild/SRPMS/nginx-$ngxVersion-1.el7.ngx.src.rpm  ~/rpmbuild/SRPMS/nginx-httpg-$ngxVersion-1.el7.ngx.src.rpm

cd ${CI_PROJECT_DIR}

}

buildVomsModuleRPM() {

if [ -z ${CI_PROJECT_DIR} ]; then
    CI_PROJECT_DIR="/workspaces/ngx_http_voms_module";
fi

# set voms modules sources
cd ~/rpmbuild/SOURCES/
mkdir ngx-http-voms-module
cp ${CI_PROJECT_DIR}/config ngx-http-voms-module/
cp ${CI_PROJECT_DIR}/config.make ngx-http-voms-module/
cp -r ${CI_PROJECT_DIR}/src ngx-http-voms-module/
cp ${CI_PROJECT_DIR}/rpm/nginx-module-http-voms.spec ~/rpmbuild/SPECS

# build rpm
rpmlint ~/rpmbuild/SPECS/nginx-module-http-voms.spec
rpmbuild -ba ~/rpmbuild/SPECS/nginx-module-http-voms.spec

cd ${CI_PROJECT_DIR}

}

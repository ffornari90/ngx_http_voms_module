#!/bin/sh

# install rpm build tools:
sudo yum install -y rpm-build redhat-rpm-config rpmdevtools

# install openresty's build requirements:
sudo yum install -y gcc make perl \
    perl-Data-Dumper libtool ElectricFence systemtap-sdt-devel valgrind-devel \
    ccache clang boost-devel

mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

cp ${HOME}/nginx-httpg_no_delegation.patch ~/rpmbuild/SOURCES/

cp SOURCES/* ~/rpmbuild/SOURCES/
cp SPECS/*.spec ~/rpmbuild/SPECS/

cd ~/rpmbuild/SPECS

for file in *.spec; do
    spectool -g -R $file
done

cat ${CI_PROJECT_DIR}/.rpmmacros

rpmbuild -ba openresty-voms.spec

cd ~

# tar cvzf rpmbuild.tar.gz rpmbuild

FROM baltig.infn.it:4567/storm2/build/ngx-voms-build:issue-17-latest

USER root

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm centos-release-scl \
    && yum install -y git224 devtoolset-10

USER $BUILD_USER

FROM storm2/ngx-voms-build

USER root

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm centos-release-scl \
    && yum install -y git224 devtoolset-10

USER $BUILD_USER

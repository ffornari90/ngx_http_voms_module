### FROM baltig.infn.it:4567/storm2/build/ngx-voms-build:issue-17-latest
## FROM baltig.infn.it:4567/storm2/build/base
FROM centos:7

# Allow customization of build user ID and name
ARG BUILD_USER=build
ARG BUILD_USER_UID=1000

# Allow customization of storm user ID and name
ARG STORM_USER=storm
ARG STORM_USER_UID=1001

# Allow customization of test user ID and name
ARG TEST_USER=test
ARG TEST_USER_UID=1002

ENV BUILD_USER $BUILD_USER
ENV BUILD_USER_UID $BUILD_USER_UID

ENV STORM_USER $STORM_USER
ENV STORM_USER_UID $STORM_USER_UID

ENV TEST_USER $TEST_USER
ENV TEST_USER_UID $TEST_USER_UID

RUN echo "include_only=.garr.it,.cern.ch" >> /etc/yum/pluginconf.d/fastestmirror.conf && \
      yum clean all && \
      yum install -y hostname epel-release && \
      yum -y update && \
      yum -y install which wget tar sudo file && \
      echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
      adduser --uid ${BUILD_USER_UID} ${BUILD_USER} && \
      usermod -a -G wheel ${BUILD_USER} && \
      adduser --uid ${STORM_USER_UID} ${STORM_USER} && \
      usermod -a -G wheel ${STORM_USER} && \
      adduser --uid ${TEST_USER_UID} ${TEST_USER} && \
      usermod -a -G wheel ${TEST_USER} && \
      yum clean all && \
      rm -rf /var/cache/yum

ADD assets/setup.sh /docker/
ADD assets/user-setup.sh /docker/
ADD assets/build-install-openresty.sh /docker/
ADD --chown=$BUILD_USER:$BUILD_USER assets/nginx-httpg_no_delegation.patch /home/$BUILD_USER/
ADD --chown=$BUILD_USER:$BUILD_USER assets/build-install-ngx-voms.sh /home/$BUILD_USER/bin/
RUN sh /docker/setup.sh

USER $BUILD_USER

RUN sh /docker/build-install-openresty.sh \
    && sh /docker/user-setup.sh

USER root

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm centos-release-scl \
    && yum install -y git224 devtoolset-10

USER $BUILD_USER

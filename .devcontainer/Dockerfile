# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of build user ID and name
ARG VSCODE_USER=vscode
ARG VSCODE_USER_UID=1000
ARG VSCODE_GID=${VSCODE_USER_UID}

ENV VSCODE_USER $VSCODE_USER
ENV VSCODE_USER_UID $VSCODE_USER_UID
ENV VSCODE_GID=${VSCODE_USER_UID}

COPY assets/provide-user.sh /docker/
RUN sh /docker/provide-user.sh ${VSCODE_USER} ${VSCODE_USER_UID} ${VSCODE_GID}

RUN echo "include_only=.garr.it,.cern.ch" >> /etc/yum/pluginconf.d/fastestmirror.conf && \
      yum clean all && \
      yum install -y hostname epel-release && \
      yum -y update && \
      yum -y install which wget tar sudo file && \
      yum clean all && \
      rm -rf /var/cache/yum

ADD assets/setup.sh /docker/
ADD assets/user-setup.sh /docker/
ADD assets/build-install-openresty.sh /docker/
ADD --chown=$VSCODE_USER:$VSCODE_USER assets/nginx-httpg_no_delegation.patch /home/$VSCODE_USER/
ADD --chown=$VSCODE_USER:$VSCODE_USER assets/build-install-ngx-voms.sh /home/$VSCODE_USER/bin/
RUN sh /docker/setup.sh

USER $VSCODE_USER

RUN sh /docker/build-install-openresty.sh \
    && sh /docker/user-setup.sh

USER root

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm centos-release-scl \
    && yum install -y git224 devtoolset-10

USER $VSCODE_USER
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
COPY assets/setup.sh /docker/
COPY assets/user-setup.sh /docker/
COPY assets/build-install-openresty.sh /docker/

RUN yum update -y && \
    yum install -y hostname epel-release which wget tar sudo file && \
    sh /docker/provide-user.sh ${VSCODE_USER} ${VSCODE_USER_UID} ${VSCODE_GID} && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY --chown=$VSCODE_USER:$VSCODE_USER assets/nginx-httpg_no_delegation.patch /home/$VSCODE_USER/
COPY --chown=$VSCODE_USER:$VSCODE_USER assets/build-install-ngx-voms.sh /home/$VSCODE_USER/bin/
RUN sh /docker/setup.sh

USER $VSCODE_USER

RUN sh /docker/build-install-openresty.sh && \
    sh /docker/user-setup.sh

USER root

RUN yum install -y https://repo.ius.io/ius-release-el7.rpm centos-release-scl \
    && yum install -y git224 devtoolset-10

USER $VSCODE_USER
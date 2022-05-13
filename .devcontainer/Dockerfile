# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of build user ID and name
ARG DEV_USER=vscode
ARG DEV_USER_UID=1000
ARG DEV_GID=${DEV_USER_UID}

ENV DEV_USER $DEV_USER
ENV DEV_USER_UID $DEV_USER_UID
ENV DEV_GID ${DEV_USER_UID}

COPY library-script/* /docker/

RUN yum update -y && \
    sh /docker/setup.sh && \
    sh /docker/provide-user.sh ${DEV_USER} ${DEV_USER_UID} ${DEV_GID} && \
    yum clean all && rm -rf /var/cache/yum

COPY --chown=$DEV_USER:$DEV_USER assets/build-install-openresty-voms.sh /home/$DEV_USER/bin/

USER $DEV_USER

RUN sh /docker/build-install-openresty.sh
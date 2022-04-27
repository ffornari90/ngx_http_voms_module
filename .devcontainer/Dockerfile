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

COPY assets/provide-user.sh /docker/
COPY assets/setup.sh /docker/
COPY assets/user-setup.sh /docker/
COPY assets/build-install-openresty.sh /docker/

RUN yum update -y && \
    sh /docker/setup.sh && \
    sh /docker/provide-user.sh ${DEV_USER} ${DEV_USER_UID} ${DEV_GID} && \
    yum clean all && rm -rf /var/cache/yum

COPY --chown=$DEV_USER:$DEV_USER assets/nginx-httpg_no_delegation.patch /home/$DEV_USER/
COPY --chown=$DEV_USER:$DEV_USER assets/build-install-ngx-voms.sh /home/$DEV_USER/bin/

USER $DEV_USER

RUN sh /docker/build-install-openresty.sh && \
    sh /docker/user-setup.sh
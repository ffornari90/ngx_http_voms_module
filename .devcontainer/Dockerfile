# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of build user ID and name
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV USERNAME $USERNAME
ENV USER_UID $USER_UID
ENV USER_GID ${USER_UID}

COPY library-script/* /docker/

RUN yum update -y && \
    sh /docker/setup.sh && \
    sh /docker/provide-user.sh ${USERNAME} ${USER_UID} ${USER_GID} && \
    yum clean all && rm -rf /var/cache/yum

COPY --chown=$USERNAME:$USERNAME assets/build-install-openresty-voms.sh /home/$USERNAME/bin/

USER $USERNAME

RUN sh /docker/build-install-openresty.sh
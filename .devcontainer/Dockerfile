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

COPY library-script/*.sh /tmp/library-script

RUN yum update -y && \
    sh /tmp/library-script/setup.sh && \
    sh /tmp/library-script/provide-user.sh ${USERNAME} ${USER_UID} ${USER_GID} && \
    yum clean all && rm -rf /var/cache/yum

COPY --chown=$USERNAME:$USERNAME assets/build-install-openresty-voms.sh /home/$USERNAME/bin/

USER $USERNAME

RUN sh /tmp/library-script/build-install-openresty.sh
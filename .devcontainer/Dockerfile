# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of build user ID and name
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

COPY library-scripts/*.sh /tmp/library-scripts/

RUN yum update -y && \
    sh /tmp/library-scripts/provide-dev-deps.sh && \
    sh /tmp/library-scripts/provide-user.sh ${USERNAME} ${USER_UID} ${USER_GID} && \
    yum clean all && rm -rf /var/cache/yum

USER $USERNAME

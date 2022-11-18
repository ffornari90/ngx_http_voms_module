# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of nginx user ID and name
ARG USERNAME=nginx
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# install dependencies
COPY library-scripts/*.sh /tmp/library-scripts/
RUN yum update -y && \
    sh /tmp/library-scripts/provide-deps.sh && \
    sh /tmp/library-scripts/provide-user.sh ${USERNAME} ${USER_UID} ${USER_GID} && \
    mkdir /pkgs && \
    yum clean all && rm -rf /var/cache/yum

# install nginx with patch for HTTPG and voms dynamic module
COPY *.rpm /pkgs/
RUN rpm -ivh /pkgs/nginx-1.22.1-1.el7.ngx.x86_64.rpm && \
    rpm -ivh /pkgs/nginx-module-http-voms-1.22.1-1.el7.x86_64.rpm

# import test 
COPY t /home/nginx/t
COPY test-ngx-voms.sh /home/nginx/
RUN sudo chown -R nginx:nginx /home/nginx/

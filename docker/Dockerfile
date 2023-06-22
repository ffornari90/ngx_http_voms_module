# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

ENV DOCKER_IN_DOCKER_ENABLED=true
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/go/bin
VOLUME /var/run/docker.sock:/var/run/docker.sock

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

RUN yum install -y yum-utils device-mapper-persistent-data lvm2 && \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum install -y docker-ce docker-ce-cli containerd.io

COPY artifacts/*.rpm /pkgs/

# install nginx httpg + voms and njs dynamic modules (latest version)
COPY nginx.repo /etc/yum.repos.d/nginx.repo
RUN rpm -ivh /pkgs/nginx-httpg-1.24.0-1.el7.ngx.x86_64.rpm && \
    rpm -ivh /pkgs/nginx-module-http-voms-1.24.0-1.el7.x86_64.rpm && \
    yum install -y nginx-module-njs

# install nginx + voms and njs dynamic modules
# RUN yum -y install nginx nginx-module-njs && \
#     rpm -ivh /pkgs/nginx-module-http-voms-1.24.0-1.el7.x86_64.rpm

EXPOSE 80
EXPOSE 443

STOPSIGNAL SIGQUIT

RUN git clone https://github.com/kubernetes/ingress-nginx.git && \
    cd ingress-nginx && git checkout tags/controller-v1.5.1 && \
    make build && mv rootfs/bin/amd64/* /

CMD ["/nginx-ingress-controller"]

# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of nginx user ID and name
ARG USERNAME=nginx
ARG USER_UID=1001

COPY library-scripts/*.sh /tmp/library-scripts/

RUN yum update -y && \
    sh /tmp/library-scripts/provide-deps.sh && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    adduser --uid ${USER_UID} ${USERNAME} && \
    usermod -a -G root ${USERNAME} && \
    yum clean all && rm -rf /var/cache/yum

RUN mkdir /pkgs

ADD *.rpm /pkgs/

RUN yum -y localinstall /pkgs/*.rpm && \
      chmod -R g+rwx /usr/local/openresty-voms/nginx && \
      mkdir -p /etc/nginx/conf.d

ADD assets/nginx.conf /usr/local/openresty-voms/nginx/conf/nginx.conf

CMD ["/usr/bin/openresty-voms", "-g", "daemon off;"]

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

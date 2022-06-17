# Copyright 2018-2022 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

# Allow customization of nginx user ID and name
ARG USERNAME=nginx
ARG USER_UID=1001

RUN echo "include_only=.garr.it,.cern.ch" >> /etc/yum/pluginconf.d/fastestmirror.conf && \
      yum clean all && \
      yum install -y hostname epel-release && \
      yum -y update && \
      yum -y install which wget tar sudo file && \
      echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
      adduser --uid ${USER_UID} ${USERNAME} && \
      usermod -a -G root ${USERNAME} && \
      yum clean all && \
      rm -rf /var/cache/yum

RUN  \
          yum -y install voms zlib pcre readline gettext && \ 
          mkdir /pkgs

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

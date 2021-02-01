FROM centos:7

RUN echo "include_only=.garr.it,.cern.ch" >> /etc/yum/pluginconf.d/fastestmirror.conf && \
      yum clean all && \
      yum install -y hostname epel-release && \
      yum -y update && \
      yum -y install which wget tar sudo file && \
      echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
      yum clean all && \
      rm -rf /var/cache/yum

RUN  \
          yum -y install voms zlib pcre readline gettext && \ 
          mkdir /pkgs

ADD *.rpm /pkgs/

RUN yum -y localinstall /pkgs/*.rpm

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

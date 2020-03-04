FROM storm2/base:latest

RUN sudo yum -y install voms zlib pcre readline gettext && \
      sudo yum clean all && rm -rf /var/cache/yum

ADD assets/setup.sh /docker/

RUN sh /docker/setup.sh

RUN mkdir /cores

USER root

ADD openresty-voms-1.15.8.1-7.el7.x86_64.rpm openresty-voms-1.15.8.1-7.el7.x86_64.rpm
ADD openresty-voms-debuginfo-1.15.8.1-7.el7.x86_64.rpm openresty-voms-debuginfo-1.15.8.1-7.el7.x86_64.rpm

ADD openresty-voms-doc-1.15.8.1-7.el7.noarch.rpm openresty-voms-doc-1.15.8.1-7.el7.noarch.rpm
ADD openresty-voms-opm-1.15.8.1-7.el7.noarch.rpm openresty-voms-opm-1.15.8.1-7.el7.noarch.rpm
ADD openresty-voms-resty-1.15.8.1-7.el7.noarch.rpm openresty-voms-resty-1.15.8.1-7.el7.noarch.rpm

RUN sudo yum -y localinstall openresty-voms-1.15.8.1-7.el7.x86_64.rpm \
    openresty-voms-resty-1.15.8.1-7.el7.noarch.rpm \
    openresty-voms-doc-1.15.8.1-7.el7.noarch.rpm \
    openresty-voms-opm-1.15.8.1-7.el7.noarch.rpm \
    openresty-voms-resty-1.15.8.1-7.el7.noarch.rpm

RUN chown -R ${STORM_USER}:${STORM_USER} /usr/local/openresty-voms/ /usr/lib/systemd/system/openresty-voms.service /usr/bin/openresty-voms

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["sudo", "/usr/bin/openresty-voms", "-g", "daemon off;"]

USER ${STORM_USER}

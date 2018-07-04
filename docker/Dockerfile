FROM storm2/base:latest

RUN sudo yum -y install voms zlib pcre readline gettext && \
      sudo yum clean all && rm -rf /var/cache/yum && \
      mkdir -p /etc/nginx/conf.d && \
      mkdir -p /home/build/local && \
      chown -R build:build /etc/nginx/conf.d /home/build/local

USER build
ADD openresty.tar.gz /home/build/local

RUN ls -lR /home/build && sudo chown -R build:build /home/build

RUN \
      touch /home/build/local/openresty/nginx/logs/access.log && \
      touch /home/build/local/openresty/nginx/logs/error.log && \
      ln -sf /dev/stdout /home/build/local/openresty/nginx/logs/access.log && \
      ln -sf /dev/stderr /home/build/local/openresty/nginx/logs/error.log

COPY assets/nginx.conf /home/build/local/openresty/nginx/conf/nginx.conf
COPY assets/srm.conf /etc/nginx/conf.d/

USER root

# Embed TINI since compose v3 syntax do not support the init
# option to run docker --init
#
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/home/build/local/openresty/bin/openresty", "-g", "daemon off;"]

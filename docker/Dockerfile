# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

ENV DOCKER_IN_DOCKER_ENABLED=true
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/go/bin
ENV LD_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:/opt/nginx/lib:/opt/nginx/auto/lib

VOLUME /var/run/docker.sock:/var/run/docker.sock

# Allow customization of nginx user ID and name
ARG USERNAME=nginx
ARG USER_UID=101
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
EXPOSE 8443

STOPSIGNAL SIGQUIT

RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-7 cmake3 && \
    source /opt/rh/devtoolset-7/enable && \
    git clone https://github.com/microsoft/mimalloc.git && \
    cd mimalloc && mkdir build && cd build && \
    cmake3 .. && make && make install && \
    ln -s /usr/local/lib64/libmimalloc.so /usr/local/lib/libmimalloc.so && \
    cd ../.. && rm -rf mimalloc

RUN git clone https://github.com/kubernetes/ingress-nginx.git && \
    cd ingress-nginx && git checkout tags/controller-v1.5.1 && \
    make build && mv rootfs/bin/amd64/* / && \
    mv rootfs/etc/nginx/* /etc/nginx/ && \
    cd .. && rm -rf ingress-nginx && \
    setcap cap_net_bind_service+ep /nginx-ingress-controller && \
    mkdir -p /etc/ingress-controller && \
    mkdir -p /etc/nginx/geoip && \
    mkdir -p /tmp/nginx && \
    mkdir -p /opt/nginx && \
    mkdir -p /tmp/luajit2 && \
    mkdir -p /tmp/ngx_devel_kit && \
    mkdir -p /tmp/lua-nginx-module && \
    mkdir -p /tmp/lua-resty-core && \
    mkdir -p /tmp/lua-resty-lrucache && \
    chown nginx: -R /etc/ingress-controller && \
    chown nginx: -R /etc/nginx && \
    chown nginx: -R /tmp/nginx && \
    chown nginx: -R /opt/nginx

ENV LUAJIT_LIB=/usr/local/lib/lua/5.1
ENV LUAJIT_INC=/usr/local/include/luajit-2.1

RUN NGINX_VERSION=$(nginx -V 2>&1 |sed -n -e 's/nginx version: //p' |cut -d'/' -f2); \
    curl -L "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" | tar -C /opt/nginx --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/luajit2/archive/refs/tags/v2.1-20230410.tar.gz" | tar -C /tmp/luajit2 --strip-components=1 -xz && \
    curl -L "https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.2.tar.gz" | tar -C /tmp/ngx_devel_kit --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.24.tar.gz" | tar -C /tmp/lua-nginx-module --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/lua-resty-core/archive/refs/tags/v0.1.24.tar.gz" | tar -C /tmp/lua-resty-core --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v0.13.tar.gz" | tar -C /tmp/lua-resty-lrucache --strip-components=1 -xz && \
    source /opt/rh/devtoolset-7/enable && \
    cd /tmp/luajit2 && make && make install && \
    cd /opt/nginx &&  ./configure \
    --with-ld-opt="-Wl,-rpath,/usr/local/lib/lua/5.1" \
    --add-dynamic-module=/tmp/ngx_devel_kit \
    --add-dynamic-module=/tmp/lua-nginx-module \
    --with-pcre --with-stream --with-http_ssl_module && \
    make -j2 && make install && \
    cd /tmp/lua-resty-core && \
    make install PREFIX=/opt/nginx && \
    cd /tmp/lua-resty-lrucache && \
    make install PREFIX=/opt/nginx && \
    ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx && \
    ln -s /usr/local/nginx/modules/ngx_http_lua_module.so /etc/nginx/modules/ngx_http_lua_module.so && \
    ln -s /usr/local/nginx/modules/ndk_http_module.so /etc/nginx/modules/ndk_http_module.so && \
    chown nginx: -R /usr/local/nginx

CMD ["/nginx-ingress-controller"]

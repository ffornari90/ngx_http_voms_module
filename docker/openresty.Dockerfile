# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

ENV DOCKER_IN_DOCKER_ENABLED=true
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/go/bin
ENV LD_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:/opt/nginx/lib:/opt/nginx/auto/lib
ENV LUAJIT_LIB=/usr/local/lib/lua/5.1
ENV LUAJIT_INC=/usr/local/include/luajit-2.1
ENV NGINX_VERSION=1.19.3.2

VOLUME /var/run/docker.sock:/var/run/docker.sock

# Allow customization of nginx user ID and name
ARG USERNAME=nginx
ARG USER_UID=101
ARG USER_GID=${USER_UID}

EXPOSE 80
EXPOSE 443
EXPOSE 8443

STOPSIGNAL SIGQUIT

# install dependencies
COPY library-scripts/*.sh /tmp/library-scripts/

RUN yum update -y && \
    sh /tmp/library-scripts/provide-deps.sh && \
    sh /tmp/library-scripts/provide-user.sh ${USERNAME} ${USER_UID} ${USER_GID} && \
    mkdir /pkgs && \
    yum install -y yum-utils device-mapper-persistent-data lvm2 centos-release-scl && \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum install -y docker-ce docker-ce-cli containerd.io devtoolset-7 cmake3 && \
    yum clean all && rm -rf /var/cache/yum && \
    source /opt/rh/devtoolset-7/enable && \
    git clone https://github.com/microsoft/mimalloc.git && \
    cd mimalloc && mkdir build && cd build && \
    cmake3 .. && make && make install && \
    ln -s /usr/local/lib64/libmimalloc.so /usr/local/lib/libmimalloc.so && \
    cd ../.. && rm -rf mimalloc && \
    git clone https://github.com/kubernetes/ingress-nginx.git && \
    cd ingress-nginx && git checkout tags/controller-v1.5.1 && \
    make build && \
    sed -i "s/    ajp_temp_path                   \/tmp\/nginx\/ajp-temp;\
/#    ajp_temp_path                   \/tmp\/nginx\/ajp-temp;/g" \
    rootfs/etc/nginx/template/nginx.tmpl && \
    sed -i '/    lua_package_path "\/etc\/nginx\/lua\/?.lua;;";/a \ \ \ \ lua_package_cpath "\/usr\/local\/lib\/lua\/?.so;;";' \
    rootfs/etc/nginx/template/nginx.tmpl && \
    mv rootfs/bin/amd64/* / && \
    mkdir -p /etc/ingress-controller && \
    mkdir -p /etc/nginx/modules && \
    mkdir -p /etc/nginx/geoip && \
    mkdir -p /tmp/nginx && \
    mkdir -p /opt/nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /tmp/luajit2 && \
    mkdir -p /tmp/ngx_devel_kit && \
    mkdir -p /tmp/lua-nginx-module && \
    mkdir -p /tmp/lua-cjson && \
    mkdir -p /tmp/lua-resty-http && \
    mkdir -p /tmp/lua-resty-dns && \
    mkdir -p /tmp/lua-resty-global-throttle && \
    mkdir -p /tmp/lua-resty-ipmatcher && \
    mkdir -p /tmp/lua-resty-roundrobin && \
    mkdir -p /tmp/lua-resty-cookie && \
    mkdir -p /tmp/lua-resty-lock && \
    mkdir -p /tmp/lua-resty-core && \
    mkdir -p /tmp/lua-resty-lrucache && \
    mkdir -p /tmp/stream-lua-nginx-module && \
    mv rootfs/etc/nginx/* /etc/nginx/ && \
    cd .. && rm -rf ingress-nginx && \
    setcap cap_net_bind_service=+eip /nginx-ingress-controller && \
    setcap cap_net_bind_service=+eip /wait-shutdown && \
    setcap cap_net_bind_service=+eip /dbg && \
    chown nginx: -R /etc/ingress-controller && \
    chown nginx: -R /var/log/nginx && \
    chown nginx: -R /var/lib/nginx && \
    chown nginx: -R /tmp/nginx && \
    chown nginx: -R /opt/nginx

RUN curl -L "http://openresty.org/download/openresty-${NGINX_VERSION}.tar.gz" | tar -C /opt/nginx --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/luajit2/archive/refs/tags/v2.1-20220915.tar.gz" | tar -C /tmp/luajit2 --strip-components=1 -xz && \
    curl -L "https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.2.tar.gz" | tar -C /tmp/ngx_devel_kit --strip-components=1 -xz && \
    curl -L "https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.20.tar.gz" | tar -C /tmp/lua-nginx-module --strip-components=1 -xz && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIP.dat.gz" | gunzip -c > /etc/nginx/geoip/GeoIP.dat && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIPASNum.dat.gz" | gunzip -c > /etc/nginx/geoip/GeoIPASNum.dat && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.xz" | xz -d > /etc/nginx/geoip/GeoLiteCity.dat && \
    git clone https://baltig.infn.it/cnafsd/ngx_http_voms_module.git /tmp/ngx_http_voms_module && \
    cd /tmp/luajit2 && make && make install && \
    cd /opt/nginx && ./configure \
    --with-ld-opt="-Wl,-lpcre,-rpath,/usr/local/lib/lua/5.1" \
    --add-dynamic-module=/tmp/ngx_devel_kit \
    --add-dynamic-module=/tmp/lua-nginx-module \
    --add-dynamic-module=/tmp/ngx_http_voms_module \
    --with-pcre --with-stream --with-http_ssl_module \
    --with-threads --with-http_geoip_module --with-stream \
    --with-http_v2_module --with-http_stub_status_module \
    --with-stream_ssl_module \
    && \
    make -j2 && make install && \
    ln -s /opt/nginx/lib/lua/ngx /etc/nginx/lua/ngx && \
    ln -s /opt/nginx/lib/lua/resty /etc/nginx/lua/resty && \
    ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx && \
    ln -s /usr/local/nginx/modules/ngx_http_voms_module.so /etc/nginx/modules/ngx_http_voms_module.so && \
    ln -s /usr/local/nginx/modules/ngx_http_lua_module.so /etc/nginx/modules/ngx_http_lua_module.so && \
    ln -s /usr/local/nginx/modules/ndk_http_module.so /etc/nginx/modules/ndk_http_module.so && \
    ln -s /usr/local/nginx/conf /etc/nginx/conf && \
    chown nginx: -R /etc/nginx && \
    chown nginx: -R /usr/local/openresty && \
    setcap cap_net_bind_service=+eip /usr/local/openresty/nginx/sbin/nginx && \
    ln -s /usr/local/lib/libluajit-5.1.so /usr/lib64/libluajit-5.1.so.2 && \
    ln -s /usr/lib64/lua/5.1/cjson.so /usr/local/lib/lua/5.1/cjson.so && \
    rm -rf /tmp/lua* /tmp/ngx* /tmp/stream*

RUN curl -L "http://repository.egi.eu/sw/production/cas/1/current/tgz/" -o index.html && \
    mkdir -p tgz /etc/grid-security/certificates && \
    for tgz in $(cat index.html | awk -F'"' '{print $2}' | grep tar.gz); \
    do curl -L "http://repository.egi.eu/sw/production/cas/1/current/tgz/$tgz" -o tgz/$tgz; \
    done && for tgz in $(ls tgz/); do tar xzf tgz/$tgz --strip-components=1 -C /etc/grid-security/certificates/; \
    done && for f in $(find /etc/grid-security/certificates/ -type f -name "*.pem"); \
    do cat $f >> /etc/ssl/certs/ca-certificates.crt; done && \
    curl -L "https://crt.sh/?d=2475254782" -o /etc/ssl/certs/geant-ov-rsa-ca.crt && \
    cat /etc/ssl/certs/geant-ov-rsa-ca.crt >> /etc/ssl/certs/ca-certificates.crt && rm -rf tgz && \
    mkdir -p /etc/grid-security/vomsdir/juno && \
    mkdir -p /etc/vomses/ && \
    echo '"juno" "lcgvoms02.jinr.ru" "15008" "/C=RU/O=RDIG/OU=hosts/OU=jinr.ru/CN=lcgvoms02.jinr.ru" "juno" "24"' \
    | tee /etc/vomses/juno-lcgvoms02.jinr.ru && \
    echo '"juno" "voms.ihep.ac.cn" "15008" "/C=CN/O=HEP/OU=CC/O=IHEP/CN=voms.ihep.ac.cn" "juno" "24"' \
    | tee /etc/vomses/juno-voms.ihep.ac.cn && \
    echo '"juno" "voms-juno.cloud.cnaf.infn.it" "15008" "/DC=org/DC=terena/DC=tcs/C=IT/ST=Roma/O=Istituto Nazionale di Fisica Nucleare/CN=voms-juno.cloud.cnaf.infn.it" "juno" "24"' \
    | tee /etc/vomses/juno-voms-juno.cloud.cnaf.infn.it && \
    echo $'/C=RU/O=RDIG/OU=hosts/OU=jinr.ru/CN=lcgvoms02.jinr.ru \n\
/C=RU/O=RDIG/CN=Russian Data-Intensive Grid CA' | tee /etc/grid-security/vomsdir/juno/lcgvoms02.jinr.ru.lsc && \
    echo $'/C=CN/O=HEP/OU=CC/O=IHEP/CN=voms.ihep.ac.cn \n\
/C=CN/O=HEP/CN=Institute of High Energy Physics Certification Authority' | tee /etc/grid-security/vomsdir/juno/voms.ihep.ac.cn.lsc && \
    echo $'/DC=org/DC=terena/DC=tcs/C=IT/ST=Roma/O=Istituto Nazionale di Fisica Nucleare/CN=voms-juno.cloud.cnaf.infn.it \n\
/C=NL/O=GEANT Vereniging/CN=GEANT eScience SSL CA 4' | tee /etc/grid-security/vomsdir/juno/voms-juno.cloud.cnaf.infn.it.lsc

CMD ["/nginx-ingress-controller"]

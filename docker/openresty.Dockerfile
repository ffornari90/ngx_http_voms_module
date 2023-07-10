# Copyright 2018-2023 Istituto Nazionale di Fisica Nucleare
# SPDX-License-Identifier: EUPL-1.2

FROM centos:7

ENV DOCKER_IN_DOCKER_ENABLED=true
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/go/bin
ENV LD_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:/usr/local/lib/lua
ENV LUAJIT_LIB=/usr/local/openresty/luajit/lib
ENV LUAJIT_INC=/usr/local/openresty/luajit/include/luajit-2.1
ENV NGINX_VERSION=1.19.9.1
ENV CONTROLLER_VERSION=1.1.2

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
    cd ingress-nginx && git checkout tags/controller-v${CONTROLLER_VERSION} && \
    make build && \
#    sed -i "s/    ajp_temp_path                   \/tmp\/nginx\/ajp-temp;\
#/#    ajp_temp_path                   \/tmp\/nginx\/ajp-temp;/g" \
    sed -i "s/    ajp_temp_path                   \/tmp\/ajp-temp;\
/#    ajp_temp_path                   \/tmp\/ajp-temp;/g" \
    rootfs/etc/nginx/template/nginx.tmpl && \
    sed -i '/    lua_package_path "\/etc\/nginx\/lua\/?.lua;;";/a \ \ \ \ lua_package_cpath "\/usr\/local\/openresty\/lualib\/?.so;;";' \
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
    mkdir -p /tmp/lua-resty-http && \
    mkdir -p /tmp/lua-resty-global-throttle && \
    mkdir -p /tmp/lua-resty-ipmatcher && \
    mkdir -p /tmp/lua-resty-roundrobin && \
    mkdir -p /tmp/lua-resty-cookie && \
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
    curl -L "https://github.com/ledgetech/lua-resty-http/archive/refs/tags/v0.17.1.tar.gz" | tar -C /tmp/lua-resty-http --strip-components=1 -xz && \ 
    curl -L "https://github.com/ElvinEfendi/lua-resty-global-throttle/archive/refs/tags/v0.2.0.tar.gz" | tar -C /tmp/lua-resty-global-throttle --strip-components=1 -xz && \ 
    curl -L "https://github.com/api7/lua-resty-ipmatcher/archive/refs/tags/v0.6.1.tar.gz" | tar -C /tmp/lua-resty-ipmatcher --strip-components=1 -xz && \ 
    curl -L "https://github.com/openresty/lua-resty-balancer/archive/refs/tags/v0.04.tar.gz" | tar -C /tmp/lua-resty-roundrobin --strip-components=1 -xz && \ 
    curl -L "https://github.com/cloudflare/lua-resty-cookie/archive/refs/tags/v0.1.0.tar.gz" | tar -C /tmp/lua-resty-cookie --strip-components=1 -xz && \ 
    curl -L "https://github.com/openresty/stream-lua-nginx-module/archive/refs/tags/v0.0.13.tar.gz" | tar -C /tmp/stream-lua-nginx-module --strip-components=1 -xz && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIP.dat.gz" | gunzip -c > /etc/nginx/geoip/GeoIP.dat && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIPASNum.dat.gz" | gunzip -c > /etc/nginx/geoip/GeoIPASNum.dat && \
    curl -L "https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.xz" | xz -d > /etc/nginx/geoip/GeoLiteCity.dat && \
    git clone https://baltig.infn.it/cnafsd/ngx_http_voms_module.git /tmp/ngx_http_voms_module && \
    cd /opt/nginx && ./configure \
    --add-module=/tmp/ngx_http_voms_module \
    --with-http_iconv_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_geoip_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-http_perl_module \
    --with-pcre --with-stream \
    --with-threads --with-stream_ssl_module && \
    make -j2 && make install && \
    cd /tmp/lua-resty-http && \
    make install PREFIX=/opt/nginx && \
    cd /tmp/lua-resty-global-throttle && \
    make install PREFIX=/opt/nginx && \
    cd /tmp/lua-resty-roundrobin && \
    make && make install && \
    cd /tmp/lua-resty-cookie && \
    make && make install && \
    cd /tmp/lua-resty-ipmatcher && \
    make install && chmod +x resty/ipmatcher.lua && \
    cp resty/ipmatcher.lua /opt/nginx/lib/lua/resty/ && \
    ln -s /usr/local/openresty/lualib/ngx /etc/nginx/lua/ngx && \
    ln -s /usr/local/openresty/lualib/resty /etc/nginx/lua/resty && \
    ln -s /usr/local/openresty/nginx /usr/local/nginx && \
    ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx && \
    ln -s /usr/local/openresty/nginx/conf /etc/nginx/conf && \
    cp /usr/local/openresty/nginx/conf/mime.types /etc/nginx/ && \
    chown nginx: -R /etc/nginx && \
    chown nginx: -R /usr/local/openresty && \
    setcap cap_net_bind_service=+eip /usr/local/openresty/nginx/sbin/nginx && \
    ln -s /usr/local/openresty/luajit/lib/libluajit-5.1.so.2.1.0 /usr/lib64/libluajit-5.1.so.2 && \
    ln -s /usr/local/lib/lua/librestychash.so /usr/local/openresty/lualib/librestychash.so && \
    cp -r /usr/local/openresty/lualib/* /usr/local/openresty/luajit/share/lua/5.1/ && \
    cp -r /opt/nginx/lib/lua/resty/* /etc/nginx/lua/resty/ && \
    cp -r /usr/local/lib/lua/resty/* /etc/nginx/lua/resty/ && \
    rm -rf /tmp/lua* /tmp/ngx*

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
/C=NL/O=GEANT Vereniging/CN=GEANT eScience SSL CA 4' | tee /etc/grid-security/vomsdir/juno/voms-juno.cloud.cnaf.infn.it.lsc && \
    ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    echo "Europe/Rome" > /etc/timezone

CMD ["/nginx-ingress-controller"]

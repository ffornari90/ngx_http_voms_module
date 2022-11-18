%define nginx_user nginx
%define nginx_group nginx
%define base_version 1.22.1
%define bdir %{_builddir}/%{name}-%{base_version}

Name:           nginx-module-http-voms
Version:        1.22.1
Release:        1%{?dist}
Summary:        nginx http voms dynamic modules

License:        EUPL-1.2
URL:            https://github.com/lauracappelli/nginx-sd-rpm

Source0:        https://nginx.org/download/nginx-%{base_version}.tar.gz
Source1:        ngx-http-voms-module
Source2:        echo-nginx-module-0.63

BuildRequires:  gcc, make
BuildRequires:  voms-devel
BuildRequires:  boost-devel
BuildRequires:  openssl-devel
BuildRequires:  zlib-devel
BuildRequires:  pcre2-devel
Requires:       nginx
Requires:       zlib
Requires:       openssl
Requires:       pcre2
Requires:       voms


%description
nginx http voms dynamic modules.


%prep
%setup -qcTn %{name}-%{base_version}
tar --strip-components=1 -zxf %{SOURCE0}

%define CONFIG_PATH %(echo "--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp")
%define CONFIG_ARGS %(echo "--user=nginx --group=nginx --with-compat --with-http_ssl_module")
%define MODULE_CONFIG_ARGS %(echo "--add-dynamic-module=%SOURCE1 --add-dynamic-module=%SOURCE2")


%build
cd %{bdir}
./configure %{CONFIG_PATH} %{CONFIG_ARGS} %{MODULE_CONFIG_ARGS}
make %{?_smp_mflags} modules


%install
cd %{bdir}
%{__rm} -rf $RPM_BUILD_ROOT
%{__mkdir} -p $RPM_BUILD_ROOT%{_libdir}/nginx/modules
for so in `find %{bdir}/objs/ -maxdepth 2 -type f -name "*.so"`; do
%{__install} -m755 $so \
   $RPM_BUILD_ROOT%{_libdir}/nginx/modules/
done


%clean
%{__rm} -rf $RPM_BUILD_ROOT


%files
%{_libdir}/nginx/modules/*


%post
if [ $1 -eq 1 ]; then
cat <<BANNER
----------------------------------------------------------------------

The http voms dynamic modules for nginx have been installed.
To enable these modules, add the following to /etc/nginx/nginx.conf
and reload nginx:

    load_module modules/ngx_http_voms_module.so;
    load_module modules/ngx_http_echo_module.so;

Please refer to the modules documentation for further details:
https://baltig.infn.it/storm2/ngx_http_voms_module

----------------------------------------------------------------------
BANNER
fi


%changelog
* Fri Nov 18 2022 Laura Cappelli
- nginx http voms module updated to 1.22.1-1.0.0
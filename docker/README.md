This folder contains a Dockerfile to run an instance of Openresty/NGINX
compiled and linked against the ngx_voms_http_module.

For more details see the [Dockerfile](./Dockerfile)

The default configuration for NGINX is provided in [this conf file](
./assets/nginx.conf). 

A configuration for the `/srm` endpoint useful for the storm docker compose
file is provided in [this conf file](./assets/srm.conf).

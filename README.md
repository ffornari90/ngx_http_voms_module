# ngx_http_voms_module

## Description

_ngx_http_voms_module_ is a module for the [NGINX web server](https://www.nginx.org/) that enables client-side authentication based on X.509 proxies augmented with Attribute Certificates, typically obtained through a [Virtual Organization Membership Service](https://italiangrid.github.io/voms/) (VOMS).

## Installation

The generic installation instructions are:

    $ cd nginx-1.x.y
    $ ./configure --add-module=/path/to/ngx_http_voms_module
    $ make && make install

A Docker image is available for use in the context of the StoRM2 project, where the OpenResty distribution is used:

    $ docker run --rm -it -v /path/to/ngx_http_voms_module:/home/build/ngx_http_voms_module storm2/ngx-voms-build
    % cd openresty-1.x.y
    % ./configure ${resty_config_options} --add-module=../ngx_http_voms_module
    % make && make install

## Variables

The module makes the following variables available for use in an NGINX configuration file:

### voms_fqans

A comma-separated list of _Fully Qualified Attribute Names_

### voms_user


## Testing

Setup and files to test the *ngx\_http\_voms\_module* are contained in the `t` folder. 

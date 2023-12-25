# `ngx_http_voms_module`

[![pipeline status](https://baltig.infn.it/cnafsd/ngx_http_voms_module/badges/master/pipeline.svg)](https://baltig.infn.it/cnafsd/ngx_http_voms_module/commits/master)

## Description

`ngx_http_voms_module` is a module for the [Nginx web server](https://www.nginx.org/) that enables client-side authentication based on X.509 proxy certificates augmented with VOMS Attribute Certificates, typically obtained from a [Virtual Organization Membership Service](https://italiangrid.github.io/voms/) (VOMS) server.

The module defines a set of *embedded* variables, whose values are extracted from the first Attribute Certificate found in the certificate chain.

### Embedded Variables

The module makes the following embedded variables available for use in an Nginx configuration file:

#### voms_user

The Subject of the End-Entity certificate, used to sign the proxy.

_Example_: ``/C=IT/O=IGI/CN=test0``

#### ssl_client_ee_s_dn

Like `voms_user`, the Subject of the End-Entity certificate. Unlike `voms_user`, it is available even for non-VOMS proxies and is formatted according to RFC 2253.

_Example_: `CN=test0,O=IGI,C=IT`

#### voms_user_ca

The Issuer (Certificate Authority) of the End-Entity certificate.

_Example_: `/C=IT/O=IGI/CN=Test CA`

#### ssl_client_ee_i_dn

Like `voms_user_ca`, the Issuer of the End-Entity certificate. Unlike `voms_user_ca`, it is available even for non-VOMS proxies and is formatted according to RFC 2253.

_Example_: `CN=Test CA,O=IGI,C=IT`

#### voms_fqans

A comma-separated list of Fully Qualified Attribute Names. See [The VOMS Attribute Certificate Format](http://ogf.org/documents/GFD.182.pdf) for more details.

_Example_: `/test.vo/exp1,/test.vo/exp2,/test.vo/exp3/Role=PIPPO`

#### voms_server

The Subject of the VOMS server certificate, used to sign the Attribute Certificate.

_Example_: `/C=IT/O=IGI/CN=voms.example`

#### voms_server_ca

The Issuer (Certificate Authority) of the VOMS server certificate.

_Example_: `/C=IT/O=IGI/CN=Test CA`

#### voms_vo

The name of the Virtual Organization (VO) to which the End Entity belongs.

_Example_: `test.vo`

#### voms_server_uri

The hostname and port of the VOMS network service that issued the Attribute Certificate, in the form _hostname_ :_port_.

_Example_: `voms.example:15000`

#### voms_not_before

The date before which the Attribute Certificate is not yet valid, in the form _YYYYMMDDhhmmss_ `Z`.

_Example_: `20180101000000Z`

#### voms_not_after

The date after which the Attribute Certificate is not valid anymore, in the form _YYYYMMDDhhmmss_ `Z`.

_Example_: `20180101120000Z`

#### voms_generic_attributes

A comma-separated list of attributes, each defined by three properties and formatted as `n=`_name_ `v=`_value_ `q=`_qualifier_. The qualifier typically coincides with the name of the VO.

_Example_: `n=nickname v=newland q=test.vo,n=nickname v=giaco q=test.vo`

#### voms_serial

The serial number of the Attribute Certificate in hexadecimal format.

_Example_: `7B`

## Installation

### prerequisites
The module is written in C++, using features from C++14 that are supported by gcc v. 4.8.5 (the version available in CentOS 7) enabling the option `-std=c++1y` (see [`config.make`](config.make)). 

The software dependecies are listed in the [provide-deps](docker/library-scripts/provide-deps.sh) script in the `docker` directory.

The nginx source files are also needed. To download them in ```/tmp/nginx-x.y.z``` you can execute:

```shell
$ ngxVersion=<version>
$ wget -O /tmp/nginx-$ngxVersion.tar.gz https://nginx.org/download/nginx-$ngxVersion.tar.gz
$ cd /tmp && tar -xzvf /tmp/nginx-$ngxVersion.tar.gz && cd -
```

### Generic installation
The generic installation instructions are:

```shell
$ cd /tmp/nginx-x.y.z
$ ./configure --add-module=/path/to/ngx_http_voms_module
$ make && make install
```

### Docker container

A Docker image with nginx and the `ngx_http_voms_module` is available, you can find it [here](https://hub.docker.com/r/cnafsd/nginx-httpg-voms).

### For the developers
A [.devcontainer](.devcontainer) is provided for the developers with all the instructions on how to use it, how to build the rpm module and how to install it.

## Testing

Setup and files to test the `ngx_http_voms_module` are contained in the [`t`](t) folder.

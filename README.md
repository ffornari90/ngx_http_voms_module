# ngx_http_voms_module

## Description

_ngx_http_voms_module_ is a module for the [Nginx web server](https://www.nginx.org/) that enables client-side authentication based on X.509 proxy certificates augmented with VOMS Attribute Certificates, typically obtained from a [Virtual Organization Membership Service](https://italiangrid.github.io/voms/) (VOMS) server.

The module defines a set of [_embedded_ variables](~embedded-variables), whose values are extracted from the first Attribute Certificate found in the certificate chain.

## Installation

The generic installation instructions are:

    $ cd nginx-1.x.y
    $ ./configure --add-module=/path/to/ngx_http_voms_module
    $ make && make install

A Docker image is available for use in the context of the StoRM2 project, where the OpenResty distribution is used:

    $ docker run --rm -it -v /path/to/ngx_http_voms_module:/home/build/ngx_http_voms_module storm2/ngx-voms-build
    % cd openresty-1.x.y
    % ./configure ${RESTY_CONFIG_OPTIONS} --add-module=../ngx_http_voms_module
    % make && make install

## Embedded Variables

The module makes the following embedded variables available for use in an Nginx configuration file:

### voms_user

The Subject of the End-Entity certificate, used to sign the proxy.

_Example_: ``/C=IT/O=IGI/CN=test0``

### voms_user_ca

The Issuer (Certificate Authority) of the End-Entity certificate.

_Example_: ``/C=IT/O=IGI/CN=Test CA``

### voms_fqans

A comma-separated list of Fully Qualified Attribute Names. See [The VOMS Attribute Certificate Format](http://ogf.org/documents/GFD.182.pdf) for more details.

_Example_: ``/test/exp1,/test/exp2,/test/exp3/Role=PIPPO``

### voms_server

The Subject of the VOMS server certificate, used to sign the Attribute Certificate.

_Example_: ``/C=IT/O=IGI/CN=voms.example``

### voms_server_ca

The Issuer (Certificate Authority) of the VOMS server certificate.

_Example_: ``/C=IT/O=IGI/CN=Test CA``

### voms_vo

The name of the Virtual Organization (VO) to which the End Entity belongs.

_Example_: ``test.vo``

### voms_server_uri

The hostname and port of the VOMS network service that issued the Attribute Certificate, in the form _hostname_ :_port_.

_Example_: ``voms.example:15000``

### voms_not_before

The date before which the Attribute Certificate is not yet valid, in the form _YYYYMMDDhhmmss_ ``Z``.

_Example_: ``20180101000000Z``

### voms_not_after

The date after which the Attribute Certificate is not valid anymore, in the form _YYYYMMDDhhmmss_ ``Z``.

_Example_: ``20180101120000Z``

### voms_generic_attributes

A comma-separated list of attributes, each defined by three properties and formatted as ``n=``_name_ ``v=``_value_ ``q=``_qualifier_. The qualifier typically coincides with the name of the VO.

_Example_: ``n=nickname v=newland q=test.vo,n=nickname v=giaco q=test.vo``

### voms_serial

The serial number of the Attribute Certificate in hexadecimal format.

_Example_: ``7B``

## Testing

Setup and files to test the *ngx\_http\_voms\_module* are contained in the `t` folder. 

# `ngx_http_voms_module` Testing 

## Description

Setup and files to test the *ngx_http_voms_module* are contained in the `t` folder. The [Openresty data-driven testsuite](https://openresty.gitbooks.io/programming-openresty/content/testing/) has been adopted for testing.

### Test fixture setup 

All the certificates and proxy certificates used in the tests are in the [`certs`](certs) folder (see that [README](certs/README.md) for further details), while trust-anchors (e.g. igi-test-ca.pem) are in the [`trust-anchors`](trust-anchors) folder.

`vomses` is the _vomses_ file needed for the generation of proxy certificates.

The LSC file `voms.example.lsc`, needed to perform correctly the VOMS AC validation, is in the [`vomsdir/test.vo`](vomsdir/test.vo) folder.

### Running Tests

To run the tests made available in `t` just type

```shell
$ prove -v 
```

from `t`' s parent directory.

The `prove` command creates a directory called `servroot` in `t`, so if the `t` folder is accessible read-only, for
example in a docker container, just make a copy somewhere else and run the tests from there:

```
cp -r t /tmp
cd /tmp
prove -v
```

### Testing directly the Nginx server

You can reuse the config file `t/servroot/conf/nginx.conf` produced by `test::Nginx`, which contains something like

```
server {
    listen 8443 ssl;
    server_name     nginx-voms.example;
    ssl_certificate ../../certs/nginx_voms_example.cert.pem;
    ssl_certificate_key ./certs/nginx_voms_example.key.pem;
    ssl_client_certificate ./trust-anchors/igi-test-ca.pem;
    ssl_verify_depth 10;
    ssl_verify_client on;
    location = / {
        echo user: $voms_user;
    }
}
```

You may want to change the configuration so that the log goes to standard output instead of to a log file:

```
server {
    error_log /dev/stdout debug;
    ...
```

Start nginx:

```shell
$ nginx -p t/servroot
```

Modify (as root) `/etc/hosts` so that `nginx-voms.example` is an alias for `localhost`:

```
127.0.0.1	localhost nginx-voms.example
```

Then run for example `curl`, calling directly the HTTPS endpoint:

```shell
$ curl https://nginx-voms.example:8443 --cert t/certs/3.pem --capath t/trust-anchors --cacert t/certs/3.cert.pem
```

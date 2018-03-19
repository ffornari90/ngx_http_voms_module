# ngx\_http\_voms\_module Testing 

## Description

Setup and files to test the *ngx\_http\_voms\_module* are contained in the `t` folder. The [Openresty data-driven testsuite](https://openresty.gitbooks.io/programming-openresty/content/testing/) has been adopted for testing.

### Test fixture setup 

Proxy certificates are in the `certs` folder (see [README.md](certs/README.md) for further details), while trust-anchors (e.g. igi-test-ca.pem) are contained in `trust-anchors`. 

Nginx server certificate and key are nginx\_voms\_example.cert.pem and nginx\_voms\_example\_key.pem, respectively, and they are contained in `certs`.

To perform correctly the VOMS AC validation, a \*.lsc or \*.pem file is needed, see [VOMS client 3.3.0 User Guide](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/) for further details. The *voms.example.lsc* can be found in `vomsdir/test.vo`.

### Running Tests

To run the tests made available in `t` just type

	prove -v 

from `t`' s parent directory.

Using the docker image provided to exploit Openresty in the Storm2 project (see [README.md](../README.md) for further details):

    cp -r t /tmp
    cd /tmp
    prove -v

A copy of the `t` folder is needed since the `prove` command creates a directory `servroot` in `t`.  

### Test coverage

To enable test coverage pass the `--coverage` option to both the compiler and the linker. For example, if the build happens inside the ``storm2/nginx-voms-build`` image:

```
    % ./configure ${resty_config_options} --add-module=../ngx_http_voms_module --with-debug --with-cc-opt="-g -O0 --coverage" --with-ld-opt="--coverage"
    % make && make install
```

Building in debug mode, with no optimizations, helps to better associate coverage information to source code.

The above command generates data files aside the source files for all Nginx. To enable coverage only for ``ngx_http_voms_module`` the ``--coverage`` option should be passed only when compiling ``ngx_http_voms_module.cpp`` (to be done).

The run the tests, e.g. with `prove`. This will create other data files with coverage information. To view that information, run `gcov <source of object file>`, e.g. `gcov /home/build/openresty-1.13.6.1/build/nginx-1.13.6/objs/addon/src/ngx_http_voms_module.o`. This will produce files with the ``.gcov`` extension in the current directory.


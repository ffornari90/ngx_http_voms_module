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

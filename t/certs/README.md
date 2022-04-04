# Certificates for `ngx_http_voms_module` testing 

This directory contains the certificates and the proxy certificates used in the unit tests of the `ngx_http_voms_module`.

The proxy certificates are generated using the [VOMS
clients](http://italiangrid.github.io/voms/documentation/voms-clients-guide/), using the following command template:

```shell
$ VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=<path_to_cert>/voms_example.cert.pem -Dvoms.fake.aaKey=<path_to_cert>/voms_example.key.pem -Dvoms.fake.notAfter=<AAAA-MM-GGT00:00:00 -Dvoms.fake.notBefore=AAAA-MM-GGT00:00:00 -Dvoms.fake.gas=<name>=<value>,<name>=<value> -Dvoms.fake.fqans=/<vo>/<fqan>,/<vo>/<fqan>/Role=<role> -Dvoms.fake.serial=<ac_serial_n>" voms-proxy-init -voms test.vo -cert <path_to test0.p12> --valid <validity> --vomsdir <path_to_vomsdir> --certdir <path_to_trust_anchors>
```

See below for some concrete examples.

As usual, the command generates a proxy certificate in `/tmp` in PEM format. To be used in these tests, they need to be
split in the corresponding certificate and key and eventually moved into this directory. Given a `name.pem` file,
`name.cert.pem` and `name.key.pem` can be obtained using the following commands:

```shell
$ awk '/BEGIN RSA PRIVATE KEY/,/END RSA PRIVATE KEY/' name.pem > name.key.pem
$ awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' name.pem > name.cert.pem
```

The following certificates and proxy certificates are used in these tests:

 * `0.pem`: long-lived proxy certificate, without any Attribute Certificate (AC)
 * `1.pem`: long-lived proxy certificate, with an expired AC
 * `2.pem`: expired proxy certificate
 * `3.pem`: long-lived proxy with valid VOMS attributes. Obtained with:

```shell
$ VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=t/certs/voms_example.cert.pem -Dvoms.fake.aaKey=t/certs/voms_example.key.pem -Dvoms.fake.notAfter=2031-12-31T00:00:00 -Dvoms.fake.notBefore=2021-11-10T00:00:00 -Dvoms.fake.gas=nickname=newland,nickname=giaco -Dvoms.fake.fqans=/test.vo/exp1,/test.vo/exp2,/test.vo/exp3/Role=PIPPO -Dvoms.fake.serial=123456" voms-proxy-init -voms test.vo -cert t/certs/test0.p12 --valid 10000:0 --vomsdir t/vomsdir --certdir t/trust-anchors --vomses t/vomses
```

 * `4.pem`: long-lived proxy with VOMS generic attributes containing special characters. Obtained with:

```shell
$ VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=t/certs/voms_example.cert.pem -Dvoms.fake.aaKey=t/certs/voms_example.key.pem -Dvoms.fake.notAfter=2031-12-31T00:00:00 -Dvoms.fake.notBefore=2021-11-10T00:00:00 -Dvoms.fake.fqans=/test.vo -Dvoms.fake.gas=nickname=newland86,title=assegnista%di%ricerca@CNAF -Dvoms.fake.serial=123457" voms-proxy-init -voms test.vo -cert t/certs/test0.p12 --valid 10000:0 --vomsdir t/vomsdir --certdir t/trust-anchors --vomses t/vomses
```

 * `5.pem`: long-lived proxy with valid VOMS attributes
 * `6.pem`: long-lived proxy with valid VOMS attributes, with an old format for FQANs 
 * `7.pem`: long-lived proxy (3 delegations), without VOMS attributes
 * `8.pem`: long-lived proxy (3 delegations), without VOMS attributes, plus a CA
   certificate included in the chain
 * `9.pem`: EEC plus CA certificate included in the chain

`voms_example.cert.pem` and `voms_example.key.pem` are the credentials of a trusted VOMS server.

`voms_example_2.cert.pem` and `voms_example_2.key.pem` are the credentials of an untrusted VOMS server. 

`nginx_voms_example.cert.pem` and `nginx_voms_example.key.pem` are the Nginx server credentials.

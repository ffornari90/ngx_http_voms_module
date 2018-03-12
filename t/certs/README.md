=======
# Certificates for ngx\_http\_voms\_module Testing 

Proxy certificates are generated using [VOMS client 3.3.0](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/):

 * 0.pem: long-lived proxy certificate, without Attribute Certificate (AC);
 * 1.pem: long-lived proxy certificate, with an expired AC;
 * 2.pem: expired proxy certificate.

To obtain such certificates the following command is used:

	VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=<path_to_cert>/voms_example.cert.pem -Dvoms.fake.aaKey=<path_to_key>/voms_example.key.pem" voms-proxy-init3 -voms test.vo -cert <path_to_test0>/test0.p12 --valid <validity>

*voms\_example.cert.pem* and *voms\_example.ket.pem* can be found in the `certs` folder. 

To perform correctly the VOMS AC validation, a \*.lsc or \*.pem file is needed in `/etc/grid-security/vomsdir`, see [VOMS client 3.3.0 User Guide](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/) for further details. An example of *voms.example.lsc* can be found in `vomsdir/test.vo`.

Nginx server certificate and key  are nginx\_voms\_example.cert.pem and nginx\_voms\_example\_key.pem.

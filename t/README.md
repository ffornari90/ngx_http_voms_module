# ngx\_http\_voms\_module Testing 

## Description

Setup and files to test the *ngx\_http\_voms\_module* are contained in the **t** folder. The [Openresty data-driven testsuite](https://openresty.gitbooks.io/programming-openresty/content/testing/) has been adopted for testing.

### Test fixture setup 

Proxy certificates are in the **certs** folder:

 * 0.pem: long-lived proxy, no AC;
 * 1.pem: long-lived proxy, expired AC;
 * 2.pem: expired proxy certificate.

Proxy certificates are generated using [VOMS client 3.3.0](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/). 

The following options are used:

	VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=<path_to_cert>/voms_example.cert.pem -Dvoms.fake.aaKey=<path_to_key>/voms_example.key.pem" voms-proxy-init3 -voms test.vo -cert <path_to_test0>/test0.p12 --valid <validity>

*voms\_example.cert.pem* and *voms\_example.ket.pem* can be found in the **certs** folder. 

To perform correctly the VOMS AC validation, a \*.lsc or \*.pem file is needed in **/etc/grid-security/vomsdir**, see [VOMS client 3.3.0 User Guide](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/) for further details. An example of *voms.example.lsc* can be found in **vomsdir/test.vo**.

Trust-anchors (igi-test-ca.pem) are contained in the **trust-anchors** folder. Nginx server certificate and key (nginx\_voms\_example.cert.pem and nginx\_voms\_example\_key.pem) are in the **certs** folder.

### Running Tests

To run the tests made available in the **t** folder just type

	prove -v t


Using the docker image provided to exploit Openresty in the Storm2 project:

	docker run --rm -it -v /path/to/ngx_http_voms_module:/home/build/ngx_http_voms_module storm2/ngx-voms-build
	cd openresty-1.x.y
	./configure ${resty_config_options} --add-module=../ngx_http_voms_module
	make && make install
	cd ..
	sudo chown build.build -R t
	prove -v t

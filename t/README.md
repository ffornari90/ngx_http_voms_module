# ngx\_http\_voms\_module Testing 

## Description

Setup and files to test the *ngx\_http\_voms\_module* are contained in the **t** folder. The [Openresty data-driven testsuite](https://openresty.gitbooks.io/programming-openresty/content/testing/) has been adopted for testing.

### Voms proxy certificates 

Proxy certificates are in the **certs** folder:

 * 0.pem: long-lived proxy, no AC;
 * 1.pem: long-lived proxy, expired AC;
 * 2.pem: expired proxy certificate.

Proxy certificates are generated using [VOMS client 3.3.0](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/). 

The following options are evoked:

	VOMS_CLIENTS_JAVA_OPTIONS="-Dvoms.fake.vo=test.vo -Dvoms.fake=true -Dvoms.fake.aaCert=<path_to_cert>/voms_example.cert.pem -Dvoms.fake.aaKey=<path_to_key>/voms_example.key.pem" voms-proxy-init3 -voms test.vo -cert <path_to_test0>/test0.p12 --valid <validity>

*voms\_example.cert.pem* and *voms\_example.ket.pem* can be found in the **certs** folder. 

To perform correctly the VOMS server connection, an *.lsc or *.pem file is needed in **/etc/grid-security/vomsdir**, see [VOMS client 3.3.0 User Guide](http://italiangrid.github.io/voms/documentation/voms-clients-guide/3.0.3/) for further details. An example of *voms.example.lsc* can be found in **vomsdir/test.vo**.

The *vomses* configuration is not actually needed for *voms-proxy-fake* evocations.

### Test Description

  * *empty\_voms\_proxy.t*: 
    
    **Input ->** 0.pem certificate and key. 
    
    **Expected output ->** 200-error-code, empty voms variables. 
    
    **Error log ->** "VOMS extension not found".
   
  * *expired\_ac\_proxy.t*: 

    **Input ->** 1.pem certificate and key. 

    **Expected output ->** 200-error-code, empty voms variables. 

    **Error log ->** "AC not valid anymore".

  * *expired\_proxy.t*: 
   
    **Input ->** 2.pem certificate and key. 
   
    **Expected output ->** 400-error-code, empty nginx variables.

    ** Error log ->** "certificate has expired".
 
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

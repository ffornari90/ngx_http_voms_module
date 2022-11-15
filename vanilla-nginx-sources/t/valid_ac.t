
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: valid AC, verification of valid VOMS attributes extracted by ngx_http_voms_module
--- main_config
    load_module /etc/nginx/modules/ngx_http_echo_module.so;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
--- http_config
    server {
        error_log logs/error.log debug;
        listen 8443 ssl;
        ssl_certificate ../../certs/nginx_voms_example.cert.pem;
        ssl_certificate_key ../../certs/nginx_voms_example.key.pem;
        ssl_client_certificate ../../trust-anchors/igi-test-ca.pem;
        ssl_verify_depth 10;
        ssl_verify_client on;
	location = / {
            default_type text/plain;
            echo $voms_user; 
            echo $voms_user_ca;
            echo $voms_fqans;
            echo $voms_server; 
            echo $voms_server_ca;
            echo $voms_vo; 
            echo $voms_server_uri;
            echo $voms_not_before;
            echo $voms_not_after;
            echo $voms_generic_attributes;
            echo $voms_serial;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/3.cert.pem;
        proxy_ssl_certificate_key ../../certs/3.key.pem;
    }
--- request
GET / 
--- response_body
/C=IT/O=IGI/CN=test0
/C=IT/O=IGI/CN=Test CA
/test.vo/exp1,/test.vo/exp2,/test.vo/exp3/Role=PIPPO
/C=IT/O=IGI/CN=voms.example
/C=IT/O=IGI/CN=Test CA
test.vo
voms.example:15000
20211110000000Z
20311231000000Z
n=nickname v=newland q=test.vo,n=nickname v=giaco q=test.vo
01E240
--- error_code: 200


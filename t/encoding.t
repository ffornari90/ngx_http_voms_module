
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: valid AC, verification of VOMS generic attributes encoding
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
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
            return 200 "$voms_generic_attributes\n";
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/4.cert.pem;
        proxy_ssl_certificate_key ../../certs/4.key.pem;
    }
--- request
GET / 
--- response_body
n=nickname v=newland86 q=test.vo,n=title v=assegnista%25di%25ricerca%40CNAF q=test.vo
--- error_code: 200

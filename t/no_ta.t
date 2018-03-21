
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: Valid proxy, wrong client certificate trust-anchor 
--- main_config
    env OPENSSL_ALLOW_PROXY_CERTS=1;
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
--- http_config
    server {
        error_log logs/error.log debug;
        listen 8443 ssl;
        ssl_certificate ../../certs/nginx_voms_example.cert.pem;
        ssl_certificate_key ../../certs/nginx_voms_example.key.pem;
        ssl_client_certificate ../../trust-anchors/igi-test-ca-2.pem;
        ssl_verify_depth 10;
        ssl_verify_client on;
	location = / {
            default_type text/plain;
            echo $voms_fqans;
        }
    }
--- config
    location = / {
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/3.cert.pem;
        proxy_ssl_certificate_key ../../certs/3.key.pem;
    }
--- request
GET / 
--- error_code: 400

=== TEST 2: Valid proxy, wrong VOMS trust-anchor 
--- main_config
    env OPENSSL_ALLOW_PROXY_CERTS=1;
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/test-trust-anchors;
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
            echo $voms_fqans; 
       }
    }
--- config
    location = / {
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/3.cert.pem;
        proxy_ssl_certificate_key ../../certs/3.key.pem;
    }
--- request
GET /
--- error_log
Cannot verify AC signature
--- error_code: 200




use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: https with x509 client authentication, valid proxy certificate expired voms attributes 
--- main_config
    env OPENSSL_ALLOW_PROXY_CERTS=1; 
    env X509_VOMS_DIR=t/vomsdir;
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
            echo $voms_fqans $voms_user;
        }
    }
--- config
    location = / {
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/1.cert.pem;
        proxy_ssl_certificate_key ../../certs/1.key.pem;
    }
--- request
GET / 
--- response_body_like eval
qr/\n/
--- error_log
AC not valid anymore
--- error_code: 200

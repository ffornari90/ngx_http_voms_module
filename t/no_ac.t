
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: https with x509 client authentication, valid proxy certificate with no VOMS attributes 
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
--- http_config
    server {
        error_log logs/error.log debug;
        listen 8443 ssl;
        ssl_certificate ../../certs/star.test.example.cert.pem;
        ssl_certificate_key ../../certs/star.test.example.key.pem;
        ssl_client_certificate ../../trust-anchors/igi-test-ca.pem;
        ssl_verify_depth 10;
        ssl_verify_client on;
	location = / {
            default_type text/plain;
            return 200 "$voms_fqans\n$voms_user\n";
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/0.cert.pem;
        proxy_ssl_certificate_key ../../certs/0.key.pem;
    }
--- request
GET / 
--- response_body_like eval
qr/\n\n/
--- error_log
VOMS extension not found
--- error_code: 200

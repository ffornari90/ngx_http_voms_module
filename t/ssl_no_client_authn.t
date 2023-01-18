
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: HTTPS with no X.509 client authentication
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
	location = / {
            default_type text/plain;
            return 200 "$voms_user\n";
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
    }
--- request
GET / 
--- response_body_like eval
qr/\n/
--- error_log
no SSL peer certificate available
--- error_code: 200

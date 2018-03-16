
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: HTTPS with no X.509 client authentication
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
	location = / {
            default_type text/plain;
            echo $voms_user;
        }
    }
--- config
    location = / {
        proxy_pass https://localhost:8443/;
    }
--- request
GET / 
--- response_body_like eval
qr/\n/
--- error_log
no SSL peer certificate available
--- error_code: 200

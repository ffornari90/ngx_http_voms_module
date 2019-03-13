
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: https with x509 client authentication, expired client certificate
--- main_config
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
            echo $ssl_client_s_dn;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/2.cert.pem;
        proxy_ssl_certificate_key ../../certs/2.key.pem;
    }
--- request
GET /
--- response_body_like eval
qr/\n/ 
--- error_log 
certificate has expired
--- error_code: 400

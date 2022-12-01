use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: three delegations proxy + CA cert
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
            return 200 "$ssl_client_ee_s_dn\n$ssl_client_ee_i_dn\n"; 
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/8.cert.pem;
        proxy_ssl_certificate_key ../../certs/8.key.pem;
    }
--- request
GET / 
--- response_body
CN=test0,O=IGI,C=IT
CN=Test CA,O=IGI,C=IT
--- error_code: 200

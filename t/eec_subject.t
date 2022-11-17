use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: rfc proxy certificate, no AC
--- main_config
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
            echo $ssl_client_ee_s_dn;
            echo $ssl_client_ee_i_dn;
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
--- response_body
CN=test0,O=IGI,C=IT
CN=Test CA,O=IGI,C=IT
--- error_code: 200

=== TEST 2: standard x.509 certificate 
--- main_config
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
            echo $ssl_client_ee_s_dn;
            echo $ssl_client_s_dn;
            echo $ssl_client_ee_i_dn;
            echo $ssl_client_i_dn;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/nginx_voms_example.cert.pem;
        proxy_ssl_certificate_key ../../certs/nginx_voms_example.key.pem;
    }
--- request
GET / 
--- response_body
CN=nginx-voms.example,O=IGI,C=IT
CN=nginx-voms.example,O=IGI,C=IT
CN=Test CA,O=IGI,C=IT
CN=Test CA,O=IGI,C=IT
--- error_code: 200

=== TEST 3: three delegations proxy
--- main_config
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
            echo $ssl_client_ee_s_dn;
            echo $ssl_client_ee_i_dn;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/7.cert.pem;
        proxy_ssl_certificate_key ../../certs/7.key.pem;
    }
--- request
GET / 
--- response_body
CN=test0,O=IGI,C=IT
CN=Test CA,O=IGI,C=IT
--- error_code: 200


=== TEST 4: three delegations proxy + CA cert
--- main_config
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
            echo $ssl_client_ee_s_dn;
            echo $ssl_client_ee_i_dn;
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

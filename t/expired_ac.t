
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: https with x509 client authentication, valid proxy certificate with expired VOMS attributes 
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
--- http_config
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;
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
        proxy_ssl_certificate ../../certs/1.cert.pem;
        proxy_ssl_certificate_key ../../certs/1.key.pem;
    }
--- request
GET / 
--- response_body_like eval
qr/\n\n/
--- error_log
AC not valid anymore
--- error_code: 200


use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: valid AC, verification of valid VOMS attributes extracted by ngx_http_voms_module
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
            return 200 "$voms_user\n$voms_user_ca\n$voms_fqans\n$voms_server\n$voms_server_ca\n$voms_vo\n$voms_server_uri\n$voms_not_before\n$voms_not_after\n$voms_generic_attributes\n$voms_serial\n";
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443/;
        proxy_ssl_certificate ../../certs/3.cert.pem;
        proxy_ssl_certificate_key ../../certs/3.key.pem;
    }
--- request
GET / 
--- response_body
/C=IT/O=IGI/CN=test0
/C=IT/O=IGI/CN=Test CA
/test.vo/exp1,/test.vo/exp2,/test.vo/exp3/Role=PIPPO
/C=IT/O=IGI/CN=*.test.example
/C=IT/O=IGI/CN=Test CA
test.vo
voms.example:15000
20221210000000Z
20311231000000Z
n=nickname v=sd q=test.vo,n=nickname v=cnaf q=test.vo
01E240
--- error_code: 200


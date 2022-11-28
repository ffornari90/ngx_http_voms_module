
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: HTTP connection, no SSL
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
    load_module /etc/nginx/modules/ngx_http_echo_module.so;
--- http_config
    server {
        error_log logs/error.log debug;
        listen 8443;
        location = / {
            default_type text/plain;
            echo $voms_user;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass http://localhost:8443/;
    }
--- request
GET / 
--- response_body_like eval
qr/\n/
--- error_log
SSL not enabled
--- error_code: 200

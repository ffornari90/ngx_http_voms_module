
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: HTTP connection, no SSL
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
--- http_config
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;
    server {
        error_log logs/error.log debug;
        listen 8443;
        location = / {
            default_type text/plain;
            return 200 "$voms_user\n";
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

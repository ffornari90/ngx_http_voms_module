
use Test::Nginx::Socket 'no_plan';

master_on();

run_tests();

__DATA__

=== TEST 1: SSL server, logging a VOMS variabile, but plain HTTP request
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
    load_module /etc/nginx/modules/ngx_http_js_module.so;
    load_module /etc/nginx/modules/ngx_http_echo_module.so;
--- http_config
    js_path "/home/nginx/t";
    js_import socket.js;
    log_format voms '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '[$voms_user]';
    server {
        error_log logs/error.log debug;
        access_log logs/access.log voms;
        listen 8443 ssl;
        ssl_certificate ../../certs/nginx_voms_example.cert.pem;
        ssl_certificate_key ../../certs/nginx_voms_example.key.pem;
        ssl_client_certificate ../../trust-anchors/igi-test-ca.pem;
        ssl_verify_depth 10;
	    location = / {
            default_type text/plain;
            # echo $voms_user;
            return 200 "$voms_user\n";
        }
    }
--- config
    location = /njs {
        error_log logs/error-proxy.log debug;
        access_log logs/access-proxy.log;
        js_content socket.connect;   
    }
--- request
GET /njs
--- error_log
client prematurely closed connection
retrieve_voms_ac_from_proxy
plain HTTP
--- error_code: 200

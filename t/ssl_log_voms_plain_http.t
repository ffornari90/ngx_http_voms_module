
# This test is always successful because, for some reason (a bug?)
# the error.log as seen in Test::Nginx doesn't contain the entries for
# the master process, although they are evailable in the actual file.
# As a consequence the no_error_log check is always satisfied,
# even if the segmentation fault were present

use Test::Nginx::Socket 'no_plan';

master_on();

run_tests();

__DATA__

=== TEST 1: SSL server, logging a VOMS variabile, but plain HTTP request
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
--- http_config
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
            echo $voms_user;
        }
    }
--- config
    location = /lua {
        error_log logs/error-proxy.log debug;
        access_log logs/access-proxy.log;
        content_by_lua_block {
            local sock = ngx.socket.tcp()
            local ok, err = sock:connect("127.0.0.1", 8443)
            if not ok then
                ngx.say("failed to connect to upstream: ", err)
                return
            end
            ngx.say("successfully connected to upstream!")
            sock:send("G")
            sock:close()
        }
    }
--- request
GET /lua
--- error_log
client prematurely closed connection
retrieve_voms_ac_from_proxy
plain http
--- no_error_log
signal 11
--- error_code: 200

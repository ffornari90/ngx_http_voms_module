
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: HTTP connection, no SSL
--- main_config
    env OPENSSL_ALLOW_PROXY_CERTS=1; 
    env X509_VOMS_DIR=t/vomsdir;
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

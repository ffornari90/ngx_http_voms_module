use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: valid AC, verification of valid VOMS attributes extracted by ngx_http_voms_module
--- main_config
    env X509_VOMS_DIR=t/vomsdir;
    env X509_CERT_DIR=t/trust-anchors;
    load_module /etc/nginx/modules/ngx_http_voms_module.so;
    load_module /etc/nginx/modules/ngx_http_echo_module.so;
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
            auth_request /authz;

            default_type text/plain;
            # auth_request_set $pippo $some_var;
            # echo $http_pluto;
            echo $some_var;
            # echo $pippo;
            # return 200 "$pippo\n";
        }
        location = /authz {
            internal;
            set $some_var $voms_user;
            proxy_set_header pluto $voms_user;
            return 200;
        }
    }
--- config
    location = / {
        error_log logs/error-proxy.log debug;
        proxy_pass https://localhost:8443;
        proxy_ssl_certificate ../../certs/3.cert.pem;
        proxy_ssl_certificate_key ../../certs/3.key.pem;
    }
--- request
GET / 
--- response_body
/C=IT/O=IGI/CN=test0
--- error_code: 200

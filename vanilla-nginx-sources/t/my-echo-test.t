use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: hello, world
This is just a simple demonstration of the echo directive provided by ngx_http_echo_module.

--- main_config
load_module /etc/nginx/modules/ngx_http_echo_module.so;

--- config
location = /hello {
    echo "hello, world!";
}

--- request
GET /hello

--- response_body
hello, world!
--- error_code: 200
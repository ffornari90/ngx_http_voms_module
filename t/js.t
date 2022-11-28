
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: hello world
--- main_config
load_module /etc/nginx/modules/ngx_http_js_module.so;
load_module /etc/nginx/modules/ngx_stream_js_module.so;

--- http_config
js_path "/home/nginx/t";
js_import main from test-voms.js;

--- config
location = /hello {
    js_content main.hello;
}

--- request
GET /hello

--- response_body
Hello world!

=== TEST 2: check njs version
--- main_config
load_module /etc/nginx/modules/ngx_http_js_module.so;
load_module /etc/nginx/modules/ngx_stream_js_module.so;

--- http_config
js_path "/home/nginx/t";
js_import test-voms.js;

--- config
location = /version {
    js_content testVoms.version;
}

location = /hello {
    js_content testVoms.hello;
}

--- request
GET /version

--- response_body
0.7.9
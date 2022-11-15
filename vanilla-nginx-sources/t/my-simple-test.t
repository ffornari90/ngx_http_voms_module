
use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: hello world

--- config
location = /hello {
    return 200 "hello world\n";
}

--- request
GET /hello

--- response_body
hello world

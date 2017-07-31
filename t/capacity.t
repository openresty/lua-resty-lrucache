# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
    lua_package_path "$pwd/lib/?.lua;;";
_EOC_

no_long_string();
run_tests();

__DATA__

=== TEST 1: capacity() returns total cache capacity
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(2)

            ngx.say("capacity: ", c:capacity())
        }
    }
--- request
GET /t
--- response_body
capacity: 2
--- no_error_log
[error]

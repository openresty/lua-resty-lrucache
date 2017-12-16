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

=== TEST 1: get_keys() with some keys
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(100)

            c:set("hello", true)
            c:set("world", false)

            local keys = c:get_keys()

            ngx.say("size: ", #keys)

            for i = 1, #keys do
                ngx.say(keys[i])
            end
        }
    }
--- request
GET /t
--- response_body
size: 2
world
hello
--- no_error_log
[error]



=== TEST 2: get_keys() with no keys
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(100)

            local keys = c:get_keys()

            ngx.say("size: ", #keys)

            for i = 1, #keys do
                ngx.say(keys[i])
            end
        }
    }
--- request
GET /t
--- response_body
size: 0
--- no_error_log
[error]



=== TEST 3: get_keys() with full cache
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(100)

            for i = 1, 100 do
                c:set("key-" .. i, true)
            end

            c:set("extra-key", true)

            local keys = c:get_keys()

            ngx.say("size: ", #keys)
            ngx.say("MRU: ", keys[1])
            ngx.say("LRU: ", keys[#keys])
        }
    }
--- request
GET /t
--- response_body
size: 100
MRU: extra-key
LRU: key-2
--- no_error_log
[error]



=== TEST 4: get_keys() max_count = 5
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(100)

            for i = 1, 100 do
                c:set("key-" .. i, true)
            end

            local keys = c:get_keys(5)

            ngx.say("size: ", #keys)
            ngx.say("MRU: ", keys[1])
            ngx.say("latest: ", keys[#keys])
        }
    }
--- request
GET /t
--- response_body
size: 5
MRU: key-100
latest: key-96
--- no_error_log
[error]



=== TEST 5: get_keys() max_count = 0 disables max returns
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(100)

            for i = 1, 100 do
                c:set("key-" .. i, true)
            end

            local keys = c:get_keys(0)

            ngx.say("size: ", #keys)
            ngx.say("MRU: ", keys[1])
            ngx.say("LRU: ", keys[#keys])
        }
    }
--- request
GET /t
--- response_body
size: 100
MRU: key-100
LRU: key-1
--- no_error_log
[error]



=== TEST 6: get_keys() user-fed res table
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c1 = lrucache.new(3)
            local c2 = lrucache.new(2)

            for i = 1, 3 do
                c1:set("c1-" .. i, true)
            end

            for i = 1, 2 do
                c2:set("c2-" .. i, true)
            end

            local res = {}

            local keys_1 = c1:get_keys(0, res)
            ngx.say("res is user-fed: ", keys_1 == res)

            for _, k in ipairs(keys_1) do
                ngx.say(k)
            end

            res = {}

            local keys_2 = c2:get_keys(0, res)

            for _, k in ipairs(keys_2) do
                ngx.say(k)
            end
        }
    }
--- request
GET /t
--- response_body
res is user-fed: true
c1-3
c1-2
c1-1
c2-2
c2-1
--- no_error_log
[error]



=== TEST 7: get_keys() user-fed res table + max_count
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c1 = lrucache.new(3)

            for i = 1, 3 do
                c1:set("key-" .. i, true)
            end

            local res = {}

            local keys = c1:get_keys(2, res)

            for _, k in ipairs(keys) do
                ngx.say(k)
            end
        }
    }
--- request
GET /t
--- response_body
key-3
key-2
--- no_error_log
[error]



=== TEST 8: get_keys() user-fed res table gets a trailing hole
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache.pureffi"
            local c1 = lrucache.new(3)

            for i = 1, 3 do
                c1:set("key-" .. i, true)
            end

            local res = {}

            for i = 1, 10 do
                res[i] = true
            end

            local keys = c1:get_keys(2, res)

            for _, k in ipairs(keys) do
                ngx.say(k)
            end
        }
    }
--- request
GET /t
--- response_body
key-3
key-2
--- no_error_log
[error]

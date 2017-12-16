# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

#no_diff();
#no_long_string();

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
    lua_package_path "$pwd/lib/?.lua;$pwd/../lua-resty-core/lib/?.lua;;";
    #init_by_lua '
    #local v = require "jit.v"
    #v.on("$Test::Nginx::Util::ErrLogFile")
    #require "resty.core"
    #';

_EOC_

no_long_string();
run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(2)

            collectgarbage()

            c:set("dog", 32)
            c:set("cat", 56)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))

            c:set("dog", 32)
            c:set("cat", 56)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))

            c:delete("dog")
            c:delete("cat")
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
cat: 56
dog: 32
cat: 56
dog: nil
cat: nil

--- no_error_log
[error]



=== TEST 2: evict existing items
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucace: ", err)
               return
            end

            c:set("dog", 32)
            c:set("cat", 56)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))

            c:set("bird", 76)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))
            ngx.say("bird: ", c:get("bird"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
cat: 56
dog: nil
cat: 56
bird: 76

--- no_error_log
[error]



=== TEST 3: evict existing items (reordered, get should also count)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucace: ", err)
               return
            end

            c:set("cat", 56)
            c:set("dog", 32)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))

            c:set("bird", 76)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))
            ngx.say("bird: ", c:get("bird"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
cat: 56
dog: nil
cat: 56
bird: 76

--- no_error_log
[error]



=== TEST 4: ttl
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(1)

            c:set("dog", 32, 0.5)
            ngx.say("dog: ", c:get("dog"))

            ngx.sleep(0.25)
            ngx.say("dog: ", c:get("dog"))

            ngx.sleep(0.26)
            ngx.say("dog: ", c:get("dog"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
dog: 32
dog: nil32

--- no_error_log
[error]



=== TEST 5: ttl
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local lim = 5
            local c = lrucache.new(lim)
            local n = 1000

            for i = 1, n do
                c:set("dog" .. i, i)
                c:delete("dog" .. i)
                c:set("dog" .. i, i)
                local cnt = 0
                for k, v in pairs(c.hasht) do
                    cnt = cnt + 1
                end
                assert(cnt <= lim)
            end

            for i = 1, n do
                local key = "dog" .. math.random(1, n)
                c:get(key)
            end

            for i = 1, n do
                local key = "dog" .. math.random(1, n)
                c:get(key)
                c:set("dog" .. i, i)

                local cnt = 0
                for k, v in pairs(c.hasht) do
                    cnt = cnt + 1
                end
                assert(cnt <= lim)
            end

            ngx.say("ok")
        ';
    }
--- request
    GET /t
--- response_body
ok

--- no_error_log
[error]
--- timeout: 20



=== TEST 6: replace value
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(1)

            c:set("dog", 32)
            ngx.say("dog: ", c:get("dog"))

            c:set("dog", 33)
            ngx.say("dog: ", c:get("dog"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
dog: 33

--- no_error_log
[error]



=== TEST 7: count
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(2)

            ngx.say("count: ", c:count())

            c:set("dog", 32)
            ngx.say("count: ", c:count())
            c:set("dog", 33)

            ngx.say("count: ", c:count())
            c:set("cat", 33)

            ngx.say("count: ", c:count())
            c:set("pig", 33)

            ngx.say("count: ", c:count())
            c:delete("dog")

            ngx.say("count: ", c:count())
            c:delete("pig")

            ngx.say("count: ", c:count())
            c:delete("cat")

            ngx.say("count: ", c:count())
        }
    }
--- request
    GET /t
--- response_body
count: 0
count: 1
count: 1
count: 2
count: 2
count: 2
count: 1
count: 0

--- no_error_log
[error]



=== TEST 8: capacity
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



=== TEST 9: get_keys() with some keys
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 10: get_keys() with no keys
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 11: get_keys() filled lru-cache
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 12: get_keys() max_count = 5
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 13: get_keys() max_count = 0 disables max returns
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 14: get_keys() user-fed res table
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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



=== TEST 15: get_keys() user-fed res table + max_count
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
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

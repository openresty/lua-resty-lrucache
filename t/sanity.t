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



=== TEST 7: flush_all() deletes all keys
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(100)

            local N = 3

            for i = 1, N do
                c:set("key " .. i, true)
            end

            c:flush_all()

            for i = 1, N do
                local key = "key " .. i
                local v = c:get(key)
                ngx.say(key, ": ", v)
            end
        }
    }
--- request
    GET /t
--- response_body
key 1: nil
key 2: nil
key 3: nil

--- no_error_log
[error]



=== TEST 8: flush_all() flush empty cache store
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(100)

            local N = 3

            c:flush_all()

            for i = 1, N do
                local key = "key " .. i
                local v = c:get(key)
                ngx.say(key, ": ", v)
            end
        }
    }
--- request
    GET /t
--- response_body
key 1: nil
key 2: nil
key 3: nil

--- no_error_log
[error]



=== TEST 9: flush_all() flush full cache store and allows subsequent reuse
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local N = 100

            local lrucache = require "resty.lrucache"
            local c = lrucache.new(N)

            for i = 1, N do
                c:set("key " .. i, true)
            end

            c:flush_all()

            c:set("new_key", true)

            ngx.say("value set after flush_all: ", c:get("new_key"))
        }
    }
--- request
    GET /t
--- response_body
value set after flush_all: true

--- no_error_log
[error]

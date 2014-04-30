# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

#no_diff();
#no_long_string();

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
    lua_package_path "$pwd/lib/?.lua;;";
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

            c:set("dog", 32, 0.1)
            ngx.say("dog: ", c:get("dog"))

            ngx.sleep(0.05)
            ngx.say("dog: ", c:get("dog"))

            ngx.sleep(0.051)
            ngx.say("dog: ", c:get("dog"))
        ';
    }
--- request
    GET /t
--- response_body
dog: 32
dog: 32
dog: nil

--- no_error_log
[error]


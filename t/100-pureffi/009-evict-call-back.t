# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestLRUCache;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

no_long_string();
run_tests();

__DATA__

=== TEST 1: evict with call back
--- config
    location = /t {
        content_by_lua_block {
            local function evict_cb(k,v)
                ngx.say(k, v)
            end
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(1, nil, evict_cb)

            collectgarbage()

            c:set("dog", 12)
            c:set("cat", 14)
        }
    }
--- response_body
dog12



=== TEST 2: evict with call back, ttl
--- config
    location = /t {
        content_by_lua_block {
            local function evict_cb(k,v)
                ngx.say(k, v)
            end
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(1, nil, evict_cb)

            collectgarbage()

            c:set("dog", 12, 1)
            ngx.sleep(1)
            c:get("dog")
        }
    }
--- response_body
dog12

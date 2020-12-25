# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestLRUCache;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

no_long_string();
run_tests();

__DATA__

=== TEST 1: delete_oldest() keys in lru
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.lrucache"

            local N = 4

            local c = lrucache.new(N)

            for i = 1, N + 1 do
                c:set("key " .. i, i)
            end

            ngx.say(c:get("key ".. 1))
            ngx.say((c:get("key ".. 2)))

            local key = c:delete_oldest()
            ngx.say(key)

            local key = c:delete_oldest()
            ngx.say(key)

            ngx.say(c:count())
            ngx.say((c:get(key)))
            local key = c:delete_oldest()
            ngx.say(key)
            local key = c:delete_oldest()
            ngx.say(key)
            local key = c:delete_oldest()
            ngx.say(key)
            ngx.say(c:count())
        }
    }
--- response_body
nil
2
key 3
key 4
2
nil
key 5
key 2
nil
0

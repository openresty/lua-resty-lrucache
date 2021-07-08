# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestLRUCache;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

no_long_string();
run_tests();

__DATA__

=== TEST 1: peek() keys in lru
--- config
    location = /t {
        content_by_lua_block {
            local lrucache = require "resty.arccache"

            local N = 4

            local c = lrucache.new(N)

            for i = 1, N + 1 do
                c:set("key " .. i, i)
            end

            local v = c:peek("key "..1)
            ngx.say(v)

            local v = c:peek("key "..2)
            ngx.say(v)
        }
    }
--- response_body
nil
2

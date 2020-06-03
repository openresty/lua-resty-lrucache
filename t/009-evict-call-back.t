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
        content_by_lua '
            local function evict_cb(k,v)
                ngx.say(k, v)
            end
            local lrucache = require "resty.lrucache"
            local c = lrucache.new(1, evict_cb)

            collectgarbage()

            c:set("dog", 12)
            c:set("cat", 14)
        ';
    }
--- response_body
dog12

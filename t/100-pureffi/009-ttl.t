# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestLRUCache;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3);

no_long_string();
run_tests();

__DATA__

=== TEST 1: no ttl
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucache: ", err)
               return
            end

            c:set("dog", 32)

            ngx.say("ttl: ", (c:ttl("dog")))
        ';
    }
--- response_body
ttl: -1



=== TEST 2: ttl defined
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucache: ", err)
               return
            end

            c:set("dog", 32, 0.2)
            ngx.say("ttl: ", ((c:ttl("dog") or 0) > 0))

            ngx.sleep(0.3)

            ngx.say("ttl: ", ((c:ttl("dog") or 0) > 0))
        ';
    }
--- response_body
ttl: true
ttl: false



=== TEST 3: update_queue is false
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucache: ", err)
               return
            end

            c:set("dog", 32)
            c:set("cat", 33)
            
            ngx.say("dog: ", (c:get("dog")))
            ngx.say("cat: ", (c:get("cat")))

            ngx.say("ttl cat: ", (c:ttl("cat")))
            ngx.say("ttl dog: ", (c:ttl("dog")))

            c:set("bird", 76)

            ngx.say("dog: ", (c:get("dog")))
            ngx.say("cat: ", (c:get("cat")))
            ngx.say("bird: ", (c:get("bird")))
        ';
    }
--- response_body
dog: 32
cat: 33
ttl cat: -1
ttl dog: -1
dog: nil
cat: 33
bird: 76



=== TEST 4: update_queue is true
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(2)
            if not c then
               ngx.say("failed to init lrucache: ", err)
               return
            end

            c:set("dog", 32)
            c:set("cat", 33)

            ngx.say("dog: ", (c:get("dog")))
            ngx.say("cat: ", (c:get("cat")))

            ngx.say("ttl cat: ", (c:ttl("cat", true)))
            ngx.say("ttl dog: ", (c:ttl("dog", true)))

            c:set("bird", 76)

            ngx.say("dog: ", (c:get("dog")))
            ngx.say("cat: ", (c:get("cat")))
            ngx.say("bird: ", (c:get("bird")))
        ';
    }
--- response_body
dog: 32
cat: 33
ttl cat: -1
ttl dog: -1
dog: 32
cat: nil
bird: 76


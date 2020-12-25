# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestLRUCache;

repeat_each(1);

plan tests => repeat_each() * (blocks() * 2);

no_long_string();
run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval
"$t::TestLRUCache::HttpConfig"
. qq!
    init_by_lua '
        local function log(...)
            print("[cache] ", ...)
        end

        local arccache = require "resty.arccache.pureffi"
        local c = arccache.new(2)

        collectgarbage()

        c:set("dog", 32)
        c:set("cat", 56)
        log("dog: ", (c:get("dog")))
        log("cat: ", (c:get("cat")))

        c:set("dog", 32)
        c:set("cat", 56)
        log("dog: ", (c:get("dog")))
        log("cat: ", (c:get("cat")))

        c:delete("dog")
        c:delete("cat")
        log("dog: ", (c:get("dog")))
        log("cat: ", (c:get("cat")))
    ';
!
--- config
    location = /t {
        return 200;
    }
--- ignore_response
--- error_log
--- grep_error_log eval: qr/\[cache\] .*? (?:\d+|nil)/
--- grep_error_log_out
[cache] dog: 32
[cache] cat: 56
[cache] dog: 32
[cache] cat: 56
[cache] dog: nil
[cache] cat: nil



=== TEST 2: sanity
--- http_config eval
"$t::TestLRUCache::HttpConfig"
. qq!
    init_by_lua '
        arccache = require "resty.arccache.pureffi"
        flv_index, err = arccache.new(200)
        if not flv_index then
            ngx.log(ngx.ERR, "failed to create the cache: ", err)
            return
        end

        flv_meta, err = arccache.new(200)
        if not flv_meta then
            ngx.log(ngx.ERR, "failed to create the cache: ", err)
            return
        end

        flv_channel, err = arccache.new(200)
        if not flv_channel then
            ngx.log(ngx.ERR, "failed to create the cache: ", err)
            return
        end

        print("3 arccache initialized.")
    ';
!
--- config
    location = /t {
        return 200;
    }
--- ignore_response
--- error_log
3 arccache initialized.

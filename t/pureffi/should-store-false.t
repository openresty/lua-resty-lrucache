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

=== TEST 1: should-store-false
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache.pureffi"
            local c = lrucache.new(2)

            collectgarbage()

            c:set("false-value", false)
            ngx.say("false-value: ", c:get("false-value"))

            c:delete("false-value")
            ngx.say("false-value: ", c:get("false-value"))
        ';
    }
--- request
    GET /t
--- response_body
false-value: false
false-value: nil
--- no_error_log
[error]

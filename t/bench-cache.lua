require "resty.core"
require "jit.opt".start("minstitch=2", "maxtrace=4000",
                        "maxrecord=8000", "sizemcode=64",
                        "maxmcode=4000", "maxirconst=1000")
local ngx = ngx

math.randomseed(os.time())

local function bench_lru(num, name, size, typ)
    local lrucache = require "resty.lrucache"
    local lru =  lrucache.new(size)
    local randoms = {}
    for i = 1, num do
        if i%2 == 0 then
            randoms[i] = math.random(0, num) % 16384
        else
            randoms[i] = math.random(0, num) % 32768
        end
    end

    ngx.update_time()
    local start = ngx.now()

    for i = 1, num do
        lru:set(randoms[i], randoms[i])
    end

    local hit, miss = 0, 0
    for i = 1, num do
        local v = lru:get(randoms[i], randoms[i])
        if v ~= nil then
            hit = hit+1
        else
            miss = miss +1
        end
    end

    ngx.update_time()
    local elasped = ngx.now() - start

    if typ then
        elasped = elasped - base_time
    end

    ngx.say(name, ": ", num, " times")
    ngx.say("elasped: ", elasped)
    ngx.say("hit: ", hit, ", miss: ", miss, ", ratio: ", hit/(miss+hit))
    ngx.say("")
end

local function bench_lru_pureffi(num, name, size, typ)
    local lrucache = require "resty.lrucache.pureffi"
    local lru =  lrucache.new(size)
    local randoms = {}
    for i = 1, num do
        if i%2 == 0 then
            randoms[i] = math.random(0, num) % 16384
        else
            randoms[i] = math.random(0, num) % 32768
        end
    end

    ngx.update_time()
    local start = ngx.now()

    for i = 1, num do
        lru:set(randoms[i], randoms[i])
    end

    local hit, miss = 0, 0
    for i = 1, num do
        local v = lru:get(randoms[i], randoms[i])
        if v ~= nil then
            hit = hit+1
        else
            miss = miss +1
        end
    end

    ngx.update_time()
    local elasped = ngx.now() - start

    if typ then
        elasped = elasped - base_time
    end

    ngx.say(name, ": ", num, " times")
    ngx.say("elasped: ", elasped)
    ngx.say("hit: ", hit, ", miss: ", miss, ", ratio: ", hit/(miss+hit))
    ngx.say("")
end


local function bench_arc(num, name, size, typ)
    local arccache = require "resty.arccache"
    local lru =  arccache.new(size)
    local randoms = {}
    for i = 1, num do
        if i%2 == 0 then
            randoms[i] = math.random(0, num) % 16384
        else
            randoms[i] = math.random(0, num) % 32768
        end
    end

    ngx.update_time()
    local start = ngx.now()

    for i = 1, num do
        lru:set(randoms[i], randoms[i])
    end

    local hit, miss = 0, 0
    for i = 1, num do
        local v = lru:get(randoms[i], randoms[i])
        if v ~= nil then
            hit = hit+1
        else
            miss = miss +1
        end
    end

    ngx.update_time()
    local elasped = ngx.now() - start

    ngx.say(name, ": ", num, " times")
    ngx.say("elasped: ", elasped)
    ngx.say("hit: ", hit, ", miss: ", miss, ", ratio: ", hit/(miss+hit))
    ngx.say("")
end



local function bench_arc_pureffi(num, name, size, typ)
    local arccache = require "resty.arccache.pureffi"
    local lru =  arccache.new(size)
    local randoms = {}
    for i = 1, num do
        if i%2 == 0 then
            randoms[i] = math.random(0, num) % 16384
        else
            randoms[i] = math.random(0, num) % 32768
        end
    end

    ngx.update_time()
    local start = ngx.now()

    for i = 1, num do
        lru:set(randoms[i], randoms[i])
    end

    local hit, miss = 0, 0
    for i = 1, num do
        local v = lru:get(randoms[i], randoms[i])
        if v ~= nil then
            hit = hit+1
        else
            miss = miss +1
        end
    end

    ngx.update_time()
    local elasped = ngx.now() - start

    ngx.say(name, ": ", num, " times")
    ngx.say("elasped: ", elasped)
    ngx.say("hit: ", hit, ", miss: ", miss, ", ratio: ", hit/(miss+hit))
    ngx.say("")
end


bench_lru(1000000, "10 lru", 10)
bench_lru(1000000, "9527 lru", 9527)
bench_lru(1000000, "9527*10 lru", 9527*10)
bench_lru_pureffi(1000000, "10 lru pureffi", 10)
bench_lru_pureffi(1000000, "9527 lru pureffi", 9527)
bench_lru_pureffi(1000000, "9527*10 lru pureffi", 9527*10)
bench_arc(1000000, "10 arc", 10)
bench_arc(1000000, "9527 arc", 9527)
bench_arc(1000000, "9527*10 arc", 9527*10)
bench_arc_pureffi(1000000, "10 arc pureffi", 10)
bench_arc_pureffi(1000000, "9527 arc pureffi", 9527)
bench_arc_pureffi(1000000, "9527*10 arc pureffi", 9527*10)

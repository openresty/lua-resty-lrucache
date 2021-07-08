-- Copyright (C) Yichun Zhang (agentzh)
--
--[[ This module implements a key/value cache store. We adopt ARC as our
replace/evict policy. Each key/value pair is tagged with a Time-to-Live (TTL);
from user's perspective, stale pairs are automatically removed from the cache.

Adaptive Replacement Cache (ARC) is a page replacement algorithm
with better performance than LRU (least recently used).
This is accomplished by keeping track of both frequently used
and recently used pages plus a recent eviction history for both.
More details can be found in https://en.wikipedia.org/wiki/Adaptive_replacement_cache.
]] --
local lrucache = require "resty.lrucache"
local ngx_now = ngx.now
local setmetatable = setmetatable
local new_tab
do
    local ok
    ok, new_tab = pcall(require, "table.new")
    if not ok then new_tab = function(narr, nrec) return {} end end
end

local function _replace(self, b2ContainsKey)
    local t1len = self.t1:count()
    if t1len > 0 and (t1len > self.p or (t1len == self.p and b2ContainsKey)) then
        local key, ok = self.t1:delete_oldest()
        if ok then self.b1:set(key, nil) end
    else
        local key, ok = self.t2:delete_oldest()
        if ok then self.b2:set(key, nil) end
    end
end

if string.find(jit.version, " 2.0", 1, true) then
    ngx.log(ngx.ALERT, "use of lua-resty-lrucache with LuaJIT 2.0 is ",
            "not recommended; use LuaJIT 2.1+ instead")
end

local _M = {_VERSION = '0.10'}
local mt = {__index = _M}

function _M.new(size)
    local self = {
        t1 = lrucache.new(size),
        t2 = lrucache.new(size),
        b1 = lrucache.new(size),
        b2 = lrucache.new(size),

        size = size, -- Size is the total capacity of the cache
        p = 0 -- P is the dynamic preference towards T1 or T2
    }

    return setmetatable(self, mt)
end

function _M.get(self, key)
    local t1val, exp, userflag = self.t1:peek(key)
    if t1val ~= nil then
        if exp == -1 then
            exp = -1
        elseif exp >= 0 and exp < ngx_now() then
            return nil, t1val, userflag
        else
            exp = exp - ngx_now()
        end

        self.t1:delete(key)
        self.t2:set(key, t1val, exp, userflag)
        return t1val, nil, userflag
    end

    return self.t2:get(key)
end

function _M.set(self, key, value, ttl, flags)
    local expire = 0
    local user_flags
    if ttl and ttl >= 0 then
        expire = ttl
    else
        expire = -1
    end

    if type(flags) == "number" and flags >= 0 then
        user_flags = flags
    else
        user_flags = 0
    end

    local t1val = self.t1:peek(key)
    if t1val ~= nil then
        self.t1:delete(key)
        self.t2:set(key, t1val, expire, user_flags)
        return
    end

    local t2val = self.t2:peek(key)
    if t2val ~= nil then
        self.t2:set(key, value, expire, user_flags)
        return
    end

    local b1val = self.b1:peek(key)
    if b1val ~= nil then
        local delta = 1
        local b1len = self.b1:count()
        local b2len = self.b2:count()
        if b2len > b1len then delta = b2len / b1len end
        if self.p + delta >= self.size then
            self.p = self.size
        else
            self.p = self.p + delta
        end

        if self.t1:count() + self.t2:count() >= self.size then
            _replace(self, false)
        end

        self.b1:delete(key)
        self.t2:set(key, value, expire, user_flags)
        return
    end

    local b2val, _, _ = self.b2:peek(key)
    if b2val ~= nil then
        local delta = 1
        local b1len = self.b1:count()
        local b2len = self.b2:count()
        if b1len > b2len then delta = b1len / b2len end
        if delta >= self.p then
            self.p = 0
        else
            self.p = self.p - delta
        end

        if self.t1:count() + self.t2:count() >= self.size then
            _replace(self, true)
        end

        self.b2:delete(key)
        self.t2:set(key, value, expire, user_flags)
        return
    end

    if self.t1:count() + self.t2:count() >= self.size then
        _replace(self, false)
    end

    if self.b1:count() > self.size - self.p then self.b1:delete_oldest() end

    if self.b2:count() > self.p then self.b2:delete_oldest() end

    self.t1:set(key, value, expire, user_flags)
end

function _M.count(self) return self.t1:count() + self.t2:count() end

function _M.peek(self, key)
    local t1val, expire, flags = self.t1:peek(key)
    if t1val ~= nil then return t1val, expire, flags end

    return self.t2:peek(key)
end

function _M.get_keys(self, max_count, res)
    if not max_count or max_count == 0 then max_count = self:count() end

    if not res then
        res = new_tab(max_count + 1, 0) -- + 1 for trailing hole
    end

    self.t1:get_keys(max_count, res)

    local t1len = #res
    if t1len >= max_count then return res end

    local t2 = self.t2:get_keys(max_count - t1len, nil)

    for i = 1, #t2 do res[i + t1len] = t2[i] end

    return res
end
function _M.flush_all(self)
    self.t1:flush_all()
    self.t2:flush_all()
    self.b1:flush_all()
    self.b2:flush_all()
    self.p = 0
end

function _M.capacity(self) return self.size end

function _M.delete(self, key)
    if self.t1:delete(key) then return end
    if self.t2:delete(key) then return end
    if self.b1:delete(key) then return end
    if self.b2:delete(key) then return end
end

return _M

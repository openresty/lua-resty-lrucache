package = "lua-resty-lrucache"
version = "0.09-1"
source = {
   url = "git://github.com/openresty/lua-resty-lrucache",
   tag = "v0.09",
}
description = {
   summary = "lua-resty-lrucache - Lua-land LRU cache based on the LuaJIT FFI.",
   detailed = [[
This library implements a simple LRU cache for OpenResty and the ngx_lua module.

This cache also supports expiration time.

The LRU cache resides completely in the Lua VM and is subject to Lua GC. 
As such, do not expect it to get shared across the OS process boundary. 
The upside is that you can cache arbitrary complex Lua values (such as deep nested Lua tables) without the overhead of serialization (as with ngx_lua's shared dictionary API). 
The downside is that your cache is always limited to the current OS process (i.e. the current Nginx worker process). 
It does not really make much sense to use this library in the context of init_by_lua 
because the cache will not get shared by any of the worker processes 
(unless you just want to "warm up" the cache with predefined items which will get inherited by the workers via fork()).

This library offers two different implementations in the form of two classes: resty.lrucache and resty.lrucache.pureffi. 
Both implement the same API. The only difference is that the latter is a pure FFI implementation that also implements an 
FFI-based hash table for the cache lookup, while the former uses native Lua tables.

If the cache hit rate is relatively high, you should use the resty.lrucache class which is faster than resty.lrucache.pureffi.

However, if the cache hit rate is relatively low and there can be a lot of variations of keys inserted into and removed from the cache, 
then you should use the resty.lrucache.pureffi instead, because Lua tables are not good at removing keys frequently. 
You would likely see the resizetab function call in the LuaJIT runtime being very hot in on-CPU flame graphs 
if you use the resty.lrucache class instead of resty.lrucache.pureffi in such a use case.

   ]],
   homepage = "https://openresty.org/",
   license = "2bsd"
}
dependencies = {
   "luajit",
}

build = {
   type = "builtin",

  modules = {
    ["resty.lrucache"] = "lib/resty/lrucache.lua",
    ["resty.lrucache.pureffi"]   = "lib/resty/lrucache/pureffi.lua"
  },
}

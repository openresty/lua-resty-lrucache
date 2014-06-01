Name
====

lua-resty-lrucache - in-Lua LRU Cache based on LuaJIT FFI

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Description](#description)
* [Methods](#methods)
    * [new](#new)
    * [set](#set)
    * [get](#get)
    * [delete](#delete)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [TODO](#todo)
* [Community](#community)
    * [English Mailing List](#english-mailing-list)
    * [Chinese Mailing List](#chinese-mailing-list)
* [Bugs and Patches](#bugs-and-patches)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is still under active development and is considered production ready.

Synopsis
========

```nginx
    lua_package_path "/path/to/lua-resty-lrucache/lib/?.lua;;";

    location = /t {
        content_by_lua '
            local lrucache = require "resty.lrucache"

            local c = lrucache.new(200)  -- allow up to 200 items in the cache
            if not c then
                ngx.say("failed to create the cache: ", err)
                return
            end

            c:set("dog", 32)
            c:set("cat", 56)
            ngx.say("dog: ", c:get("dog"))
            ngx.say("cat: ", c:get("cat"))

            c:set("dog", { age = 10 }, 0.1)  -- expire in 0.1 sec
            c:delete("dog")
        ';
    }
```

Description
===========

This library implements a simple LRU cache for [OpenResty](http://openresty.org) and the [ngx_lua](https://github.com/chaoslawful/lua-nginx-module) module.

This cache also supports expiration time.

The LRU cache resides completely in the Lua VM and is subject to Lua GC. So do not expect
it to get shared across the OS process boundary. The upside is that you can cache
arbitrary complex Lua values (like deep nested Lua tables) without the overhead of
serialization (as with `ngx_lua`'s
[shared dictionary API](https://github.com/chaoslawful/lua-nginx-module#lua_shared_dict)).
The downside is that your cache is always limited to the current OS process
(like the current nginx worker process). It does not really make much sense to use this
library in the context of [init_by_lua](https://github.com/chaoslawful/lua-nginx-module#lua_shared_dict)
because the cache will not get shared by any of the worker processes
(unless you just want to "warm up" the cache with predefined items which will get
inherited by the workers via `fork`).

[Back to TOC](#table-of-contents)

Methods
=======

To load this library,

1. you need to specify this library's path in ngx_lua's [lua_package_path](https://github.com/chaoslawful/lua-nginx-module#lua_package_path) directive. For example, `lua_package_path "/path/to/lua-resty-lrucache/lib/?.lua;;";`.
2. you use `require` to load the library into a local Lua variable:

```lua
    local lrucache = require "resty.lrucache"
```

[Back to TOC](#table-of-contents)

new
---
`syntax: cache, err = lrucache.new(max_items)`

Creates a new cache instance. If failed, returns `nil` and a string describing the error.

The `max_items` argument specifies the maximal number of items held in the cache.

[Back to TOC](#table-of-contents)

set
---
`syntax: cache:set(key, value, ttl)`

Sets a key with a value and an expiration time.

The `ttl` argument specifies the expiration time period. The time value is in seconds, but you can also specify the fraction number part, like `0.25`. A nil `ttl` argument value means never expired (which is the default).

When the cache is full, the cache will automatically evict the least recently used item.

[Back to TOC](#table-of-contents)

get
---
`syntax: data = cache:get(key)`

Fetches a value with the key. If the key does not exist in the cache or has already expired, a `nil` value will be returned.

[Back to TOC](#table-of-contents)

delete
------
`syntax: cache:delete(key)`

Removes an item specified by the key from the cache.

[Back to TOC](#table-of-contents)

Prerequisites
=============

* [LuaJIT](http://luajit.org) 2.0+
* [ngx_lua](https://github.com/chaoslawful/lua-nginx-module) 0.8.10+

[Back to TOC](#table-of-contents)

Installation
============

It is recommended to use the latest [ngx_openresty bundle](http://openresty.org) directly. At least ngx_openresty 1.4.2.9 is required. And you need to enable LuaJIT when building your ngx_openresty
bundle by passing the `--with-luajit` option to its `./configure` script. No extra Nginx configuration is required.

If you want to use this library with your own Nginx build (with ngx_lua), then you need to
ensure you are using at least ngx_lua 0.8.10.

Also, You need to configure
the [lua_package_path](https://github.com/chaoslawful/lua-nginx-module#lua_package_path) directive to
add the path of your lua-resty-lrucache source tree to ngx_lua's Lua module search path, as in

```nginx
    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-lrucache/lib/?.lua;;";
        ...
    }
```

and then load the library in Lua:

```lua
    local lrucache = require "resty.lrucache"
```

[Back to TOC](#table-of-contents)

TODO
====

* add new method `get_stale` for fetching already expired items.
* add new method `flush_all` for flushing out everything in the cache.

[Back to TOC](#table-of-contents)

Community
=========

[Back to TOC](#table-of-contents)

English Mailing List
--------------------

The [openresty-en](https://groups.google.com/group/openresty-en) mailing list is for English speakers.

[Back to TOC](#table-of-contents)

Chinese Mailing List
--------------------

The [openresty](https://groups.google.com/group/openresty) mailing list is for Chinese speakers.

[Back to TOC](#table-of-contents)

Bugs and Patches
================

Please report bugs or submit patches by

1. creating a ticket on the [GitHub Issue Tracker](http://github.com/agentzh/lua-resty-lrucache/issues),
1. or posting to the [OpenResty community](#community).

[Back to TOC](#table-of-contents)

Author
======

Yichun "agentzh" Zhang (章亦春) <agentzh@gmail.com>, CloudFlare Inc.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2014, by Yichun "agentzh" Zhang, CloudFlare Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: https://github.com/chaoslawful/lua-nginx-module
* OpenResty: http://openresty.org

[Back to TOC](#table-of-contents)


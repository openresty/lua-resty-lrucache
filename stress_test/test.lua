local argv = {...}
if #argv ~= 1 then
    print ("Usage test.lua key-file")
    os.exit(1)
end

local keyfile = io.open(argv[1])
if not keyfile then
    io.write(string.format("Fail to open key file '%s'\n", argv[1]))
    os.exit(1)
end

ngx = {}
ngx.new = function() return os.time() end

package.path =  "../lib/resty/?.lua;../lib/resty/lrucache/?.lua;" .. package.path
lruffi = require "pureffi"
lru = require "lrucache"

local key_num = 128
local lru_inst = lru.new(key_num)
local lruffi_inst = lruffi.new(key_num, 0.5)

local key_vect = {}
local key_idx = 0
local key_cnt = 0

local function compare()
    for i = 1, key_idx do
        local key = key_vect[i]
        local val1 = lru_inst:get(key)
        local val2 = lruffi_inst:get(key)
        -- print(key, val1, val2)
        if val1 ~= val2 then
            io.write(
                string.format("disagree on key '%s', values are %d vs %d\n",
                              key, val1, val2))
            os.exit(1)
        end
    end
end

local function main()
    for line in keyfile:lines() do

        lru_inst:set(line, key_cnt)
        lruffi_inst:set(line, key_cnt)

        key_cnt = key_cnt + 1
        key_idx = key_idx + 1
        key_vect[key_idx] = line

        if key_idx == key_num then
            compare()
            for i = 1, key_idx do
                key_vect[i] = nil
            end
            key_idx = 0
        end
    end

    compare()
end

main()

os.exit(0)

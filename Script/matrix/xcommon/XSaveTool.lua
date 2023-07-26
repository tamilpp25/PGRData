local tostring = tostring
local load = load
local type = type
local ipairs = ipairs
local pairs = pairs
local string = string
local table = table

local stringDump = string.dump
local stringGmatch = string.gmatch
local tableUnpack = table.unpack
local tableInsert = table.insert
local tableSort = table.sort
local tableConcat = table.concat


XSaveTool = XSaveTool or {}
XSaveTool.LocalCache = {}

local StrCache = {} --字符串缓存
local ClearCacheTime = 5 * 60 -- 清除缓存时间
local LuaDataHeader = "LuaData:"
 

--region   ------------------obj -> string start-------------------
local function fret(...)
    local args = { ... }
    return function()
        return tableUnpack(args)
    end
end

local function updateStrCache(key, value, now)
    StrCache[key] = {
        Value = value,
        UpdateTime = now
    }

    for k, v in pairs(StrCache) do
        if now - v.UpdateTime >= ClearCacheTime then
            StrCache[k] = nil
        end
    end
end

local function getStrFromCache(key, newFunc) 
    local temp = StrCache[key]
    local now = XTime.GetServerNowTimestamp()
    if temp then
        temp.UpdateTime = now
        return temp.Value
    end
    local result = newFunc()
    updateStrCache(key, result, now)
    return result
end

local function getLuaDataKey(key)
    local temp = StrCache[key]
    if temp then
        return getStrFromCache(key)
    end
    local newFunc = function() 
        return string.format("%s%s", LuaDataHeader, key)
    end
    return getStrFromCache(key, newFunc)
end

local function NilStringify(val, needSort, cache)
    return "nil"
end

local function BoolStringify(val, needSort, cache)
    return tostring(val)
end

local function NumStringify(val, needSort, cache)
    return tostring(val)
end

local function FuncStringify(val, needSort, cache)
    return string.format("function(...) return load(%s)(...) end", XSaveTool.Stringify(stringDump(val), needSort, cache))
end

local function StrStringify(val, needSort, cache)
    local temp = StrCache[val]
    if temp then
        return getStrFromCache(val)
    end
    local newFunc = function()
        local s = "\""
        for c in stringGmatch(val, ".") do
            s = string.format("%s\\%s", s, c:byte())
        end
        return string.format("%s\"", s)
    end
    return getStrFromCache(val, newFunc)
end

local function TbStringify(val, needSort, cache)
    cache = cache or {}
    if cache[val] then
        XLog.Error("loop Stringify")
        return
    end
    cache[val] = true
    local members = {}
    if needSort then
        local keys = {}
        for k, _ in pairs(val) do
            tableInsert(keys, k)
        end
        tableSort(keys)
        for _, v in ipairs(keys) do
            tableInsert(members, "[" .. XSaveTool.Stringify(v, needSort, cache) .. "]=" .. XSaveTool.Stringify(val[v], needSort, cache))
        end
    else
        for k, v in pairs(val) do
            tableInsert(members, "[" .. XSaveTool.Stringify(k, needSort, cache) .. "]=" .. XSaveTool.Stringify(v, needSort, cache))
        end
    end
    return string.format("{%s}", tableConcat(members, ","))
end

local StringifyFuncMap = {
    ["nil"]         = NilStringify,
    ["boolean"]     = BoolStringify,
    ["number"]      = NumStringify,
    ["function"]    = FuncStringify,
    ["string"]      = StrStringify,
    ["table"]       = TbStringify,
}
--endregion------------------obj -> string finish------------------

--==============================--
--desc: 数据字符串化
--@val: 需要封装成字符串的数据
--@needSort: 是否需要排序
--@cache: 缓存处理，table引用死锁判断
--@return 封装好的字符串
--==============================--
function XSaveTool.StringifyOld(val, needSort, cache)
    cache = cache or {}

    return (({
        ["nil"]        = fret "nil",
        ["boolean"]    = fret(tostring(val)),
        ["number"]    = fret(val),
        ["function"]    = function()
            return "function(...)" ..
            "return load(" ..
            XSaveTool.StringifyOld(stringDump(val), needSort, cache) ..
            ")(...)" ..
            "end"
        end,
        ["string"]    = function()
            local s = "\""
            for c in stringGmatch(val, ".") do
                s = s .. "\\" .. c:byte()
            end
            return s .. "\""
        end,
        ["table"]    = function()
            if cache[val] then
                XLog.Error("loop Stringify")
                return
            end
            cache[val] = true
            local members = {}
            if needSort then
                local keys = {}
                for k, _ in pairs(val) do
                    tableInsert(keys, k)
                end
                tableSort(keys)
                for _, v in ipairs(keys) do
                    tableInsert(members, "[" .. XSaveTool.StringifyOld(v, needSort, cache) .. "]=" .. XSaveTool.StringifyOld(val[v], needSort, cache))
                end
            else
                for k, v in pairs(val) do
                    tableInsert(members, "[" .. XSaveTool.StringifyOld(k, needSort, cache) .. "]=" .. XSaveTool.StringifyOld(v, needSort, cache))
                end
            end
            return "{" .. tableConcat(members, ",") .. "}"
        end,
    })[type(val)] or function()
        XLog.Error("cannot Stringify type:" .. type(val), 2)
    end)()
end

function XSaveTool.Stringify(val, needSort, cache)
    local func = StringifyFuncMap[type(val)]
    if not func then
        XLog.Error("cannot Stringify type:" .. type(val), 2)
    end
    return func(val, needSort, cache)
end

--==============================--
--desc: 本地数据持久化
--@key: 存储key
--@value: 存储值
--==============================--
function XSaveTool.SaveData(key, value)
    local k = XSaveTool.Stringify(key, true)
    if value == false then
        XSaveTool.LocalCache[k] = nil
    else
        XSaveTool.LocalCache[k] = value or XSaveTool.LocalCache[k]
    end
    CS.UnityEngine.PlayerPrefs.SetString(getLuaDataKey(k), XSaveTool.Stringify(XSaveTool.LocalCache[k]))
    CS.UnityEngine.PlayerPrefs.Save()
end

--==============================--
--desc: 持久化数据删除
--@key: 数据key
--==============================--
function XSaveTool.RemoveData(key)
    local k = XSaveTool.Stringify(key, true)
    XSaveTool.LocalCache[k] = nil
    CS.UnityEngine.PlayerPrefs.DeleteKey(getLuaDataKey(k))
end

--==============================--
--desc: 获取持久化数据
--@key: 存储key
--@return 存储值
--==============================--
function XSaveTool.GetData(key)
    local k = XSaveTool.Stringify(key, true)
    if XSaveTool.LocalCache[k] then
        return XSaveTool.LocalCache[k]
    end

    local str = CS.UnityEngine.PlayerPrefs.GetString(getLuaDataKey(k))
    if str and str ~= "" then
        local obj = load("return " .. str)()
        XSaveTool.LocalCache[k] = obj
        return obj
    end

    return nil
end

--==============================--
--desc: 移除所有持久化数据（调试）
--==============================--
function XSaveTool.RemoveAll()
    local enable1 = XDataCenter.GuideManager.CheckFuncDisable()
    local enable2 = XDataCenter.CommunicationManager.CheckFuncDisable()
    local enable3 = XDataCenter.FunctionEventManager.CheckFuncDisable()
    local enable4 = XRpc.CheckLuaNetLogEnable()

    XSaveTool.LocalCache = {}
    CS.UnityEngine.PlayerPrefs.DeleteAll()

    XDataCenter.GuideManager.ChangeFuncDisable(enable1)
    XDataCenter.CommunicationManager.ChangeFuncDisable(enable2)
    XDataCenter.FunctionEventManager.ChangeFuncDisable(enable3)
    XRpc.SetLuaNetLogEnable(enable4)
end
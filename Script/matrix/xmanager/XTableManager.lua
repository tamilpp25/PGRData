XTableManager = XTableManager or {}
local Binary = require("Binary/BinaryTable")

local rawget = rawget
local rawset = rawset

local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local math = math
local mathFloor = math.floor
local string = string
local stringFind = string.find
local stringSub = string.sub
local stringGmatch = string.gmatch
local stringSplit = string.Split
local table = table
local tableInsert = table.insert

-- 从外部目录读取tab
local UseExternTable = (CS.XTableManager.UseExternTable == true)

local UNUSE_BYTES_VALUE = 0
local USE_BYTES_VALUE = 1
local UseBytes = (CS.XTableManager.UseBytes == USE_BYTES_VALUE and not UseExternTable)

local loadFileProfiler = XGame.Profiler:CreateChild("LoadTableFile")
local readTabFileProfiler = XGame.Profiler:CreateChild("ReadTabFile")

--只读标志
local NeedSetReadonly = CS.XLuaEngine.LuaReadonlyTableMode ~= CS.XMode.Release
--只读元表
local ReadOnlyTable = {
    __newindex = function()
        XLog.Error("attempt to update a readonly table")
    end
}

local AllTables = {}

--默认类型
local DefaultOfType = {
    ["int"] = 0,
    ["float"] = 0,
    ["string"] = nil,
    ["bool"] = false,
    ["fix"] = fix.zero
}

local tableEmpty = {}

--默认类型
local DefaultOfTypeNew = {
    [1] = false,
    [2] = nil,
    [3] = fix.zero,
    [4] = tableEmpty,
    [5] = tableEmpty,
    [6] = tableEmpty,
    [7] = tableEmpty,
    [8] = tableEmpty,
    [9] = tableEmpty,
    [10] = tableEmpty,
    [11] = tableEmpty,
    [12] = tableEmpty,
    [13] = tableEmpty,
    [14] = 0,
    [15] = 0
}

-- debug
local IsEditorDebug = XMain.IsEditorDebug
local CurrentPath = ""
local CurrentKey = ""
local CurrentValue = ""
local CurrentRow = -1
local CurrentCol = -1

local ToInt = function(value)
    return mathFloor(value)
end

local ToFloat = function(value)
    return tonumber(value)
end

local ToString = function(value)
    return tostring(value)
end

local ToBool = function(value)
    return tonumber(value) ~= 0 and true or false
end

local ToFix = function(value)
    return FixParse(value)
end

local LIST_FLAG = 1
local DICTIONARY_FLAG = 2

local ValueFunc = {
    ["int"] = ToInt,
    ["float"] = ToFloat,
    ["string"] = ToString,
    ["bool"] = ToBool,
    ["fix"] = ToFix
}

local KeyFunc = {
    ["int"] = ToInt,
    ["string"] = ToString
}

local GetSingleValueNew = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return nil
    end

    return func(value)
end

local GetSingleValue = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return DefaultOfType[type]
    end

    return func(value)
end

local GetContainerValue = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return
    end

    return func(value)
end

local GetDictionaryKey = function(type, value)
    local func = KeyFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return
    end

    return func(value)
end

local IsDictionary = function(paramConfig)
    return paramConfig.Type == DICTIONARY_FLAG
end

local IsList = function(paramConfig)
    return paramConfig.Type == LIST_FLAG
end

local IsTable = function(pramsConfig)
    return IsDictionary(pramsConfig) or IsList(pramsConfig)
end

local EmptyTable = {}

-- type func end--
local READ_KEY_TYPE = {
    INT = 0,
    STRING = 1
}

local Split = function(str)
    local arr = {}
    for v in stringGmatch(str, "[^\t]*") do
        tableInsert(arr, v)
    end
    return arr
end

local CreateColElems = function(tableConfig)
    local elems = {}
    for key, paramConfig in pairs(tableConfig) do
        if IsTable(paramConfig) then
            elems[key] = {}
        else
            elems[key] = DefaultOfType[paramConfig.ValueType]
        end
    end

    return elems
end

local ReadWithContext = function(context, tableConfig, keyType, identifier, path)
    local file = assert(context)
    local iter = stringSplit(file, "\r\n") --每一行内容
    local names = Split(iter[1])
     -- 表头
    local keys = {} --存储某一列字典类型的键值
    local cols = #names
    local keyIndexTable = {}
    local j = 1

    CurrentPath = path

    -- 表头解析和检查
    for i = 1, cols do
        local name = names[i]
        local key
        local startIndex = stringFind(name, "[[]")
        if startIndex and startIndex > 0 then
            local endIndex = stringFind(name, "[]]")
            if startIndex ~= endIndex and endIndex == #name then -- 处理数组表头
                key = stringSub(name, startIndex + 1, endIndex - 1) --Dic key Array[2]中的 2
                name = stringSub(name, 1, startIndex - 1)
                names[i] = name --Id Name Array[1] Array[2] ->Id Name Array Array
                if not keyIndexTable[name] then
                    keyIndexTable[name] = j
                    j = j + 1
                end
            else
                XLog.Error(
                    "XTableManager.ReadTabFile 函数错误, 读取数据失败, 路径是 = " ..
                        path .. ", 名字 = " .. name .. ", 开始索引 = " .. startIndex .. ", 结束索引 = " .. endIndex
                )
                return
            end
        else
            keyIndexTable[name] = j
            j = j + 1
        end

        -- 检查属性是否有配置
        local paramConfig = tableConfig[name]
        if not paramConfig then
            goto continue
        end

        -- 字典类型处理
        if IsDictionary(paramConfig) then
            if not key then
                XLog.Error("XTableManager.ReadTabFile 函数错误: 读取数据失败，路径 = " .. path .. ", name = " .. name)
                return
            end

            local ret = GetDictionaryKey(paramConfig.KeyType, key) --Array[key] 吧key转成目标类型
            if not ret then
                XLog.Error(
                    "XTableManager.ReadTabFile 函数错误: 读取数据失败，路径 = " ..
                        path .. ", name = " .. name .. ", type = " .. paramConfig.KeyType .. ", key = " .. key
                )
                return
            end

            keys[i] = ret
        end

        ::continue::
    end
    ---每一个表对应一个元表
    local metaTable = {}

    metaTable.__index = function(tbl, keyIndex)
        local idx = keyIndexTable[keyIndex]

        if not idx or not tbl then
            return nil
        end

        local result = rawget(tbl, idx)
        local resultType = tableConfig[keyIndex]

        if not resultType then
            XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", keyIndex))
            return nil
        end

        if not result then
            if resultType and IsTable(resultType) then
                result = EmptyTable
            else
                result = DefaultOfType[resultType.ValueType]
            end
        end

        return result
    end

    metaTable.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    metaTable.__metatable = "readonly table"

    metaTable.__pairs = function(t)
        local function stateless_iter(tbl, key)
            local nk = next(tbl, key)

            if nk and type(nk) == "string" then
                local k = keyIndexTable[nk]
                local nv = t[k] or t[nk]
                return nk, nv
            end
        end

        return stateless_iter, tableConfig, nil
    end

    local createTable = function()
        local tab = {}
        local index = 1
        local lineCount = #iter
        for i = 2, lineCount do -- 遍历每一行表内容
            local line = iter[i]

            if not line or #line == 0 then
                goto nextLine
            end

            local elemArray = {}
            local elems = {} --CreateColElems(tableConfig) --存储每一列类型的默认值
            local tmpElems = Split(line) --分割每一行内容，\t
            --如果表头长度和内容长度匹配不上
            if #tmpElems ~= cols then
                XLog.Warning(
                    "XTableManager.ReadTabFile warning: cols not match, path = " ..
                        path .. ", row = " .. index .. ", cols = " .. cols .. ", cells length = " .. #tmpElems
                )
            end
            CurrentRow = i
            for i2 = 1, cols do
                local name = names[i2] --表头键值
                local value = tmpElems[i2] -- 单元格内容
                local paramConfig = tableConfig[name] --单元格类型
                CurrentKey = name
                CurrentValue = value
                CurrentCol = i2
                if paramConfig then
                    --如果是列表
                    if IsList(paramConfig) then -- 数组
                        value = GetContainerValue(paramConfig.ValueType, value) --单元格字符串转换成目标类型
                        if not elems[name] or not next(elems[name]) then
                            elems[name] = {}
                            if NeedSetReadonly then
                                setmetatable(elems[name], ReadOnlyTable)
                            end
                        end

                        if value then
                            local len = #elems[name]
                            rawset(elems[name], len + 1, value)
                        end
                    elseif IsDictionary(paramConfig) then -- 字典
                        value = GetContainerValue(paramConfig.ValueType, value)
                        if not elems[name] or not next(elems[name]) then
                            elems[name] = {}

                            if NeedSetReadonly then
                                setmetatable(elems[name], ReadOnlyTable)
                            end
                        end

                        if value then
                            local key = keys[i2]
                            rawset(elems[name], key, value)
                        end
                    else
                        elems[name] = GetSingleValueNew(paramConfig.ValueType, value)
                    end

                    elemArray[keyIndexTable[name]] = elems[name]
                --else
                --- XLog.Warning(string.format("表格%s 没有导出XTable.lua ,没找到Key：%s", path, name))
                end
            end

            if identifier then
                local mainKey = elems[identifier]
                if not mainKey then
                    XLog.Warning(
                        "表格有空行, path = " ..
                            path .. ", row = " .. index .. ", cols = " .. cols .. ", cells length = " .. #tmpElems
                    )
                    goto nextLine
                end

                local id = keyType == READ_KEY_TYPE.STRING and tostring(mainKey) or mathFloor(mainKey)
                tab[id] = elemArray
            else
                tab[index] = elemArray
            end

            setmetatable(elemArray, metaTable)

            index = index + 1

            ::nextLine::
        end
        return tab
    end

    local tab
    if IsEditorDebug then
        local status, _ = xpcall(function() tab = createTable() end, function(err)
            XLog.Error(err)
        end)
        if not status then
            local err = string.format("出错配置:" .. tostring(CurrentPath) .. ", 行:" .. tostring(CurrentRow).. ", 列:" .. tostring(CurrentCol) .. ", 字段:" .. tostring(CurrentKey) .. ", 报错内容:" .. tostring(CurrentValue))
            XLog.Error(err)
            XUiManager.TipMsg(err)
        end
    else
        tab = createTable()
    end
    return tab
end

local ReadTabFile = function(path, tableConfig, keyType, identifier)
    loadFileProfiler:Start()
    local context = CS.XTableManager.Load(path)
    loadFileProfiler:Stop()

    readTabFileProfiler:Start()
    local content = ReadWithContext(context, tableConfig, keyType, identifier, path)
    readTabFileProfiler:Stop()

    return content
end

--============= 内部读表函数 ============
local function ReadTable(path, identifier)
    if not identifier then
        XLog.Error(string.format("%s,identifier is null", path))
        return
    end

    local tab = {}
    local bin = Binary.ReadHandle(path)
    if not bin then
        return tab
    end

    AllTables[path] = bin
    local len = bin:GetLength()
    local mate = {}
    mate.__index = function(tab, key)
        if not key then
            return nil
        end

        if not bin then
            return
        end

        local data = bin:Get(key)
        return data
    end

    mate.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    mate.__metatable = "readonly table"

    mate.__len = function(t)
        return len
    end

    mate.__pairs = function(t)
        if bin and bin.cachesCount ~= len then
            local tt = bin:ReadAllContent(identifier)
        end

        local function stateless_iter(tbl, key)
            local nk, nv = next(tbl, key)
            return nk, nv
        end

        return stateless_iter, bin.caches, nil
    end

    setmetatable(tab, mate)
    return tab
end

local function ReadTableAll(path, identifier)
    local tab = Binary.ReadAll(path, identifier)
    return tab
end

local function ReadByStringKeyFromTab(path, xtable, identifier)
    if path == nil or #path == 0 then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 配置表的路径不能为空, path: " .. path)
        return
    end

    if xtable == nil then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 必须根据此配置表在xtable中定义相应的字段, 配置表路径: " .. path)
        return
    end

    if identifier == nil or #identifier == 0 then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 参数identifier不能为空, path: " .. path)
        return
    end

    if string.EndsWith(path, ".tab") then
        return ReadTabFile(path, xtable, READ_KEY_TYPE.STRING, identifier)
    end

    local paths = CS.XTableManager.GetPaths(path)
    local mergeTable = {}

    XTool.LoopCollection(
        paths,
        function(tmpPath)
            local t = ReadTabFile(tmpPath, xtable, READ_KEY_TYPE.STRING, identifier)
            for k, v in pairs(t) do
                if mergeTable[k] then
                    XLog.Error(
                        "XTableManager ReadByStringKey函数错误, 配置表项键值重复检查配置表, 路径: " ..
                            tmpPath .. ", identifier: " .. identifier .. ", key: " .. k
                    )
                    return
                end
                mergeTable[k] = v
            end
        end
    )

    return mergeTable
end

local function ReadByIntKeyFromTab(path, xtable, identifier)
    if path == nil or #path == 0 then
        XLog.Error("XTableManager ReadByIntKey 函数错误, 表的路径不能为空Path: " .. xtable)
        return
    end

    if xtable == nil then
        XLog.Error("XTableManager ReadByIntKey 函数错误, 配置表需要在xtable中定义相应的字段, 路径是: " .. path)
        return
    end

    if string.EndsWith(path, ".tab") then
        local t = ReadTabFile(path, xtable, READ_KEY_TYPE.INT, identifier)
        return t
    end

    local paths = CS.XTableManager.GetPaths(path)
    local mergeTable = {}

    XTool.LoopCollection(
        paths,
        function(tmpPath)
            local t = ReadTabFile(tmpPath, xtable, READ_KEY_TYPE.INT, identifier)
            for k, v in pairs(t) do
                if mergeTable[k] then
                    XLog.Error(
                        "XTableManager ReadByIntKey 函数错误, 配置表项键值重复检查配置表, 路径: " ..
                            tmpPath .. ", identifier: " .. identifier .. ", key: " .. k
                    )
                    return
                end
                mergeTable[k] = v
            end
        end
    )

    return mergeTable
end

--============= 外部函数 ============
function XTableManager.ReadAllByIntKey(path, xtable, identifier)
    if UseBytes then
        return ReadTableAll(path, identifier)
    end

    return ReadByIntKeyFromTab(path, xtable, identifier)
end

function XTableManager.ReadAllByStringKey(path, xtable, identifier)
    if UseBytes then
        return ReadTableAll(path, identifier)
    end

    return ReadByStringKeyFromTab(path, xtable, identifier)
end

function XTableManager.ReadByStringKey(path, xtable, identifier)
    if UseBytes then
        local t = nil

        CS.PrefProfiler.ProfilerCore.BeginSample(path, 2)

        if not identifier then
            t = ReadTableAll(path)
        else
            t = ReadTable(path, identifier)
        end
        CS.PrefProfiler.ProfilerCore.EndSample(path, 2)

        return t
    end

    return ReadByStringKeyFromTab(path, xtable, identifier)
end

function XTableManager.ReadByIntKey(path, xtable, identifier)
    if UseBytes then
        local t = nil

        CS.PrefProfiler.ProfilerCore.BeginSample(path, 2)

        if not identifier then
            t = ReadTableAll(path)
        else
            t = ReadTable(path, identifier)
        end

        CS.PrefProfiler.ProfilerCore.EndSample(path, 2)

        return t
    end

    return ReadByIntKeyFromTab(path, xtable, identifier)
end

function XTableManager.ReadArray(path, xtable, identifier)
    return XTableManager.ReadByIntKey(path, xtable)
end

function XTableManager.ReadByIntKeyWithContent(context, xtable, identifier)
    return ReadWithContext(context, xtable, READ_KEY_TYPE.INT, identifier, "unknown")
end

function XTableManager.ReadByStringKeyWithContent(context, xtable, identifier)
    return ReadWithContext(context, xtable, READ_KEY_TYPE.STRING, identifier, "unknown")
end

function XTableManager.ReleaseAll(uload)
    for k, v in pairs(AllTables) do
        v:Release(uload)
    end
end

function XTableManager.Close(path)
    local t = AllTables[path]
    if t then
        t:Close()
        t = nil
    end
    AllTables[path] = nil
end

function XTableManager.GetTypeDefaultValue(type)
    return DefaultOfType[type]
end

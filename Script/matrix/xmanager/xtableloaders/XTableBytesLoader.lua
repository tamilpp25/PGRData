local loader = {}

local BinaryTable = require("Binary/BinaryTable")

local AllTables = {}

local EmptyTable = {}

local function ReadTableAll(path, identifier)
    local tab = BinaryTable.ReadAll(path, identifier)
    return tab
end

--============= 内部读表函数 ============
local function ReadTable(path, identifier)
    if not identifier then
        XLog.Error(string.format("%s,identifier is null", path))
        return
    end

    local bin = BinaryTable.ReadHandle(path)
    if not bin then
        return EmptyTable
    end

    if bin.primarykey ~= identifier then
        XLog.Error("表格 " .. path .. " 读取Id与主键不一致，已改为强制读取模式，请按主键索引, 强制读取会带来较大性能损失")
        return ReadTableAll(path, identifier)
    end

    local tab = {}

    AllTables[path] = bin
    local len = bin:GetRowCount()
    local meta = {}
    meta.__index = function(tab, key)
        if not key then
            return nil
        end

        if not bin then
            return
        end

        local data = bin:Get(key)
        return data
    end

    meta.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    meta.__metatable = "readonly table"

    meta.__len = function(t)
        return len
    end

    meta.__pairs = function(t)
        if bin and bin.cachesCount ~= len then
            local tt = bin:ReadAllContent(identifier, true)
        end

        local function stateless_iter(tbl, key)
            local nk, nv = next(tbl, key)
            return nk, nv
        end

        return stateless_iter, bin.caches, nil
    end

    local rowCnt = bin:GetRowCount()
    if rowCnt ~= 0 then
        tab.__tableCount = rowCnt
    end

    setmetatable(tab, meta)

    return tab
end


function loader.ReadAllByIntKey(path, xTable, identifier)
    return ReadTableAll(path, identifier)
end

function loader.ReadAllByStringKey(path, xTable, identifier)
    return ReadTableAll(path, identifier)
end

function loader.ReadByIntKey(path, xTable, identifier)
    local t = nil
    if not identifier then
        t = ReadTableAll(path)
    else
        t = ReadTable(path, identifier)
    end
    return t
end

function loader.ReadByStringKey(path, xTable, identifier)
    local t = nil
    if not identifier then
        t = ReadTableAll(path)
    else
        t = ReadTable(path, identifier)
    end
    return t
end

function loader.ReleaseCache()
    for _, v in pairs(AllTables) do
        v:ReleaseCache()
    end
end

function loader.ReleaseFull(path)
    local v = AllTables[path]
    if not v then
        return
    end
    v:ReleaseFull()
    AllTables[path] = nil
end


function loader.ReadArray(path, xTable, identifier)
    return nil
end

return loader;
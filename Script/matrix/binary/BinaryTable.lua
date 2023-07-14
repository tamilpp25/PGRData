local BinaryTable = {}
local Binary = require("Binary/Binary")
local tableEmpty = {}

local BinaryPool = {}
local BINARY_LIMIT_COUNT = 10

local Reader = require("Binary/Reader")


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
    [15] = 0,
}


function BinaryTable.New(path)
    local temp = {}
    setmetatable(temp, { __index = BinaryTable })
    temp:Ctor(path)
    return temp
end

function BinaryTable:Ctor(path)
    self.filePath = path
    self.canRead = false
end

--读取全部
function BinaryTable.ReadAll(path, identifier)
    local temp = BinaryTable.New(path)

    if not temp or not temp:InitBinary() then
        return
    end

    local tab = temp:ReadAllContent(identifier)

    temp:Release(true)
    temp = nil

    return tab
end

--读取句柄
function BinaryTable.ReadHandle(path)
    local temp = BinaryTable.New(path)

    if not temp or not temp:InitBinary() then
        return
    end

    return temp
end



function BinaryTable:InitBinary()

    local bytes = CS.BinaryManager.LoadBytes(self.filePath)

    if not bytes then
        XLog.Error(string.format("BinaryTable.InitBinary 加载文件失败 %s", self.filePath))
        return
    end

    self.len = string.len(bytes)
    self.bytes = bytes
    local result = self:Init()

    CS.PrefProfiler.ProfilerCore.RecordTableBinaryLoad(self.filePath, self.len, self.row)

    return result
end

--初始化基础信息
function BinaryTable:Init()
    local reader = self:GetReader()


    local len = reader:ReadIntFix()
    self.col = reader:ReadInt()
    self.infoTrunkLen = len

    self.colTypes = {}
    self.colNames = {}
    for i = 1, self.col do
        table.insert(self.colTypes, reader:ReadInt())
        local name = reader:ReadString()
        table.insert(self.colNames, name)
    end

    local hasPrimarykey = reader:ReadBool()
    self.primarykeyCount = 0

    if hasPrimarykey then
        self.primarykeyCount = 1
        self.primarykey = reader:ReadString()
        self.primarykeyLen = reader:ReadInt()
    end

    for i = 1, #self.colNames do
        local name = self.colNames[i]
        if self.primarykey == name then
            self.primarykeyType = self.colTypes[i]
        end
    end

    self.rowTrunkLen = reader:ReadInt()
    self.row = reader:ReadInt()
    self.contentTrunkLen = reader:ReadInt()

    if not self.contentTrunkLen then
        if XMain.IsDebug then
            XLog.Warning(string.format("BinaryTable:InitBinary,%s, 空表", self.filePath))
        end
        return
    end

    local position = self:GetContenTrunkPosition()

    reader:Close()
    reader = nil

    self.canRead = true
    self.caches = {}
    self.cachesCount = 0


    return true
end


--获取内容块
function BinaryTable:GetContentTrunkReader()
    local position = self:GetContenTrunkPosition()

    if position < 0 then
        return
    end

    local reader = self:GetReader(position)
    return reader
end

--获取内容块位置
function BinaryTable:GetContenTrunkPosition()
    local position = self.infoTrunkLen + 4
    local count = self.primarykeyCount

    if count > 0 then
        position = position + self.primarykeyLen
    end

    position = position + self.rowTrunkLen
    return position
end

function BinaryTable:ReadAllContent(identifier)

    local reader = self:GetContentTrunkReader()

    if not reader then
        XLog.Error(string.format("可能是空表 路径:%s 请检查",    self.filePath))
        return tableEmpty
    end

    local row = self.row
    local col = self.col
    local colType = self.colTypes
    local colNames = self.colNames

    local colNameIndex = {}

    local index = 0
    for i = 1, #colNames do
        local name = colNames[i]
        if name == identifier then
            index = i
        end
        colNameIndex[name] = i
    end

    if index <= 0 then
        XLog.Warning(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", self.filePath))
    end

    ---每一个表对应一个元表
    local metaTable = {}

    metaTable.__index = function(tbl, colName)
        local idx = colNameIndex[colName]

        if not idx or not tbl then
            return nil
        end

        local result = rawget(tbl, idx)

        if not result then
            local resultType = colType[idx]

            if not resultType then
                XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", colName))
            end

            result = DefaultOfTypeNew[resultType]
        end


        return result
    end

    metaTable.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    metaTable.__metatable = "readonly table"


    metaTable.__pairs = function(t)
        local function stateless_iter(tbl, key)
            local nk, v = next(tbl, key)

            if nk and v then
                local nv = t[v] or t[nk]
                return nk, nv
            end
        end

        return stateless_iter, colNameIndex, nil
    end

    local tab = {}
    for i = 1, row do
        local temp = {}
        local keyValue = nil
        for j = 1, col do
            local type = colType[j]
            local value = reader:Read(type)
            temp[j] = value
            if index > 0 and j == index then
                keyValue = value or 0
            end

        end

        if index == 0 then
            keyValue = i
        end

        setmetatable(temp, metaTable)
        tab[keyValue] = temp

        self.caches[keyValue] = temp
        CS.PrefProfiler.ProfilerCore.RecordGetTableBinaryItem(self.filePath)
    end

    self.cachesCount = self.row
    reader:Close()
    reader = nil

    return tab
end

function BinaryTable:GetLength()
    return self.row
end

function BinaryTable:Get(key)
    local v = self.caches[key]
    if v then
        return v
    end

    local t = self:ReadElement(key)
    self.caches[key] = t
    if t ~= nil then
        self.cachesCount = self.cachesCount + 1
    end
    CS.PrefProfiler.ProfilerCore.RecordGetTableBinaryItem(self.filePath)

    return t
end

--读取内存块
function BinaryTable:GetReader(offset)

    if not self.bytes then
        self.bytes = CS.BinaryManager.LoadBytes(self.filePath)
        CS.PrefProfiler.ProfilerCore.RecordTableBinaryLoad(self.filePath, self.len, self.row)
    end

    offset = offset or 0
    local reader = Reader.New(self.bytes, self.len, offset + 1)
    return reader
end

--读取索引块
function BinaryTable:ReadIndexTrunk()

    local len = self.primarykeyLen
    local position = self.infoTrunkLen + 4

    if len <= 0 or position < 0 then
        XLog.Error(string.format("%s,读取索引块失败!! primarykey = %s", self.filePath, self.primarykey))
        return
    end

    self.primarykeyList = {}

    local reader = self:GetReader(position)
    for i = 1, self.row do
        local temp = reader:Read(self.primarykeyType) or 0
        self.primarykeyList[temp] = i
        --table.insert(self.primarykeyList, temp)
    end

    reader:Close()
    return true
end


-- 读取每行的位置和长度
function BinaryTable:ReadRowInfoTrunk()

    local len = self.rowTrunkLen
    local position = self.infoTrunkLen + 4

    if self.primarykeyCount > 0 then
        position = position + self.primarykeyLen
    end

    if len <= 0 or position < 0 then
        XLog.Error(string.format("%s,BinaryTable:ReadRowInfoTrunk 读取行位置块失败！", self.filePath))
        return
    end

    self.rowInfoArray = {}
    local reader = self:GetReader(position)
    for i = 1, self.row do

        local rowInfo = {}
        rowInfo.start = reader:ReadInt() or 0
        rowInfo.tail = reader:ReadInt() or 0
        table.insert(self.rowInfoArray, rowInfo)
    end

    reader:Close()
    reader = nil
end


--获取某一行信息
function BinaryTable:TryGetRowInfo(index)

    if not self.rowInfoArray then
        self:ReadRowInfoTrunk()
    end

    if not self.rowInfoArray or #self.rowInfoArray <= 0 then
        XLog.Error(string.format("%s,BinaryTable:TryGetRowInfo 读取行位置数据失败", self.filePath))
        return
    end

    if index > #self.rowInfoArray then
        XLog.Error(string.format("%s,BinaryTable:TryGetRowInfo 超出总行数长度 : %s 查询长度 : %s", self.filePath, #self.rowInfoArray, index))
        return
    end

    return self.rowInfoArray[index]
end

--读取条目
function BinaryTable:ReadElement(value)

    if not self.primarykey then
        XLog.Error(string.format("%s,主键未初始化 ", self.filePath))
        return nil
    end

    if not self.primarykeyList then
        self:ReadIndexTrunk()
    end

    local element = nil
    local index = self.primarykeyList[value]
    if index then
        local info = self:TryGetRowInfo(index)
        element = self:ReadElementInner(info, index, value)
    end

    if not element then
        --  XLog.Warning(string.format("%s,BinaryTable:ReadElement,查询失败，未找到条目 %s = %s", self.filePath, self.primarykey, value))
        return
    end

    return element
end

function BinaryTable:ReadRow(info, offset)

    if info.start < 0 or info.tail <= 0 then
        XLog.Error(string.format("%s,BinaryTable:ReadRow,行数据异常 %s = %s", self.filePath, info.start, info.tail))
        return
    end

    local len = info.tail - info.start
    local startIndex = offset + info.start

    local reader = self:GetReader(startIndex)
    return reader
end


function BinaryTable:ReadElementInner(info, index, value)

    local position = self:GetContenTrunkPosition()
    local reader = self:ReadRow(info, position)
    if not reader then
        XLog.Warning(string.format("%s,BinaryTable:ReadElementInner,查询数据失败 %s = %s", self.filePath, self.primarykey, value))
        return
    end

    local colType = self.colTypes
    local colNames = self.colNames

    self.colNameIndex = {}

    for i = 1, #colNames do
        local name = colNames[i]
        self.colNameIndex[name] = i
    end

    ---每一个表对应一个元表
    local metaTable = {}

    metaTable.__index = function(tbl, colName)
        local idx = self.colNameIndex[colName]

        if not idx or not tbl then
            return nil
        end

        local result = rawget(tbl, idx)

        if not result then
            local resultType = colType[idx]

            if not resultType then
                XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", colName))
            end

            result = DefaultOfTypeNew[resultType]
        end


        return result
    end

    metaTable.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    metaTable.__metatable = "readonly table"


    metaTable.__pairs = function(t)
        local function stateless_iter(tbl, key)
            local nk, v = next(tbl, key)

            if nk and v then
                local nv = t[v] or t[nk]
                return nk, nv
            end
        end

        return stateless_iter, self.colNameIndex, nil
    end

    local temp = {}
    local keyValue = nil

    for j = 1, self.col do
        local type = colType[j]
        local value = reader:Read(type)
        temp[j] = value
    end

    setmetatable(temp, metaTable)

    reader:Close()
    reader = nil
    return temp
end


function BinaryTable:Release(uload)

    CS.PrefProfiler.ProfilerCore.RecordTableBinaryUnload(self.filePath, uload and true or false)

    if uload then
        self.bytes = nil
    end

    self.caches = {}
    self.cachesCount = 0
end


function BinaryTable:Close()
    self.bytes = nil
end

return BinaryTable
local BinaryManager = CS.BinaryManager
local BinaryTable = {}
local tableEmpty = {}

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
    self.FilePath = path
end

--读取全部
function BinaryTable.ReadAll(path, identifier)
    local bt = BinaryTable.ReadHandle(path)

    if not bt then
        return nil
    end

    local tab = bt:ReadAllContent(identifier)

    bt:ReleaseFull()
    bt = nil

    return tab
end

--读取句柄
function BinaryTable.ReadHandle(path)
    local bt = BinaryTable.New(path)

    if not bt or not bt:InitBinary() then
        return nil
    end

    return bt
end

function BinaryTable:InitBinary()
    self.Bytes = BinaryManager.LoadBytes(self.FilePath)

    if not self.Bytes then
        XLog.Error(string.format("BinaryTable.InitBinary 加载文件失败 %s", self.FilePath))
        return nil
    end
    self.Length = string.len(self.Bytes)

    local result = self:Init()
    return result
end

function BinaryTable:__ReadInt()
    if self.Length < 4 then
        XLog.Error(string.format("%s ReadInt Error, file might be empty", self.FilePath))
        return 0
    end
    local b1, b2, b3, b4 = string.byte(self.Bytes, 1, 4)
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

function BinaryTable:__GetReader(len, offset)
    offset = offset or 0
    if offset + len > self.Length then
        XLog.Error(string.format("%s GetReader out of range exception", self.FilePath))
        return nil
    end
    local reader = ReaderPool.GetReader()
    reader:LoadBytes(self.Bytes, len, offset + 1)
    return reader
end

function BinaryTable:InitMetaTable()
    local colType = self.colTypes
    local colNames = self.colNames

    local colNameIndex = {}

    for i = 1, #colNames do
        local name = colNames[i]
        colNameIndex[name] = i
    end

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

    self.MetaTable = metaTable
end

--初始化表头
function BinaryTable:Init()
    local len = self:__ReadInt()
    local reader = self:__GetReader(len, 4)

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
            XLog.Warning(string.format("BinaryTable:InitBinary,%s, 空表", self.FilePath))
        end
        self:__CloseReader(reader)
        return
    end

    self:InitMetaTable()
    self:__CloseReader(reader)
    self.caches = {}
    self.cachesCount = 0

    return true
end

--获取内容块
function BinaryTable:GetContentTrunkReader()
    local position = self:GetContentTrunkPosition()

    if position < 0 then
        return
    end

    local reader = self:__GetReader(self.contentTrunkLen, position)
    return reader
end

--获取内容块位置
function BinaryTable:GetContentTrunkPosition()
    local position = self.infoTrunkLen + 4
    local count = self.primarykeyCount

    if count > 0 then
        position = position + self.primarykeyLen
    end

    position = position + self.rowTrunkLen
    return position
end

function BinaryTable:ReadAllContent(identifier)
    --if self.Bytes == nil then
    --    XLog.Error("Re Open All")
    --    self:InitBinary()
    --    if self.Bytes == nil then
    --        return tableEmpty
    --    end
    --end

    local reader = self:GetContentTrunkReader()

    if not reader then
        XLog.Error(string.format("可能是空表 路径:%s 请检查", self.FilePath))
        return tableEmpty
    end

    local row = self.row
    local col = self.col
    local colType = self.colTypes
    local colNames = self.colNames

    local index = 0
    for i = 1, #colNames do
        local name = colNames[i]
        if name == identifier then
            index = i
        end
    end

    if index <= 0 then
        XLog.Warning(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", self.FilePath))
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

        setmetatable(temp, self.MetaTable)
        tab[keyValue] = temp

        self.caches[keyValue] = temp
    end

    self.cachesCount = self.row
    self:__CloseReader(reader)
    return tab
end

function BinaryTable:__CloseReader(reader)
    ReaderPool.ReleaseReader(reader)
end

function BinaryTable:GetRowCount()
    return self.row
end

function BinaryTable:Get(key)
    local v = self.caches[key]
    if v then
        return v
    end

    --if self.Bytes == nil then
    --    XLog.Error("Re Open Get")
    --    self:InitBinary()
    --    if self.Bytes == nil then
    --        return nil
    --    end
    --end

    local t = self:ReadElement(key)

    self.caches[key] = t

    if t ~= nil then
        self.cachesCount = self.cachesCount + 1
    end

    return t
end

--读取索引块
function BinaryTable:ReadIndexTrunk()

    local len = self.primarykeyLen
    local position = self.infoTrunkLen + 4

    if len <= 0 or position < 0 then
        XLog.Error(string.format("%s,读取索引块失败!! primarykey = %s", self.FilePath, self.primarykey))
        return
    end

    self.primaryKeyList = {}

    local reader = self:__GetReader(len, position)
    for i = 1, self.row do
        local temp = reader:Read(self.primarykeyType) or 0
        self.primaryKeyList[temp] = i
    end

    self:__CloseReader(reader)
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
        XLog.Error(string.format("%s,BinaryTable:ReadRowInfoTrunk 读取行位置块失败！", self.FilePath))
        return
    end

    self.rowInfoStartArray = {}
    self.rowInfoTailArray = {}
    local reader = self:__GetReader(len, position)
    for _ = 1, self.row do
        table.insert(self.rowInfoStartArray, reader:ReadInt() or 0)
        table.insert(self.rowInfoTailArray, reader:ReadInt() or 0)
    end
    self:__CloseReader(reader)
end


--获取某一行信息
function BinaryTable:TryGetRowInfo(index)

    if not self.rowInfoStartArray then
        self:ReadRowInfoTrunk()
    end

    if not self.rowInfoStartArray or #self.rowInfoStartArray <= 0 then
        XLog.Error(string.format("%s,BinaryTable:TryGetRowInfo 读取行位置数据失败", self.FilePath))
        return
    end

    if index > #self.rowInfoStartArray then
        XLog.Error(string.format("%s,BinaryTable:TryGetRowInfo 超出总行数长度 : %s 查询长度 : %s", self.FilePath, #self.rowInfoStartArray, index))
        return
    end

    return self.rowInfoStartArray[index], self.rowInfoTailArray[index]
end

--读取条目
function BinaryTable:ReadElement(key)

    if not self.primarykey then
        XLog.Error(string.format("%s,主键未初始化 ", self.FilePath))
        return nil
    end

    if not self.primaryKeyList then
        self:ReadIndexTrunk()
    end

    local element = nil
    local index = self.primaryKeyList[key]
    if index then
        local start, tail = self:TryGetRowInfo(index)
        element = self:ReadElementInner(start, tail, index, key)
    end

    if not element then
        --  XLog.Warning(string.format("%s,BinaryTable:ReadElement,查询失败，未找到条目 %s = %s", self.filePath, self.primarykey, value))
        return
    end

    return element
end

function BinaryTable:ReadRow(start, tail, offset)

    if start < 0 or tail <= 0 then
        XLog.Error(string.format("%s,BinaryTable:ReadRow,行数据异常 %s = %s", self.FilePath, start, tail))
        return
    end

    local len = tail - start
    local startIndex = offset + start

    local reader = self:__GetReader(len, startIndex)
    return reader
end


function BinaryTable:ReadElementInner(start, tail, index, keyName)

    local position = self:GetContentTrunkPosition()
    local reader = self:ReadRow(start, tail, position)
    if not reader then
        XLog.Warning(string.format("%s,BinaryTable:ReadElementInner,查询数据失败 %s = %s", self.FilePath, self.primarykey, keyName))
        return
    end

    local colType = self.colTypes

    local temp = {}

    for j = 1, self.col do
        local type = colType[j]
        local value = reader:Read(type)
        temp[j] = value
    end

    setmetatable(temp, self.MetaTable)

    self:__CloseReader(reader)
    return temp
end


function BinaryTable:ReleaseCache()
    self.caches = {}
    self.cachesCount = 0
end

function BinaryTable:ReleaseFull()
    self.caches = {}
    self.Bytes = nil
    self.cachesCount = 0
end


function BinaryTable:Close()

end

return BinaryTable

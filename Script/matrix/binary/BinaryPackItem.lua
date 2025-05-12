local tableEmpty = {} --TODO 这里要保护好不要被改写了

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

--Init接口
--InitHead 配置表的表头信息, 必须要
--InitMetaTable 每一行转化成lua对象的元表, 必须要
--InitPrimaryKeyList 读取主键列表, 按需读取需要
--InitRowOffset --每一行的偏移, 按需读取需要


---@class BinaryPackItem
local BinaryPackItem = {}


function BinaryPackItem.New(tabName, ownPack, offset, len)
    local temp = {}
    setmetatable(temp, { __index = BinaryPackItem })
    temp:Ctor(tabName, ownPack, offset, len)
    return temp
end

function BinaryPackItem:Ctor(tabName, ownPack, offset, len)
    --这里只是先记录一些加载数据的必要信息
    self._TabName = tabName
    ---@type BinaryPack
    self._OwnPack = ownPack
    self._Offset = offset
    self._Len = len

    self._HeadLen = 0
    self._Col = 0 --列数

    self._ColTypes = false
    self._ColNames = false
    self._ColNameIndex = false

    self._PrimaryKey = false --主键
    self._PrimaryIndex = 0 --主键的索引
    self._PrimaryKeyType = false --主键的数据类型
    self._PrimaryKeyList = false --所有主键的值
    self._PrimaryKeyLen = 0 --有主键值的话, 会记录所有的主键值

    self._RowOffsetLen = 0
    self._RowStartOffset = false
    self._RowTailOffset = false
    self._Row = 0 --有多少行数据
    self._ContentLen = 0 --所有数据的长度

    self._MetaTable = false
    self._Table = false

    --TODO: Caches也应该做成只读table
    self._Caches = {}
    self._CachesCount = 0
    self._IsInit = false
    self._IsReadAll = false
end

function BinaryPackItem:CheckInit()
    self._IsInit = true
    self:InitHead()
    self:InitMetaTable()
    if self._PrimaryKey ~= self._Identifier then
        XLog.Error("表格 " .. self._TabName .. " 读取Id与主键不一致，已改为强制读取模式，请按主键索引, 强制读取会带来较大性能损失")
        self:ReadAllContent(self._Identifier)
    end
end

function BinaryPackItem:CheckInitAndReadAll()
    if not self._IsInit then
        self:ReadAll(self._Identifier)
    elseif self._CachesCount ~= self._Row then
        self:ReadAllContent(self._Identifier)
    end
end

function BinaryPackItem:SetIdentifier(identifier)
    self._Identifier = identifier
end

function BinaryPackItem:InitTable(identifier)
    self._Identifier = identifier
    if not self._Table then
        local meta = {}
        meta.__index = function(tab, key)
            if not key then
                return nil
            end
            if not self._IsInit then
                self:CheckInit()
            end
            local data = self:Get(key)
            return data
        end

        meta.__newindex = function()
            XLog.Error("attempt to update a readonly table")
        end

        meta.__metatable = "readonly table"

        meta.__len = function(t)
            if not self._IsInit then
                self:CheckInit()
            end
            return self._Row
        end

        meta.__pairs = function(t)
            self:CheckInitAndReadAll()

            local function stateless_iter(tbl, key)
                local nk, nv = next(tbl, key)
                return nk, nv
            end

            return stateless_iter, self._Caches, nil
        end

        self._Table = {}

        setmetatable(self._Table, meta)
    end
    return self._Table
end

function BinaryPackItem:GetTable()
    return self._Table
end

function BinaryPackItem:GetCaches()
    return self._Caches
end

function BinaryPackItem:GetPrimaryKey()
    return self._PrimaryKey
end

---初始化表头信息
---@param reader CryptoReader
function BinaryPackItem:InitHead(reader)
    local needRelease = false
    if not reader then
        needRelease = true
        self._HeadLen = self._OwnPack:ReadIntFix(self._Offset) --先把头部的长度读出来
        reader = self._OwnPack:GetReader(self._Offset + 4, self._HeadLen)
    else
        self._HeadLen = reader:ReadIntFix()
    end

    local hasPrimaryKey = reader:ReadBool()
    if hasPrimaryKey then
        self._PrimaryKey = reader:ReadString()
        self._PrimaryKeyLen = reader:ReadInt() or 0
    end

    self._Col = reader:ReadInt() or 0
    self._ColTypes = {} --每一列的数据类型
    self._ColNames = {} --每一列的名字
    self._ColNameIndex = {} --key对应的下表

    local findKey = false
    for i = 1, self._Col do
        self._ColTypes[i] = reader:ReadInt() or 0
        local key = reader:ReadString()
        self._ColNames[i] = key
        self._ColNameIndex[key] = i
        if not findKey and key == self._PrimaryKey then
            self._PrimaryIndex = i
            self._PrimaryKeyType = self._ColTypes[i]
            findKey = true
        end
    end

    self._RowOffsetLen = reader:ReadInt() or 0 --这里其实记录每一行的起始位置和结束位置, 其实这里也是有优化空间的, 因为是密集数据, 只要记录最后一个即可
    self._Row = reader:ReadInt() or 0
    self._ContentLen = reader:ReadInt() --空表

    if not self._ContentLen then
        if XMain.IsDebug then
            XLog.Warning(string.format("BinaryPackItem:InitHead,%s, 空表", self._TabName))
        end
        self._Table = tableEmpty
    end
    if needRelease then
        CryptoReaderPool.ReleaseReader(reader)
    end
end

--初始化要转换的lua table对象基类
function BinaryPackItem:InitMetaTable()
    local colType = self._ColTypes
    local colNameIndex = self._ColNameIndex

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

    self._MetaTable = metaTable
end

--初始化主键列表
function BinaryPackItem:InitPrimaryKeyList()
    if self._PrimaryKeyLen == 0 then
        XLog.Error(string.format("%s,读取索引块失败!!", self._TabName))
        return
    end
    local offset = self._Offset + self._HeadLen + 4

    self._PrimaryKeyList = {}

    local reader = self._OwnPack:GetReader(offset, self._PrimaryKeyLen)
    for i = 1, self._Row do
        local key = reader:Read(self._PrimaryKeyType) or 0
        self._PrimaryKeyList[key] = i
    end

    CryptoReaderPool.ReleaseReader(reader)
end

--解析每一行的偏移及长度
function BinaryPackItem:InitRowOffset()
    local offset = self._Offset + self._HeadLen + self._PrimaryKeyLen + 4

    self._RowStartOffset = {}
    self._RowTailOffset = {}

    local reader = self._OwnPack:GetReader(offset, self._RowOffsetLen)
    local lastOffset = 0
    for i = 1, self._Row do
        self._RowStartOffset[i] = lastOffset
        lastOffset = reader:ReadInt() or 0
        self._RowTailOffset[i] = lastOffset
    end
    CryptoReaderPool.ReleaseReader(reader)
end

function BinaryPackItem:GetRowOffset(index)
    if not self._RowStartOffset then
        self:InitRowOffset()
    end
    return self._RowStartOffset[index], self._RowTailOffset[index]
end

--读取整张表, 包括头部信息
function BinaryPackItem:ReadAll(identifier)
    self._IsInit = true
    local reader = self._OwnPack:GetReader(self._Offset, self._Len) --一次性全部读出来
    self:InitHead(reader)
    if self._ContentLen then
        self:InitMetaTable()
        local tbl = self:ReadAllContent(identifier, reader)
        if not self._Table then
            self._Table = tbl
        end
    end
    CryptoReaderPool.ReleaseReader(reader)
end

--读取整个表的内容, 但不包含头部信息
---@param reader CryptoReader
function BinaryPackItem:ReadAllContent(identifier, reader)
    if self._IsReadAll then
        --XLog.Error("重复读取整表: " .. self._TabName)
    end
    self._IsReadAll = true
    local needRelease = false
    local offset = 0
    if reader then
        offset = self._HeadLen + self._PrimaryKeyLen + self._RowOffsetLen + 4 + 1
        reader:SetIndex(offset)
    else
        offset = self._Offset + self._HeadLen + self._PrimaryKeyLen + self._RowOffsetLen + 4
        reader = self._OwnPack:GetReader(offset, self._ContentLen)
        needRelease = true
    end

    local index = 0
    if identifier == self._PrimaryKey then
        index = self._PrimaryIndex
    else
        for i = 1, #self._ColNames do
            local name = self._ColNames[i]
            if identifier == name then
                index = i
                break
            end
        end
    end

    if index == 0 then
        XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", self._TabName))
    end

    local tbl = {}
    for i = 1, self._Row do
        local row = {}
        local keyValue = nil
        for j = 1, self._Col do
            local type = self._ColTypes[j]
            local value = reader:Read(type)
            row[j] = value
            if index > 0 and j == index then
                keyValue = value or 0
            end

        end

        if index == 0 then
            keyValue = i
        end

        setmetatable(row, self._MetaTable)

        --if self._Caches[keyValue] then
        --    XLog.Error("重复初始化: " .. self._TabName .. " :" .. keyValue)
        --end
        self._Caches[keyValue] = row
        tbl[keyValue] = row
    end

    self._CachesCount = self._Row
    if needRelease then
        CryptoReaderPool.ReleaseReader(reader)
    end
    return tbl
end

function BinaryPackItem:Get(key)
    local element = self._Caches[key]
    if element then
        return element
    end

    element = self:ReadElement(key)
    if element then
        self._Caches[key] = element
        self._CachesCount = self._CachesCount + 1
        return element
    end
end

function BinaryPackItem:ReadElement(key)
    if not self._PrimaryKey then
        XLog.Error(string.format("%s,主键未初始化 ", self._TabName))
        return nil
    end
    if not self._PrimaryKeyList then
        self:InitPrimaryKeyList()
    end

    local element = nil
    local index = self._PrimaryKeyList[key]
    if index then
        local start, tail = self:GetRowOffset(index)
        element = self:ReadSingleRow(start, tail)
    end
    return element
end

--读取一行的数据并转成lua 对象
function BinaryPackItem:ReadSingleRow(start, tail)
    local offset = self._Offset + self._HeadLen + self._PrimaryKeyLen + self._RowOffsetLen + 4
    local len = tail - start
    local start = offset + start

    local reader = self._OwnPack:GetReader(start, len)
    
    local row = {}

    for i = 1, self._Col do
        local type = self._ColTypes[i]
        local value = reader:Read(type)
        row[i] = value
    end

    setmetatable(row, self._MetaTable)
    CryptoReaderPool.ReleaseReader(reader)
    return row
end

function BinaryPackItem:ReleaseFull()
    self._Caches = nil
    self._CachesCount = 0
end

function BinaryPackItem:ReleaseCache()
    self._Caches = {}
    self._CachesCount = 0
end

function BinaryPackItem:TestCode()
    if self._PrimaryKey then
        local str = "table.insert(tbl, packLoader.ReadByIntKey(\"".. self._TabName .. "\", nil, \"" .. self._PrimaryKey.. "\"))\n"
        return str
    end
    return ""
end

return BinaryPackItem
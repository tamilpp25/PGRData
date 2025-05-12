--洁哥说这文件不用了

---@class CryptoReader
local CryptoReader = XClass(nil, "CryptoReader")
local ReadByType = {}
local MaxInt32 = 2147483647
local FloatToInt = 10000

function CryptoReader:Ctor()

end

function CryptoReader:LoadBytes(bytes, len, index)
    self.bytes = bytes
    self.len = len
    self.index = index or 1
end

---设置当前读取的位置
function CryptoReader:SetIndex(index)
    self.index = index
end

function CryptoReader:Close()
    self.bytes = nil
end

function CryptoReader:ConvertIndex(index)
    return self.len - index + 1
end


function CryptoReader:Read(type)
    return ReadByType[type](self)
end

function CryptoReader:ReadFloat()

    local num = self:ReadInt()
    if not num then
        return nil
    end

    num = num / 10000

    local a, b = math.modf(num) --拆分整数位和小数位
    if b == 0 then
        num = a
    end

    return num
end


function CryptoReader:ReadBool()
    local pos = self.len - self.index + 1
    local value = string.byte(self.bytes, pos, pos)
    self.index = self.index + 1
    return value == 1 and true or nil
end

--读取string
function CryptoReader:ReadString()
    local position = self.index
    local pos = self.len - position + 1
    local ass = string.byte(self.bytes, pos, pos)

    while ass > 0 do
        position = position + 1
        pos = self.len - position + 1
        ass = string.byte(self.bytes, pos, pos)
        if ass == nil then
            XLog.Error(string.format("读取字符串异常 postion = %s,len = %s index =%s", position, self.len, self.index))
        end
    end

    if position == self.index then
        self.index = self.index + 1
        return
    end

    local value = string.reverse(string.char(string.byte(self.bytes, self.len - position + 1 + 1, self.len - self.index + 1)))
    self.index = position + 1

    return value
end

function CryptoReader:ReadIntFix()
    local pos1 = self.len - self.index - 3 + 1
    local pos2 = self.len - self.index + 1
    local b1, b2, b3, b4 = string.byte(self.bytes, pos1, pos2)
    self.index = self.index + 4
    return b4 | b3 << 8 | b2 << 16 | b1 << 24 --这里调转顺序
end

function CryptoReader:ReadInt()
    return self:ReadInt32Variant()
end

function CryptoReader:ReadInt32Variant()
    return self:ReadUInt32Variant()
end

function CryptoReader:ReadUInt32Variant()
    local value = 0
    local tempByte
    local index = 0
    local pos

    while not tempByte or ((tempByte >> 7) > 0) do
        pos = self.len - self.index + 1
        tempByte = string.byte(self.bytes, pos, pos)
        local temp1 = (tempByte & 0x7F) << index
        value = value | temp1
        index = index + 7
        self.index = self.index + 1
    end

    --负数,MaxInt32 = 2147483647 因为lua number是64bit 所以需要特殊处理负数
    if value > MaxInt32 then
        value = -(((~ value) & MaxInt32) + 1)
    end

    if value == 0 then
        return nil
    end

    return value
end

function CryptoReader:ReadListString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadString())
    end

    return list
end


function CryptoReader:ReadListBool()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadBool())
    end

    return list
end


function CryptoReader:ReadListInt()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadInt() or 0)
    end

    return list
end

function CryptoReader:ReadListFloat()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFloat() or 0)
    end

    return list
end

function CryptoReader:ReadDicStringString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadString()
        local value = self:ReadString()
        dic[key] = value
    end

    return dic
end

function CryptoReader:ReadDicIntInt()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadInt() or 0
        dic[key] = value
    end

    return dic
end

function CryptoReader:ReadDicIntString()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadString()
        dic[key] = value
    end

    return dic
end


function CryptoReader:ReadDicStringInt()

    local len = self:ReadInt() or 0
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadString()
        local value = self:ReadInt()
        dic[key] = value
    end

    return dic
end

function CryptoReader:ReadDicIntFloat()

    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local dic = {}
    for i = 1, len do
        local key = self:ReadInt() or 0
        local value = self:ReadFloat()
        dic[key] = value
    end

    return dic
end

--读取Fix
function CryptoReader:ReadFix()
    local str = self:ReadString()
    if not str then
        return nil
    end

    return FixParse(str)
end

--读取Fix
function CryptoReader:ReadListFix()
    local len = self:ReadInt()
    if not len or len <= 0 then
        return nil
    end

    local list = {}
    for i = 1, len do
        table.insert(list, self:ReadFix())
    end

    return list
end


ReadByType = {
    [1] = CryptoReader.ReadBool,
    [2] = CryptoReader.ReadString,
    [3] = CryptoReader.ReadFix,
    [4] = CryptoReader.ReadListString,
    [5] = CryptoReader.ReadListBool,
    [6] = CryptoReader.ReadListInt,
    [7] = CryptoReader.ReadListFloat,
    [8] = CryptoReader.ReadListFix,
    [9] = CryptoReader.ReadDicStringString,
    [10] = CryptoReader.ReadDicIntInt,
    [11] = CryptoReader.ReadDicIntString,
    [12] = CryptoReader.ReadDicStringInt,
    [13] = CryptoReader.ReadDicIntFloat,
    [14] = CryptoReader.ReadInt,
    [15] = CryptoReader.ReadFloat,
}


return CryptoReader
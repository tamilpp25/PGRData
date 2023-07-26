local Reader = XClass(nil, "Reader")
local ReadByType = {}
local MaxInt32 = 2147483647
local FloatToInt = 10000

function Reader:Ctor()

end

function Reader:LoadBytes(bytes, len, index)
    self.bytes = bytes
    self.len = len
    self.index = index or 1
end

function Reader:Close()
    self.bytes = nil
end


function Reader:Read(type)
    return ReadByType[type](self)
end

function Reader:ReadFloat()

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
    --
    -- if self.index + 3 > self.len then
    --     return
    -- end
    -- local b1, b2, b3, b4 = string.byte(self.bytes, self.index, self.index + 3)
    -- self.index = self.index + 4
    -- local sign = b4 > 0x7F  --最高位符号位
    -- local expo = (b4 % 0x80) * 0x02 + math.floor(b3 / 0x80)  --整数部分 
    -- local mant = ((b3 % 0x80) * 0x100 + b2) * 0x100 + b1 --小数部分    
    -- if sign then
    --     sign = -1
    -- else
    --     sign = 1
    -- end
    -- local n
    -- if mant == 0 and expo == 0 then
    --     n = sign * 0
    -- elseif expo == 0xFF then
    --     if mant == 0 then
    --         n = sign * math.huge
    --     else
    --         n = nil
    --     end
    -- else
    --     if (expo > 0) and (expo < 0xFF) then
    --         n = sign * (1 + mant / 8388608) * (1 << (expo - 0x7F))
    --     else
    --         n = sign * (mant / 8388608) * (1 << 0x7F)
    --     end
    -- end
    -- return n
end


function Reader:ReadBool()
    local value = string.byte(self.bytes, self.index, self.index)
    self.index = self.index + 1
    return value == 1 and true or nil
end

--读取string
function Reader:ReadString()

    local postion = self.index
    local ass = string.byte(self.bytes, postion, postion)

    while ass > 0 do
        postion = postion + 1
        ass = string.byte(self.bytes, postion, postion)
        if ass == nil then
            XLog.Error(string.format("读取字符串异常 postion = %s,len = %s index =%s", postion, self.len, self.index))
        end
    end

    if postion == self.index then
        self.index = self.index + 1
        return
    end

    local value = string.char(string.byte(self.bytes, self.index, postion - 1))
    self.index = postion + 1

    return value
end

function Reader:ReadIntFix()
    self.index = self.index + 4
    local b1, b2, b3, b4 = string.byte(self.bytes, 1, 4)
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

function Reader:ReadInt()
    return self:ReadInt32Variant()
end

function Reader:ReadInt32Variant()
    return self:ReadUInt32Variant()
end

function Reader:ReadUInt32Variant()
    local value = 0
    local tempByte
    local index = 0

    while not tempByte or ((tempByte >> 7) > 0) do
        tempByte = string.byte(self.bytes, self.index, self.index)
        local temp1 = (tempByte & 0x7F) << index
        value = value | temp1
        index = index + 7
        self.index = self.index + 1
    end

    --负数,MaxInt32 = 2147483647 因为lua number是64bit 所以需要特殊处理负数
    if value > MaxInt32 then
        local newValue = 0
        value = -(((~ value) & MaxInt32) + 1)
    end

    if value == 0 then
        return nil
    end

    return value
end

function Reader:ReadListString()

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


function Reader:ReadListBool()

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


function Reader:ReadListInt()

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

function Reader:ReadListFloat()

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

function Reader:ReadDicStringString()

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

function Reader:ReadDicIntInt()

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

function Reader:ReadDicIntString()

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


function Reader:ReadDicStringInt()

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

function Reader:ReadDicIntFloat()

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
function Reader:ReadFix()
    local str = self:ReadString()
    if not str then
        return nil
    end

    return FixParse(str)
end

--读取Fix
function Reader:ReadListFix()
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
    [1] = Reader.ReadBool,
    [2] = Reader.ReadString,
    [3] = Reader.ReadFix,
    [4] = Reader.ReadListString,
    [5] = Reader.ReadListBool,
    [6] = Reader.ReadListInt,
    [7] = Reader.ReadListFloat,
    [8] = Reader.ReadListFix,
    [9] = Reader.ReadDicStringString,
    [10] = Reader.ReadDicIntInt,
    [11] = Reader.ReadDicIntString,
    [12] = Reader.ReadDicStringInt,
    [13] = Reader.ReadDicIntFloat,
    [14] = Reader.ReadInt,
    [15] = Reader.ReadFloat,
}


return Reader
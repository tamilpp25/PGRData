local Binary = {}
local Reader = require("Binary/Reader")
local OFFSET = 0


function Binary.New(path)
    local temp = {}
    setmetatable(temp, { __index = Binary })
    local result = temp:Ctor(path)
    if not result then
        return nil
    end

    return temp
end

function Binary:Ctor(path)
    local file, err = io.open(path, "rb")
    if not file then
        XLog.Error(string.format("Binary:Ctor 打开文件失败 %s ,%s", path, err))
        return
    end

    local len = assert(file:seek("end"))
    self.file = path
    self.len = len
    self.fileStream = file
    return true
end

--读取int默认4字节，其他类型暂时不管了
function Binary:ReadInt(position)
    position = position or 0
    if position >= self.len then
        XLog.Error(string.format("Binary.ReadInt 超出长度 %s，position = %s", self.len, position))
        return
    end

    local startPos = self:Seek("set", 0)
    local bytes = self:Read(4)
    if not bytes then
        return 0
    end

    local b1, b2, b3, b4 = string.byte(bytes, 1, 4)
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

--读取字节
function Binary:Read(len)
    local bytes, err = self.fileStream:read(len)

    if not bytes then
        XLog.Error(string.format("Binary.Read 读取二进制失败 len = %s,%s", len, err))
        return
    end

    return bytes
end

--读取内存块
function Binary:GetReader(len, offset)
    local bytes = self:ReadBytes(len, offset)
    local reader = Reader.New(bytes, len)

    return reader
end

--读取内存块
function Binary:ReadBytes(len, offset)
    if not len then
        XLog.Error(len)
    end

    if len >= self.len then
        XLog.Error(string.format("Binary.ReadBytes 超出长度 %s, len = %s", self.len, len))
        return
    end

    local startPos = self:Seek("set", offset)
    local bytes = self:Read(len)

    return bytes
end


--定位
function Binary:Seek(position, offset)
    offset = offset and offset + OFFSET or OFFSET
    local len, err = self.fileStream:seek(position, offset)

    if not len then
        XLog.Error(string.format("Binary.Seek 失败，offset = %s ,position = %s,%s", offset, position, err))
        return
    end

    return len
end


function Binary:ReadAll()
    local startPos = self:Seek("set", 0)
    local bytes = self:Read("*a")


    return bytes
end


function Binary:Close()
    self.fileStream:close()
    self.fileStream = nil
end

return Binary
local BinaryFile = {}
local OFFSET = 0

local BinaryPool = {}
local PoolCount = 0

function BinaryFile.New(path)
    local temp = {}
    setmetatable(temp, { __index = BinaryFile })
    local result = temp:Ctor(path)
    if not result then
        return nil
    end

    return temp
end

function BinaryFile:Ctor(path)
    self.file = path
    self:Open(path)
    return true
end

function BinaryFile:Open(path)
    local file, err = io.open(path, "rb")
    if not file then
        XLog.Error(string.format("Binary:Open 打开文件失败 %s ,%s", path, err))
        return
    end

    local len = assert(file:seek("end"))
    self.file = path
    self.len = len
    self.fileStream = file
    self.isClose = false

    if PoolCount >= 10 then
        local bin = table.remove(BinaryPool,PoolCount)
        bin:CloseFile()
        PoolCount = PoolCount-1
    end

    table.insert(BinaryPool,self)
    PoolCount = PoolCount+1

end

function BinaryFile:ReOpen()
    if not self.isClose then
        return
    end

    self:Open(self.file)
end

function BinaryFile:GetFileStream()
    if self.isClose then
    end
end

--读取int默认4字节，其他类型暂时不管了
function BinaryFile:ReadInt(position)
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
function BinaryFile:Read(len)
    local bytes, err = self.fileStream:read(len)

    if not bytes then
        XLog.Error(string.format("Binary.Read 读取二进制失败 len = %s,%s", len, err))
        return
    end

    return bytes
end

--读取内存块
function BinaryFile:GetReader(len, offset)

    if self.isClose then
        self:ReOpen()
    end

    local bytes = self:ReadBytes(len, offset)
    local reader = ReaderPool.GetReader()
    reader:LoadBytes(bytes, len)

    return reader
end

--读取内存块
function BinaryFile:ReadBytes(len, offset)
    if len >= self.len then
        XLog.Error(string.format("Binary.ReadBytes 超出长度 %s, len = %s", self.len, len))
        return
    end

    self:Seek("set", offset)
    local bytes = self:Read(len)
    return bytes
end


function BinaryFile:CloseReader(reader)
    reader:Close()
    table.insert(ReaderPool,reader)
end

--定位
function BinaryFile:Seek(position, offset)
    offset = offset and offset + OFFSET or OFFSET
    local len, err = self.fileStream:seek(position, offset)

    if not len then
        XLog.Error(string.format("Binary.Seek 失败，offset = %s ,position = %s,%s", offset, position, err))
        return
    end

    return len
end


function BinaryFile:ReadAll()
    self:Seek("set", 0)
    local bytes = self:Read("*a")
    return bytes
end

function BinaryFile:CloseFile()

    if self.isClose then
        return
    end

    self.fileStream:close()
    self.fileStream = nil
    self.isClose = true
end

function BinaryFile:Close()

    self:CloseFile()
    local index = -1
    for i,v in ipairs(BinaryPool) do
        if v.file == self.file then
            index = i
        end
    end

    if index > 0 then
        table.remove(BinaryPool,index)
        PoolCount = PoolCount-1
    end
end

function BinaryFile:GetLen()
    return self.len or 0
end

return BinaryFile
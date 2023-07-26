local BinaryBytes = {}
local BinaryManager = CS.BinaryManager

function BinaryBytes.New(filePath)
    local temp = {}
    setmetatable(temp, { __index = BinaryBytes })
    local res = temp:Ctor(filePath)
    if not res then
        return nil
    end
    return temp
end

function BinaryBytes:Ctor(filePath)
    local bytes = BinaryManager.LoadBytes(filePath)
    if bytes == nil then
        return false
    end
    self.Bytes = bytes
    self.Length = string.len(bytes)
    self.FilePath = filePath
    return true
end

function BinaryBytes:ReadInt()
    if self.Length < 4 then
        XLog.Error(string.format("%s ReadInt Error, file might be empty", self.FilePath))
        return 0
    end
    local b1, b2, b3, b4 = string.byte(self.Bytes, 1, 4)
    return b1 | b2 << 8 | b3 << 16 | b4 << 24
end

function BinaryBytes:GetReader(len, offset)
    if offset + len > self.Length then
        XLog.Error(string.format("%s GetReader out of range exception", self.FilePath))
        return nil
    end
    local reader = ReaderPool.GetReader()
    reader:LoadBytes(self.Bytes, len, offset + 1)
    return reader
end

function BinaryBytes:GetLen()
    return self.Length
end

function BinaryBytes:Close()
    --self.Bytes = nil
    --self.Length = 0
end

return BinaryBytes
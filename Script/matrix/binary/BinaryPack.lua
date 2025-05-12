local BinaryPackItem = require("Binary/BinaryPackItem")

---@class BinaryPack
local BinaryPack = {}
---@type table<number, BinaryPack>
local OpenPackList = {}
local OpenPackCount = 0
local OpenPackMax = 20--CS.XRemoteConfig.PackCacheCount --最大io数量放在后台配置

--检查是否达到最大打开文件上限
local function CheckMaxOpenFile()
    if OpenPackCount > OpenPackMax then
        local pack = table.remove(OpenPackList, 1)
        pack:Close()
        OpenPackCount = OpenPackCount - 1
    end
end

local function AddOpen(pack)
    OpenPackCount = OpenPackCount + 1
    OpenPackList[OpenPackCount] = pack
    CheckMaxOpenFile()
end

function BinaryPack.ReleaseIo()
    for _, v in ipairs(OpenPackList) do
        v:Close()
    end
    OpenPackCount = 0
end


function BinaryPack.New(path, packName)
    local temp = {}
    setmetatable(temp, { __index = BinaryPack })
    temp:Ctor(path, packName)
    return temp
end

function BinaryPack:Ctor(path, packName)
    self._Path = path --文件路径
    self._PackName = packName --配置包名
    self._PackStream = false --文件流句柄
    self._HeadOffset = 0 --表头信息偏移值
    self._RefCount = 0 --引用的
    self._CacheDoneCount = 0

    ---@type table<string, number>
    self._TabOffsetStart = false
    ---@type table<string, BinaryPackItem>
    self._ItemTab = {}
    self._IsOpenIo = false
    self:Open(path)
end

function BinaryPack:Open(path)
    self._IsOpenIo = true
    local file, err = io.open(path, "rb")
    if not file then --文件打不开
        XLog.Error(string.format("BinaryPack:Open 打开文件失败 %s ,%s", path, err))
        return
    end
    self._PackStream = file
    if not self._StreamLens then
        self._StreamLens = file:seek("end") --去读长度
    end
    AddOpen(self)
end

--关闭流
function BinaryPack:Close()
    self._PackStream:close()
    self._PackStream = nil
    self._IsOpenIo = false
end

--初始化表头信息, 主要包含这个包里包含了哪些配置表和配置表的偏移信息
function BinaryPack:InitHeadInfo()
    local HeadLen = self:ReadIntFix(0) --读取info长度
    self._TabOffsetStart = {}
    self._TabOffsetEnd = {}
    self._InfoIndexes = {}
    self._HeadOffset = 4 + HeadLen
    ---@type Reader
    local headReader = self:GetReader(4, HeadLen)
    local headCount = headReader:ReadInt() or 0
    local lastOffset = 0
    for i = 1, headCount do
        local name = headReader:ReadString()
        self._InfoIndexes[name] = i
        local len = headReader:ReadInt() or 0
        self._TabOffsetStart[i] = lastOffset
        self._TabOffsetEnd[i] = len
        lastOffset = lastOffset + len
    end
    self:CloseReader(headReader)
end

---@return BinaryPackItem
function BinaryPack:GetItem(tabName)
    if not self._TabOffsetStart then --初始化头部信息
        self:InitHeadInfo()
    end

    local tabIndex = self._InfoIndexes[tabName]

    if self._ItemTab[tabIndex] then --有缓存
        return self._ItemTab[tabIndex]
    end

    if tabIndex then
        local item = BinaryPackItem.New(tabName, self, self._HeadOffset + self._TabOffsetStart[tabIndex], self._TabOffsetEnd[tabIndex])
        self._ItemTab[tabIndex] = item
        self._RefCount = self._RefCount + 1
        return item
    else
        XLog.Error(string.format("BinaryPack:GetItem: %s 找不到表格: %s", self._PackName, tabName))
    end
end

function BinaryPack:ReleaseItem(tabName)
    if not self._InfoIndexes then
        return
    end
    local tabIndex = self._InfoIndexes[tabName]

    if not self._ItemTab[tabIndex] then
        XLog.Error(string.format("BinaryPack:ReleaseItem: %s 找不到表格: %s", self._PackName, tabName))
        return
    end

    local item = self._ItemTab[tabIndex]
    item:ReleaseFull()
    self._ItemTab[tabIndex] = nil
    self._RefCount = self._RefCount - 1
end

function BinaryPack:ReadIntFix(pos)
    local bytes = self:Read(pos, 4)
    local b1, b2, b3, b4 = string.byte(bytes, 1, 4)
    return b4 | b3 << 8 | b2 << 16 | b1 << 24
end

function BinaryPack:Read(pos, len)
    if not self._IsOpenIo then
        self:Open(self._Path)
    end
    if not self._PackStream then
        return nil
    end

    local cryptoPos = self._StreamLens - (pos + len)
    local curPos, err = self._PackStream:seek("set", cryptoPos)
    local bytes, err = self._PackStream:read(len)
    if not bytes then
        XLog.Error(string.format("Binary.Read 读取二进制失败 len = %s,%s", len, err))
        return nil
    end
    return bytes
end

--读取内存块
---@return CryptoReader
function BinaryPack:GetReader(pos, len)
    local bytes = self:Read(pos, len)
    local reader = CryptoReaderPool.GetReader()
    reader:LoadBytes(bytes, len)
    return reader
end

function BinaryPack:CloseReader(reader)
    CryptoReaderPool.ReleaseReader(reader)
end

function BinaryPack:ReleaseAll()
    for _, item in pairs(self._ItemTab) do
        item:ReleaseFull()
    end
    self._RefCount = 0
    self._ItemTab = nil
    self:Close()
end

function BinaryPack:ReleaseCache()
    for _, item in pairs(self._ItemTab) do
        item:ReleaseCache()
    end
end

function BinaryPack:TestCode()
    local str = ""
    for _, item in pairs(self._ItemTab) do
        str = str .. item:TestCode()
    end
    return str
end

return BinaryPack
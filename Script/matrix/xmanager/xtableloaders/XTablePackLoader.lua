local loader = {}

local BinaryPack = require("Binary/BinaryPack")
---@type table<string, BinaryPack>
local PackCache = {} --缓存pack

local TABLE_PACK_DIRECTORY = "../../Product/Pack/" --本地打包的路径
--local PACK_PREFIX = "Assets/Temp/Pack/" --打包会有临时目录
local PACK_PREFIX = "External/Pack/" --使用外部目录更合适一些?
local SUFFIX = ".pack"



--获取表格在哪个pack里
local function GetTablePackPath(path)
    local lastSlashIndex = path:match("^.*/()") --()返回最后一个/后的位置
    if lastSlashIndex then
        return path:sub(1, lastSlashIndex - 2)
    end
    return nil
end

--获取pack文件所在路径
local function GetPackFilePath(packName)
    if XMain.IsWindowsEditor then --本地模式
        return TABLE_PACK_DIRECTORY .. packName .. SUFFIX
    end
    return CS.XResourceManager.GetPrimaryFileUrl(PACK_PREFIX .. packName .. SUFFIX)
end

---根据packName返回对应的BinaryPack
---@return BinaryPack
local function GetPack(packName)
    if not PackCache[packName] then
        local packPath = GetPackFilePath(packName)
        local pack = BinaryPack.New(packPath, packName)
        PackCache[packName] = pack
    end
    return PackCache[packName]
end

local function ReadTableAll(path, identifier)
    local packName = GetTablePackPath(path)

    local pack = GetPack(packName)
    if not pack then
        return nil
    end
    local item = pack:GetItem(path)
    if not item then
        return nil
    end
    item:ReadAll(identifier)

    return item:GetTable() --这里其实存的就是所有的表格
end

local function ReadTable(path, identifier)
    if not identifier then
        XLog.Error(string.format("%s,identifier is null", path))
        return
    end

    local packName = GetTablePackPath(path)

    local pack = GetPack(packName)
    if not pack then
        return nil
    end

    local item = pack:GetItem(path)
    if not item then
        return nil
    end

    --if item:GetPrimaryKey() ~= identifier then
    --    XLog.Error("表格 " .. path .. " 读取Id与主键不一致，已改为强制读取模式，请按主键索引, 强制读取会带来较大性能损失")
    --    return ReadTableAll(path, identifier)
    --end
    --item:SetIdentifier(identifier)
    --item:CheckInit()
    item:InitTable(identifier)
    return item:GetTable()
end


--以下是固定读取接口
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
    for _, pack in pairs(PackCache) do
        pack:ReleaseCache()
    end
end

function loader.ReleaseFull(path)
    local packName = GetTablePackPath(path)
    local pack = PackCache[packName]
    if pack then
        pack:ReleaseItem(path)
    end
end

function loader.ReleaseIo()
    BinaryPack.ReleaseIo()
end


function loader.ReadArray(path, xTable, identifier)
    return nil
end

function loader.TestCode()
    local str = "local tbl = {}\n"
    for _, pack in pairs(PackCache) do
        str = str .. pack:TestCode()
    end
    str = str .. "for _, tab in ipairs(tbl) do\n"
    str = str .. "  for k, v in pairs(tab) do\n"
    str = str .. "  end\n"
    str = str .. "end"
    local file = io.open(TABLE_PACK_DIRECTORY .. "testCode.txt", "w")
    file:write(str)
    file:close()
    return str
end


return loader
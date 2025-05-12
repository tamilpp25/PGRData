---@class XRhythmGameModel : XModel
local XRhythmGameModel = XClass(XModel, "XRhythmGameModel")
local TaikoMapTableKey = {}
local FallingMapTableKey = {}
local TableKey = 
{ 
    RhythmGameControl = {},
    RhythmGameTaikoSkin = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XRhythmGameModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/RhythmGame", TableKey, XConfigUtil.CacheType.Normal)
end

function XRhythmGameModel:InitTaikoMapTable()
    TaikoMapTableKey = {}
    local mapPath = "Client/MiniActivity/MusicGame/RhythmGame/Taiko/Map/"
    local paths = CS.XTableManager.GetPaths(mapPath)
    XTool.LoopCollection(paths, function(path)
        local mapName = XTool.ExtractFilenameWithoutExtension(path)
        TaikoMapTableKey[mapName] = {DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", TableDefindName = "XTableRhythmGameMap", ReadFunc = XConfigUtil.ReadType.String}
    end)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/RhythmGame/Taiko/Map", TaikoMapTableKey, XConfigUtil.CacheType.Private)
end

function XRhythmGameModel:InitFallingMapTable()
    FallingMapTableKey = {}
    local mapPath = "Client/MiniActivity/MusicGame/RhythmGame/Falling/Map/"
    local paths = CS.XTableManager.GetPaths(mapPath)
    XTool.LoopCollection(paths, function(path)
        local mapName = XTool.ExtractFilenameWithoutExtension(path)
        FallingMapTableKey[mapName] = {DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", TableDefindName = "XTableRhythmGameMap", ReadFunc = XConfigUtil.ReadType.String}
    end)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/RhythmGame/Falling/Map", FallingMapTableKey, XConfigUtil.CacheType.Private)
end

function XRhythmGameModel:ClearPrivate()
end

function XRhythmGameModel:ResetAll()
    --这里执行重登数据清理
    TaikoMapTableKey = {}
    FallingMapTableKey = {}
end

---@return XTableRhythmGameControl[]
function XRhythmGameModel:GetRhythmGameControl()
    return self._ConfigUtil:GetByTableKey(TableKey.RhythmGameControl)
end

---@return XTableRhythmGameSkin[]
function XRhythmGameModel:GetRhythmGameTaikoSkin()
    return self._ConfigUtil:GetByTableKey(TableKey.RhythmGameTaikoSkin)
end

---@return XTableRhythmGameMap[]
function XRhythmGameModel:GetRhythmGameTaikoMapConfig(mapName)
    -- 空的话再初始化
    if XTool.IsTableEmpty(TaikoMapTableKey) then
        self:InitTaikoMapTable()
    end

    if not TaikoMapTableKey[mapName] then
        XLog.Error("MapName: " .. mapName .. " 不存在")
        return nil
    end

    return self._ConfigUtil:GetByTableKey(TaikoMapTableKey[mapName])
end

---@return XTableRhythmGameMap[]
function XRhythmGameModel:GetRhythmGameFallingMapConfig(mapName)
    -- 空的话再初始化
    if XTool.IsTableEmpty(FallingMapTableKey) then
        self:InitFallingMapTable()
    end

    if not FallingMapTableKey[mapName] then
        XLog.Error("MapName: " .. mapName .. " 不存在")
        return nil
    end

    return self._ConfigUtil:GetByTableKey(FallingMapTableKey[mapName])
end

return XRhythmGameModel
---@class XFightLevelMusicGameModel : XModel
local XFightLevelMusicGameModel = XClass(XModel, "XFightLevelMusicGameModel")

local TableKey = {
    --- Game 谱面数据
    LevelMusicMap = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 谱面轨道
    LevelMusicTrack = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 谱面物件
    LevelMusicNote = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XFightLevelMusicGameModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fight/MiniGame/LevelMusic", TableKey)
end

function XFightLevelMusicGameModel:ClearPrivate()
end

function XFightLevelMusicGameModel:ResetAll()
end

--region Cfg - LevelMusicMap
---@return XTableLevelMusicMap[]
function XFightLevelMusicGameModel:GetMapCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.LevelMusicMap)
end

---@return XTableLevelMusicMap
function XFightLevelMusicGameModel:GetMapCfg(mapId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LevelMusicMap, mapId)
end

function XFightLevelMusicGameModel:GetMapCfgLimitTime(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.LimitTime
end

function XFightLevelMusicGameModel:GetMapFaultTolerance(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.FaultTolerance
end

function XFightLevelMusicGameModel:GetMapCfgAreaMoveTypeList(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.AreaMoveTypeList
end

function XFightLevelMusicGameModel:GetMapCfgAreaInitPosList(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.AreaInitPosList
end

function XFightLevelMusicGameModel:GetMapCfgAreaInitMoveSpeedList(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.AreaInitMoveSpeedList
end

function XFightLevelMusicGameModel:GetMapCfgTrackList(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.TrackList
end

function XFightLevelMusicGameModel:GetMapCfgTutorialId(mapId)
    local cfg = self:GetMapCfg(mapId)
    return cfg and cfg.TutorialId
end
--endregion

--region Cfg - LevelMusicTrack
---@return XTableLevelMusicTrack[]
function XFightLevelMusicGameModel:GetTrackCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.LevelMusicTrack)
end

---@return XTableLevelMusicTrack
function XFightLevelMusicGameModel:GetTrackCfg(trackId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LevelMusicTrack, trackId)
end

function XFightLevelMusicGameModel:GetTrackCfgLength(trackId)
    local cfg = self:GetTrackCfg(trackId)
    return cfg and cfg.Length
end

function XFightLevelMusicGameModel:GetTrackCfgNoteList(trackId)
    local cfg = self:GetTrackCfg(trackId)
    return cfg and cfg.NoteList
end
--endregion

--region Cfg - LevelMusicNote
---@return XTableLevelMusicNote[]
function XFightLevelMusicGameModel:GetNoteCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.LevelMusicNote)
end

---@return XTableLevelMusicNote
function XFightLevelMusicGameModel:GetNoteCfg(noteId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.LevelMusicNote, noteId)
end

function XFightLevelMusicGameModel:GetNoteCfgType(noteId)
    local cfg = self:GetNoteCfg(noteId)
    return cfg and cfg.Type
end

function XFightLevelMusicGameModel:GetNoteCfgLength(noteId)
    local cfg = self:GetNoteCfg(noteId)
    return cfg and cfg.Length
end
--endregion

return XFightLevelMusicGameModel
---@class XRhythmGameControl : XEntityControl
---@field private _Model XRhythmGameModel
local XRhythmGameControl = XClass(XEntityControl, "XRhythmGameControl")
function XRhythmGameControl:OnInit()
    --初始化内部变量
end

function XRhythmGameControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRhythmGameControl:RemoveAgencyEvent()
end

function XRhythmGameControl:OnRelease()
end

function XRhythmGameControl:GetNewEntityXNote()
    local xNote = require("XUi/XUiRhythmGame/Entity/XRhythmGameNote")
    return self:AddEntity(xNote)
end

function XRhythmGameControl:GetModelRhythmGameTaikoMapConfig(mapName)
    return self._Model:GetRhythmGameTaikoMapConfig(mapName)
end

function XRhythmGameControl:GetModelRhythmGameFallingMapConfig(mapName)
    return self._Model:GetRhythmGameFallingMapConfig(mapName)
end

function XRhythmGameControl:GetModelRhythmGameTaikoSkin()
    return self._Model:GetRhythmGameTaikoSkin()
end

-- 埋点
function XRhythmGameControl:BuryingRhythmScore(mapId, scoreData)
    local dict = self._Model.BuryingRhythmScoreData or {}
    dict["i_mapId"] = mapId 
    dict["i_combo"] = scoreData.maxCombo
    dict["i_perfect_count"] = scoreData.perfectCount
    dict["i_good_count"] = scoreData.goodCount
    dict["i_miss_count"] = scoreData.missCount
    dict["i_point"] = scoreData.point
    dict["i_acc"] = scoreData.acc
    dict["role_id"] = XPlayer.Id -- 玩家id
    CS.XRecord.Record(dict, "200019", "RhythmGameScore")

    self._Model.BuryingRhythmScoreData = dict
end

return XRhythmGameControl
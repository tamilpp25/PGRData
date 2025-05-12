---@class XGoldenMinerStageMapInfo
local XGoldenMinerStageMapInfo = XClass(nil, "XGoldenMinerStageMapInfo")

function XGoldenMinerStageMapInfo:Ctor()
    self._StageId = 0
    self._MapId = 0
end

function XGoldenMinerStageMapInfo:UpdateData(data)
    self._StageId = data.StageId
    self:UpdateMapId(data.MapId)
end

function XGoldenMinerStageMapInfo:UpdateMapId(value)
    self._MapId = value
end

function XGoldenMinerStageMapInfo:GetStageId()
    return self._StageId
end

function XGoldenMinerStageMapInfo:GetMapId()
    return self._MapId
end

return XGoldenMinerStageMapInfo
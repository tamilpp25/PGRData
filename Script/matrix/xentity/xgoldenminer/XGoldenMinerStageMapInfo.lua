local type = type

local XGoldenMinerStageMapInfo = XClass(nil, "XGoldenMinerStageMapInfo")

local Default = {
    _StageId = 0, --关卡id
    _MapId = 0, --地图id
}

function XGoldenMinerStageMapInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XGoldenMinerStageMapInfo:UpdateData(data)
    self._StageId = data.StageId
    self._MapId = data.MapId
end

function XGoldenMinerStageMapInfo:GetStageId()
    return self._StageId
end

function XGoldenMinerStageMapInfo:GetMapId()
    return self._MapId
end

return XGoldenMinerStageMapInfo
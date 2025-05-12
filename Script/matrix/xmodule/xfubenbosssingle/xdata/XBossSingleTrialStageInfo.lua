---@class XBossSingleTrialStageInfo
local XBossSingleTrialStageInfo = XClass(nil, "XBossSingleTrialStageInfo")

function XBossSingleTrialStageInfo:Ctor(data)
    self:SetData(data)
end

function XBossSingleTrialStageInfo:SetData(data)
    if data then
        self._StageId = data.StageId
        self._Score = data.Score
    end
end

function XBossSingleTrialStageInfo:GetStageId()
    return self._StageId
end

function XBossSingleTrialStageInfo:GetScore()
    return self._Score
end

return XBossSingleTrialStageInfo
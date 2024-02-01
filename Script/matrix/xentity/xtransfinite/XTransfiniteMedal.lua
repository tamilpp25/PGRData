---@class XTransfiniteMedal
local XTransfiniteMedal = XClass(nil, "XTransfiniteMedal")

function XTransfiniteMedal:Ctor()
    self._Id = 0
    self._Time = 0
    self._StartStageProgressId = 0
end

function XTransfiniteMedal:SetTime(time, progressId)
    if not XTool.IsNumberValid(progressId) then
        progressId = 1
    end
    self._StartStageProgressId = progressId
    self._MedalId = XTransfiniteConfigs.GetMedalIdByTime(time, progressId)
    self._Time = time
end
 
function XTransfiniteMedal:GetName()
    return XTransfiniteConfigs.GetMedalName(self._MedalId)
end

function XTransfiniteMedal:GetIcon()
    return XTransfiniteConfigs.GetMedalIcon(self._MedalId)
end

function XTransfiniteMedal:GetDesc()
    local desc = XTransfiniteConfigs.GetMedalDesc(self._MedalId)
    return desc[self._StartStageProgressId] or ""
end

function XTransfiniteMedal:GetTime()
    return self._Time
end

return XTransfiniteMedal

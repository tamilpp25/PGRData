---@class XTransfiniteMedal
local XTransfiniteMedal = XClass(nil, "XTransfiniteMedal")

function XTransfiniteMedal:Ctor()
    self._Id = 0
    self._Time = 0
end

function XTransfiniteMedal:SetTime(time)
    self._MedalId = XTransfiniteConfigs.GetMedalIdByTime(time)
    self._Time = time
end
 
function XTransfiniteMedal:GetName()
    return XTransfiniteConfigs.GetMedalName(self._MedalId)
end

function XTransfiniteMedal:GetIcon()
    return XTransfiniteConfigs.GetMedalIcon(self._MedalId)
end

function XTransfiniteMedal:GetDesc()
    return XTransfiniteConfigs.GetMedalDesc(self._MedalId)
end

function XTransfiniteMedal:GetTime()
    return self._Time
end

return XTransfiniteMedal

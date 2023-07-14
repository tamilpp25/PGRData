---@class XPlanetBuff
local XPlanetBuff = XClass(nil, "XPlanetBuff")

function XPlanetBuff:Ctor()
    self._EventId = false
    self._Amount = 1
end

function XPlanetBuff:SetEventId(id)
    self._EventId = id
end

function XPlanetBuff:SetAmount(amount)
    self._Amount = amount
end

function XPlanetBuff:GetName()
    return XPlanetStageConfigs.GetEventName(self._EventId)
end

function XPlanetBuff:GetDesc()
    return XPlanetStageConfigs.GetEventDesc(self._EventId)
end

function XPlanetBuff:GetIcon()
    return XPlanetStageConfigs.GetEventIcon(self._EventId)
end

function XPlanetBuff:GetAmount()
    return self._Amount
end

function XPlanetBuff:IsIncrease()
    return XPlanetStageConfigs.GetEventIsIncrease(self._EventId)
end

function XPlanetBuff:IsShow()
    return XPlanetStageConfigs.GetEventIsShow(self._EventId)
end

return XPlanetBuff
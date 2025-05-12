local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

local XUiGuildWarReinforceDetailEvent = XClass(XUiGuildWarStageDetailEvent, 'XUiGuildWarReinforceDetailEvent')

function XUiGuildWarReinforceDetailEvent:SetEntity(entity)
    self._Entity = entity
    self.TxtNum.gameObject:SetActiveEx(false)
end

---@overload
function XUiGuildWarReinforceDetailEvent:IsShowExtend(eventId)
    self._EventId = eventId
    return table.contains(XGuildWarConfig.GetClientConfigValues('BuffShowReinforceEvents'),tostring(eventId))
end

---@overload
function XUiGuildWarReinforceDetailEvent:DoExtendShow()
    self.TxtNum.gameObject:SetActiveEx(true)
    
    local supportCost = self._Entity:GetCurrentSupportCost()
    local addsPer = XGuildWarConfig.GetServerConfigValue('ReinforcementSupportHp')
    if string.IsNumeric(addsPer) then
        addsPer = tonumber(addsPer)
    else
        addsPer = 0
    end
    
    local hpAdds = supportCost * addsPer
    
    local contentformat = XGuildWarConfig.GetClientConfigValues('ReinforcementsSupportDetail')[1]
    
    local percentStr = tostring(XMath.ToMinInt(hpAdds / self._Entity:GetMaxHP() * 100))..'%'
    
    self.TxtNum.text = XUiHelper.FormatText(contentformat, supportCost, percentStr)
end

function XUiGuildWarReinforceDetailEvent:RefreshShow()
    if XTool.IsNumberValid(self._EventId) then
        if self:IsShowExtend(self._EventId) then
            self:DoExtendShow()
        end
    end 
end

return XUiGuildWarReinforceDetailEvent

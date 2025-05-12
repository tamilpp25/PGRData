local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

local XUiGuildWarReinforceAttackedDetailEvent = XClass(XUiGuildWarStageDetailEvent, 'XUiGuildWarReinforceAttackedDetailEvent')

---@overload
function XUiGuildWarReinforceAttackedDetailEvent:IsShowExtend(eventId)
    return XTool.IsNumberValid(self.Parent._Node.LastReinforcementAttackedTime)
end

---@overload
function XUiGuildWarReinforceAttackedDetailEvent:DoExtendShow()
    if self.Parent.AddTimer then
        self:RefreshReinforementBuffTime()
        self._ReinforementBuffTimerId = self.Parent:AddTimer(handler(self,self.RefreshReinforementBuffTime))
    end
end

---@overload
function XUiGuildWarReinforceAttackedDetailEvent:Release()
    -- 关闭定时器
    if self.Parent.RemoveTimer then
        self.Parent:RemoveTimer(self._ReinforementBuffTimerId)
    end
    
    self.Super.Release(self)
end


function XUiGuildWarReinforceAttackedDetailEvent:RefreshReinforementBuffTime()
    local leftTime = self.Parent._Node.LastReinforcementAttackedTime + tonumber(XGuildWarConfig.GetServerConfigValue('ReinforcementBuffEffectInterval')) - XTime.GetServerNowTimestamp()

    if leftTime <= 0 then
        self.GameObject:SetActiveEx(false)
        return
    end
    
    self.TxtTime2.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('NodeAttackedByReinforementBuffTime')[1],XUiHelper.GetTime(leftTime,XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))


end


return XUiGuildWarReinforceAttackedDetailEvent

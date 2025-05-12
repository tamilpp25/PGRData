---@class XUiGuildWarStageDetailEvent
local XUiGuildWarStageDetailEvent = XClass(nil, "XUiGuildWarStageDetailEvent")

function XUiGuildWarStageDetailEvent:Ctor(ui,parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
end

function XUiGuildWarStageDetailEvent:Release()
    -- 关闭定时器
    if self.Parent.RemoveTimer and XTool.IsNumberValid(self.RefreshRebuildTimeId) then
        self.Parent:RemoveTimer(self.RefreshRebuildTimeId)
    end
    
    -- 移除所有引用
    local keyList = {}

    for i, v in pairs(self) do
        table.insert(keyList, i)
    end

    for i, v in ipairs(keyList) do
        self[v] = nil
    end
end

function XUiGuildWarStageDetailEvent:Update(event)
    self.Text.text = event.Description
    self.ImgIcon:SetRawImage(event.Icon)
    if self.TextName then
        self.TextName.text = event.Name
    end
    local isShow = self:IsShowExtend(event.Id)
    if isShow then
        self:DoExtendShow()
    end
    if self.TxtTime2 then
        self.TxtTime2.gameObject:SetActiveEx(isShow)
    end
    if self.TxtRemainder then
        self.TxtRemainder.gameObject:SetActiveEx(isShow)
        local attackInterval = tonumber(XGuildWarConfig.GetServerConfigValue('ResourceNodeAttackedInterval'))
        local attackTimes = math.floor(XDataCenter.GuildWarManager.GetRoundLeftTime() / attackInterval)
        self.TxtRemainder.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('AttackLeftTimes')[1],attackTimes)
    end
    
end

function XUiGuildWarStageDetailEvent:IsShowExtend(eventId)
    return table.contains(XGuildWarConfig.GetClientConfigValues('BuffShowTimeEvents'),tostring(eventId))
end

function XUiGuildWarStageDetailEvent:DoExtendShow()
    if self.TxtTime2 and self.Parent.AddTimer then
        self:RefreshRebuildTime()
        self.RefreshRebuildTimeId = self.Parent:AddTimer(handler(self,self.RefreshRebuildTime))
    end
end

--2.11 特殊的用于显示炮击buff炮击倒计时需求
function XUiGuildWarStageDetailEvent:RefreshRebuildTime()
    local nextTime = XDataCenter.GuildWarManager.GetNextAttackedTime()
    local leftTime = nextTime - XTime.GetServerNowTimestamp()
    self.TxtTime2.text = XUiHelper.GetText('GuildWarDamageTime',XUiHelper.GetTime(leftTime,XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
end

return XUiGuildWarStageDetailEvent

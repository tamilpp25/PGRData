local XUiPanelTwins = XClass(nil, "XUiPanelTwins")

function XUiPanelTwins:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelTwins:SetData(node)
    --伏兵强化面板
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        self.PanelShelling.gameObject:SetActiveEx(node:GetIsMerge())
    else
        self.PanelShelling.gameObject:SetActiveEx(false)
    end
    
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then return end
    self.RImgShellingIcon:SetRawImage(buffData.Icon)
    self.TxtShellingName.text = buffData.Name
    self.TxtShellingDetails.text = buffData.Description
    self.TxtAreaDetails.text = node:GetDesc()
    self:RefreshTimeData(node)
end

function XUiPanelTwins:RefreshTimeData(node)
    local timeRemaining = node:GetTimeToBossAttack()
    if timeRemaining > 0 then
        local textTime = XUiHelper.GetTime(timeRemaining, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtShellingTime.text = XUiHelper.GetText("GuildWarDamageTime",
                                                      textTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtShellingTime.gameObject:SetActiveEx(true)
    else
        self.TxtShellingTime.gameObject:SetActiveEx(false)
    end
end

return XUiPanelTwins

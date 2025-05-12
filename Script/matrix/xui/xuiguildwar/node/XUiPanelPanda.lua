local XUiPanelPanda = XClass(nil, "XUiPanelPanda")

function XUiPanelPanda:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelPanda:SetData(node)
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then return end
    self.RImgShellingIcon:SetRawImage(buffData.Icon)
    self.TxtShellingName.text = buffData.Name
    self.TxtShellingDetails.text = buffData.Description
    self.TxtAreaDetails.text = node:GetDesc()
    self:RefreshTimeData(node)
end

function XUiPanelPanda:RefreshTimeData(node)
    local timeRemaining = node:GetTimeToBossAttack()
    if timeRemaining > 0 then
        local textTime = XUiHelper.GetTime(timeRemaining)
        self.TxtShellingTime.text = XUiHelper.GetText("GuildWarDamageTime",
                                                      textTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtShellingTime.gameObject:SetActiveEx(true)
    else
        self.TxtShellingTime.gameObject:SetActiveEx(false)
    end
end

return XUiPanelPanda

local XUiPanelBuff = XClass(nil, "XUiPanelBuff")

function XUiPanelBuff:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelBuff:SetData(node)
    local buffData = node:GetShowFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then return end
    self.RImgIcon:SetRawImage(buffData.Icon)
    self.TxtBuff.text = buffData.Name
    self.TxtDetails.text = buffData.Description
    self.TxtAreaDetails.text = XUiHelper.GetText("GuildWarBuffPanelTip")
end

return XUiPanelBuff

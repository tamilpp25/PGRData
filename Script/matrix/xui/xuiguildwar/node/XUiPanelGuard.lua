local XUiPanelGuard = XClass(nil, "XUiPanelGuard")

function XUiPanelGuard:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelGuard:SetData(node)
    local buffData = node:GetFightEventDetailConfig()
    self.GameObject:SetActiveEx(buffData ~= nil)
    if buffData == nil then return end
    self.RImgIcon:SetRawImage(buffData.Icon)
    self.TxtName.text = buffData.Name
    self.TxtDetails.text = buffData.Description
    self.PanelPass.gameObject:SetActiveEx(node:GetStutesType() == XGuildWarConfig.NodeStatusType.Die)
end

return XUiPanelGuard

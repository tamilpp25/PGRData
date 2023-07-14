local XUiGridExpeditionRecruitFeature = XClass(nil, "XUiGridExpeditionRecruitFeature")

function XUiGridExpeditionRecruitFeature:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

end

function XUiGridExpeditionRecruitFeature:Refresh(eComboId)
    self.ECombo = XDataCenter.ExpeditionManager.GetComboByChildComboId(eComboId)
    self.RImgIcon:SetRawImage(self.ECombo:GetIconPath())
    local comboActive = self.ECombo:GetComboActive()
    self.BgNormal.gameObject:SetActiveEx(comboActive)
    self.BgDefault.gameObject:SetActiveEx(comboActive)
    self.Disable.gameObject:SetActiveEx(not comboActive)
    if comboActive then
        local isDefault = self.ECombo:CheckIsDefaultCombo()
        self.BgDefault.gameObject:SetActiveEx(isDefault)
        self.BgNormal.gameObject:SetActiveEx(not isDefault)
    end
end

return XUiGridExpeditionRecruitFeature
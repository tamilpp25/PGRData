--虚像地平线招募界面队伍组合列表控件
local XUiExpeditionComboGrid = XClass(nil, "XUiExpeditionComboGrid")

function XUiExpeditionComboGrid:Ctor()

end

function XUiExpeditionComboGrid:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.GridPhase.gameObject:SetActiveEx(false)
    self.Disable.gameObject:SetActiveEx(false)
    self.Select.gameObject:SetActiveEx(true)
end

function XUiExpeditionComboGrid:RefreshDatas(eCombo)
    self.ECombo = eCombo
    local comboActive = self.ECombo:GetComboActive()
    self.Select.gameObject:SetActiveEx(comboActive)
    self.Disable.gameObject:SetActiveEx(not comboActive)
    if comboActive then
        self.RImgActive:SetRawImage(self.ECombo:GetIconPath())
        self.TxtActive.text = self.ECombo:GetCurrentPhaseStr()
        local isDefault = self.ECombo:CheckIsDefaultCombo()
        self.BgDefault.gameObject:SetActiveEx(isDefault)
        self.BgNormal.gameObject:SetActiveEx(not isDefault)
        if self.TxtActiveLevel then
            self.TxtActiveLevel.text = self.ECombo:GetCurrentPhaseLevelStr()
        end
    else
        self.RImgDisable:SetRawImage(self.ECombo:GetIconPath())
        self.TxtDisable.text = self.ECombo:GetReachConditionNumStr()
    end
end

return XUiExpeditionComboGrid
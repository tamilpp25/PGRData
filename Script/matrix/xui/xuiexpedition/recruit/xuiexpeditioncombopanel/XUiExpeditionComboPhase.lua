--虚像地平线羁绊阶段显示图标控件
local XUiExpeditionComboPhase = XClass(nil, "XUiExpeditionComboPhase")

function XUiExpeditionComboPhase:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Active = self.Transform:Find("ImgSelect").gameObject
end

function XUiExpeditionComboPhase:SetIconActive(isActive)
    self.Active:SetActiveEx(isActive)
end

return XUiExpeditionComboPhase
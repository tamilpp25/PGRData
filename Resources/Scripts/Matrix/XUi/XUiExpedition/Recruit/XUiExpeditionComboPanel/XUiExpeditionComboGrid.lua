--虚像地平线招募界面队伍组合列表控件
local XUiExpeditionComboGrid = XClass(nil, "XUiExpeditionComboGrid")
local XUiExpeditionComboPhase = require("XUi/XUiExpedition/Recruit/XUiExpeditionComboPanel/XUiExpeditionComboPhase")
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
    else
        self.RImgDisable:SetRawImage(self.ECombo:GetIconPath())
        self.TxtDisable.text = self.ECombo:GetCurrentPhaseStr()
    end
    self:RefreshPhase()
end

function XUiExpeditionComboGrid:RefreshPhase()
    if not self.ECombo then return end
    if not self.GridPhaseList then self.GridPhaseList = {} end
    for i = 1, self.ECombo:GetConditionCharaNum() do
        if not self.GridPhaseList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridPhase.gameObject)
            ui.transform:SetParent(self.GridPhase.transform.parent, false)
            ui.gameObject:SetActiveEx(true)
            self.GridPhaseList[i] = XUiExpeditionComboPhase.New(ui)
        end
    end
    for i = 1, #self.GridPhaseList do
        self.GridPhaseList[i].GameObject:SetActiveEx(i <= self.ECombo:GetConditionCharaNum())
        self.GridPhaseList[i]:SetIconActive(i <= self.ECombo:GetReachConditionNum())
    end
end

return XUiExpeditionComboGrid
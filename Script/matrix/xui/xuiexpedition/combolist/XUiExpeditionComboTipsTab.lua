--虚像地平线羁绊组合详细页面：页签控件
local XUiExpeditionComboTipsTab = XClass(nil, "XUiExpeditionComboTipsTab")
local UiButtonState = CS.UiButtonState
function XUiExpeditionComboTipsTab:Ctor(ui, rootUi, index, tabData, onClickCallBack)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Button = self.GameObject:GetComponent("XUiButton")
    if tabData.TabType ~= "BtnFirstHasSnd" then
        self.BtnType = XDataCenter.ExpeditionManager.ComboBtnType.ChildComboType
        self.Button:ShowTag(tabData.IsActive)      
        self.Button:SetNameByGroup(0, tabData.Name)
    else
        self.BtnType = XDataCenter.ExpeditionManager.ComboBtnType.BaseComboType
        self.Button:SetNameByGroup(0, tabData.Name)
        self.Button:SetNameByGroup(1, string.format("%d/%d", tabData.ActiveChildCount, tabData.ChildCount))
    end
    if self.BtnType == XDataCenter.ExpeditionManager.ComboBtnType.ChildComboType then
        self.ECombo = tabData.Combo
    end
    self.OnClickCallBack = onClickCallBack
    self.Index = index
end

function XUiExpeditionComboTipsTab:OnClick()
    if self.BtnType == XDataCenter.ExpeditionManager.ComboBtnType.ChildComboType then
        self.RootUi:PlayAnimation("QieHuan")
        self:RefreshComboList()
    end
end

function XUiExpeditionComboTipsTab:RefreshComboList()
    self.RootUi:RefreshComboList(self.ECombo)
end

return XUiExpeditionComboTipsTab
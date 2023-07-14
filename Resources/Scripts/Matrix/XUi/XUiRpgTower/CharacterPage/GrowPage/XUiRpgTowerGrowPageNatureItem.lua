--兵法蓝图养成界面天赋树天赋节点控件
local XUiRpgTowerGrowPageNatureItem = XClass(nil, "XUiRpgTowerGrowPageNatureItem")

function XUiRpgTowerGrowPageNatureItem:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.BtnTalent.CallBack = function() self:OnClick() end
end

function XUiRpgTowerGrowPageNatureItem:RefreshData(rTalent)
    self.Talent = rTalent
    self.BtnTalent:SetName(self.Talent:GetTalentName())
    self.BtnTalent:SetRawImage(self.Talent:GetIconPath())
    if self.Talent:GetIsUnLock() then
        self.BtnTalent:SetButtonState(CS.UiButtonState.Normal)
        self.BtnTalent.TempState = CS.UiButtonState.Normal
    elseif self.Talent:GetCanUnLock() then
        self.BtnTalent:SetButtonState(CS.UiButtonState.Select)
        self.BtnTalent.TempState = CS.UiButtonState.Select
    else
        self.BtnTalent:SetButtonState(CS.UiButtonState.Disable)
        self.BtnTalent.TempState = CS.UiButtonState.Disable
    end
end

function XUiRpgTowerGrowPageNatureItem:OnClick()
    if not self.Talent then return end
    XLuaUiManager.Open("UiRpgTowerNature", self.Talent)  
end

function XUiRpgTowerGrowPageNatureItem:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiRpgTowerGrowPageNatureItem:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiRpgTowerGrowPageNatureItem
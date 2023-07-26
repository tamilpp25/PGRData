--虚像地平线招募界面子页面角色详细：羁绊显示控件
local XUiExpeditionComboIconGrid = XClass(nil, "XUiExpeditionComboIconGrid")

function XUiExpeditionComboIconGrid:Ctor()

end

function XUiExpeditionComboIconGrid:Init(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.GridPhase then
        self.GridPhase.gameObject:SetActiveEx(false)
    end
    if self.Disable then
        self.Disable.gameObject:SetActiveEx(false)
    end
    if self.Select then
        self.Select.gameObject:SetActiveEx(true)
    end
end

function XUiExpeditionComboIconGrid:RefreshData(eComboId, detailsType)
    self.ECombo = XDataCenter.ExpeditionManager.GetComboByChildComboId(eComboId)
    local isDefault = self.ECombo:CheckIsDefaultCombo()
    self.BgDefault.gameObject:SetActiveEx(isDefault)
    self.BgNormal.gameObject:SetActiveEx(not isDefault)
    local comboActive = self.ECombo:GetComboActive()
    self.Select.gameObject:SetActiveEx(comboActive)
    self.Disable.gameObject:SetActiveEx(not comboActive)
    if comboActive then
        self.RImgActive:SetRawImage(self.ECombo:GetIconPath())
        self.TxtActive.text = self.ECombo:GetCurrentPhaseStr()
        if self.TxtActiveLevel then
            self.TxtActiveLevel.text = self.ECombo:GetCurrentPhaseLevelStr()
        end
    else
        self.RImgDisable:SetRawImage(self.ECombo:GetIconPath())
        self.TxtDisable.text = self.ECombo:GetReachConditionNumStr()
    end
    
    self.ImgDown.gameObject:SetActiveEx(false)
    if detailsType == XExpeditionConfig.MemberDetailsType.RecruitMember then
        self.ImgUp.gameObject:SetActiveEx(self.ECombo:GetPrePhaseUp() or self.ECombo:GetIsWillActive())
    elseif detailsType == XExpeditionConfig.MemberDetailsType.FireMember then
        self.ImgUp.gameObject:SetActiveEx(false)
    end
end
return XUiExpeditionComboIconGrid
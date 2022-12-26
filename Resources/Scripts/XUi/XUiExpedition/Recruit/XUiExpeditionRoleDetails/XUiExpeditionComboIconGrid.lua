--虚像地平线招募界面子页面角色详细：羁绊显示控件
local XUiExpeditionComboIconGrid = XClass(nil, "XUiExpeditionComboIconGrid")
local DetailsType = {
    RecruitMember = 1,
    FireMember = 2
}
function XUiExpeditionComboIconGrid:Ctor()

end

function XUiExpeditionComboIconGrid:Init(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionComboIconGrid:RefreshData(eComboId, detailsType)
    self.ECombo = XDataCenter.ExpeditionManager.GetComboByChildComboId(eComboId)
    self.RImgCombo:SetRawImage(self.ECombo:GetIconPath())
    self.ImgDown.gameObject:SetActiveEx(false)
    if detailsType == DetailsType.FireMember then
        self.ImgUp.gameObject:SetActiveEx(false)
        --self.IsActive.gameObject:SetActiveEx(self.ECombo:GetComboActive())
    elseif detailsType == DetailsType.RecruitMember then
        --self.IsActive.gameObject:SetActiveEx(self.ECombo:GetPreActive())
        self.ImgUp.gameObject:SetActiveEx(self.ECombo:GetPrePhaseUp() or self.ECombo:GetIsWillActive())
    end
end
return XUiExpeditionComboIconGrid
local XUiGridSkillDesc = XClass(nil, "XUiGridSkillDesc")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridSkillDesc:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelect = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridSkillDesc:SetButtonCallBack()
    self.BtnAddSelect.CallBack = function()
        self:OnBtnAddSelectClick()
    end
end

function XUiGridSkillDesc:OnBtnAddSelectClick()
    self.Base:SetSelectSkill(self.Data, not self.IsSelect)
    self:ShowSelect()
end

function XUiGridSkillDesc:UpdateGrid(data, base)
    self.Data = data
    self.Base = base

    if data then
        local level = data:GetLevelStr()
        self.TxtLevel.text = CSTextManagerGetText("PartnerSkillLevelCN",level)
        self.TxtName.text = data:GetSkillName()
        self.TxtContent.text = data:GetSkillDesc()
        self.RImgIcon:SetRawImage(data:GetSkillIcon())
        self:ShowSelect()
    end

end

function XUiGridSkillDesc:ShowSelect()
    self.IsSelect = self.Base:CheckIsSelectSkill(self.Data:GetId())
    self.PanelSelect.gameObject:SetActiveEx(self.IsSelect)
end

return XUiGridSkillDesc
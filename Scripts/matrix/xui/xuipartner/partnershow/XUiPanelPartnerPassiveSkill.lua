local XUiPanelPartnerPassiveSkill = XClass(nil, "XUiPanelPartnerPassiveSkill")

function XUiPanelPartnerPassiveSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- skill : XPartnerPassiveSkillGroup
function XUiPanelPartnerPassiveSkill:SetData(skill)
    self.GameObject:SetActiveEx(true)
    self.RImgSkillIcon:SetRawImage(skill:GetSkillIcon())
    self.TxtName.text = skill:GetSkillName()
    self.TxtDesc.text = skill:GetSkillDesc()
end

function XUiPanelPartnerPassiveSkill:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelPartnerPassiveSkill
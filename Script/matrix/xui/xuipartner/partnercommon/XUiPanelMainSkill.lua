local XUiPanelMainSkill = XClass(nil, "XUiPanelMainSkill")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelMainSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsLock = false
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelMainSkill:SetButtonCallBack()
    self.BtnSkill.CallBack = function()
        self:OnBtnSkillClick()
    end
end

function XUiPanelMainSkill:OnBtnSkillClick() 
    XLuaUiManager.Open("UiPartnerActivateMainSkill", self.Partner)
end

function XUiPanelMainSkill:UpdatePanel(data, partner)
    self.Data = data
    self.Partner = partner

    if data then
        local level = data:GetLevelStr()
        self.TxtLevel.text = level
        self.SkillName.text = data:GetSkillName()
        self.IconSkill:SetRawImage(data:GetSkillIcon())
        local IsShowRed = XDataCenter.PartnerManager.CheckNewSkillRedByPartnerId(self.Partner:GetId())
        self:ShowRed(IsShowRed)
    end
end

function XUiPanelMainSkill:ShowRed(IsShowRed)
    self.BtnSkill:ShowReddot(IsShowRed)
end

return XUiPanelMainSkill
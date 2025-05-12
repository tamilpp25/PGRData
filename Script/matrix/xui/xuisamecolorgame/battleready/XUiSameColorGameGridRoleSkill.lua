---@class XUiSameColorGameGridRoleSkill
local XUiSameColorGameGridRoleSkill = XClass(nil, "XUiSameColorGameGridRoleSkill")

function XUiSameColorGameGridRoleSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.ClickCallBack = nil
    ---@type XSCRoleSkill
    self.Skill = nil
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
end

---@param skill XSCRoleSkill
function XUiSameColorGameGridRoleSkill:SetData(skill, index)
    self.Skill = skill
    self.RImgSkillIcon:SetRawImage(skill:GetIcon())
    self.RImgSkillIcon.gameObject:SetActiveEx(true)
    if self.PanelEmpty then
        self.PanelEmpty.gameObject:SetActiveEx(false)
    end
end

function XUiSameColorGameGridRoleSkill:SetClickCallBack(callback)
    self.ClickCallBack = callback
end

function XUiSameColorGameGridRoleSkill:SetIsEmpty(value)
    if value then
        self.Skill = nil
    end
    if self.PanelEmpty then
        self.RImgSkillIcon.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)
    end
end

function XUiSameColorGameGridRoleSkill:SetSelectStatus(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

function XUiSameColorGameGridRoleSkill:OnBtnSelfClicked(playAnim)
    playAnim = false  -- v4.0不需要播动画
    if self.ClickCallBack then
        self.ClickCallBack(self.Skill, self, playAnim)
    end
end

function XUiSameColorGameGridRoleSkill:GetSkill()
    return self.Skill
end

return XUiSameColorGameGridRoleSkill
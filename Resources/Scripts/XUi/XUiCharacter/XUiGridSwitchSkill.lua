local XUiGridSwitchSkill = XClass(nil, "XUiGridSwitchSkill")

function XUiGridSwitchSkill:Ctor(ui, switchCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SwitchCb = switchCb
    XTool.InitUiObject(self)
    self.BtnSelect.CallBack = function()
        self:OnClickBtnSelect()
    end
end

function XUiGridSwitchSkill:Refresh(skillId, skillLevel, isCurrent)
    self.SkillId = skillId

    self.SelectIcon.gameObject:SetActiveEx(isCurrent)
    self.BtnSelect.gameObject:SetActiveEx(not isCurrent)

    local name, intro = XCharacterConfigs.GetSkillGradeDesConfigSkillDes(skillId, skillLevel)
    self.SkillTitle.text = name
    self.SkillText.text = intro
end

function XUiGridSwitchSkill:OnClickBtnSelect()
    XDataCenter.CharacterManager.ReqSwitchSkill(self.SkillId, self.SwitchCb)
end

return XUiGridSwitchSkill
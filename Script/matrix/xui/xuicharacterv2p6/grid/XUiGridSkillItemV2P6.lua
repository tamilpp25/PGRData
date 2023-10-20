local XUiGridSkillItemV2P6 = XClass(XUiNode, "XUiGridSkillItemV2P6")

function XUiGridSkillItemV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self:AutoInitUi()
end

function XUiGridSkillItemV2P6:AutoInitUi()
    self.Btn = self.Transform:GetComponent("XUiButton")
end

function XUiGridSkillItemV2P6:UpdateEnhanceSkillInfo(characterId, skillInfo)
    self.Btn:SetNameByGroup(0, skillInfo.Name)
    self.Btn:SetRawImage(skillInfo.Icon)
    local isShowRed = XRedPointManager.CheckConditions({ XRedPointConditions.Types.CONDITION_CHARACTER_ENHANCESKILL, XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS }, characterId)
    self.Btn:ShowReddot(isShowRed)
end

function XUiGridSkillItemV2P6:UpdateNormalSkillInfo(characterId, skill)
    self.Btn:SetNameByGroup(0, skill.Name)
    self.Btn:SetRawImage(skill.Icon)

    local canUpdate = false
    for _, subSkill in ipairs(skill.subSkills) do
        if (XDataCenter.CharacterManager.CheckCanUpdateSkill(characterId, subSkill.SubSkillId, subSkill.Level)) then
            canUpdate = true
            break
        end
    end
    self.Btn:ShowReddot(canUpdate)
end

function XUiGridSkillItemV2P6:SetClickCb(cb)
    if not cb then
        return
    end
    XUiHelper.RegisterClickEvent(self, self.Btn, function ()
        cb()
    end)
end

return XUiGridSkillItemV2P6

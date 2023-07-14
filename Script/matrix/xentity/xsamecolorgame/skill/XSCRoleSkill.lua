local XSCRoleSkill = XClass(nil, "XSCRoleSkill")

function XSCRoleSkill:Ctor(groupId)
    self.GroupId = groupId
    self.IsOn = false
end

function XSCRoleSkill:InitSwitch()
    self.IsOn = false
end

function XSCRoleSkill:ChangeSwitch()
    self.IsOn = not self.IsOn
end

function XSCRoleSkill:GetIsOn()
    return self.IsOn
end

function XSCRoleSkill:GetSkillGroupCfg()
    return XSameColorGameConfigs.GetSkillGroupConfig(self.GroupId)
end

function XSCRoleSkill:GetSkillGroupId()
    return self:GetSkillGroupCfg().Id
end

function XSCRoleSkill:GetShopItemId()
    return self:GetSkillGroupCfg().ShopItemId
end

function XSCRoleSkill:GetCD()
    return self:GetSkillGroupCfg().Cd
end

function XSCRoleSkill:GetOnSkillId()
    return self:GetSkillGroupCfg().OnSkillId
end

function XSCRoleSkill:GetOffSkillId()
    return self:GetSkillGroupCfg().SkillId
end

function XSCRoleSkill:GetSkillId()
    return self:GetIsOn() and self:GetOnSkillId() or self:GetOffSkillId()
end

function XSCRoleSkill:GetIsHasOnSkill()
    return self:GetOnSkillId() and self:GetOnSkillId() > 0
end

function XSCRoleSkill:GetSkillCfg(skillId)
    return XSameColorGameConfigs.GetSkillConfig(skillId or self:GetSkillId())
end

function XSCRoleSkill:GetIcon(skillId)
    return self:GetSkillCfg(skillId).Icon
end

function XSCRoleSkill:GetName(skillId)
    return self:GetSkillCfg(skillId).Name
end

function XSCRoleSkill:GetDesc(skillId)
    return self:GetSkillCfg(skillId).Desc
end

function XSCRoleSkill:GetScreenMaskType(skillId)
    return self:GetSkillCfg(skillId).ScreenMaskType
end

function XSCRoleSkill:GetControlType(skillId)
    return self:GetSkillCfg(skillId).ControlType
end

function XSCRoleSkill:GetIsShowCountdown(skillId)
    return self:GetSkillCfg(skillId).ShowCountdown
end

function XSCRoleSkill:GetHintText(skillId)
    return self:GetSkillCfg(skillId).HintText
end

function XSCRoleSkill:GetEnergyCost(skillId)
    return self:GetSkillCfg(skillId).EnergyCost
end

return XSCRoleSkill
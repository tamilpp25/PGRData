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

function XSCRoleSkill:GetCD(isTimeType)
    if isTimeType then
        return self:GetSkillGroupCfg().LimitTime
    else
        return self:GetSkillGroupCfg().Cd
    end
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

function XSCRoleSkill:GetDesc(isTimeType)
    if isTimeType then
        return self:GetSkillCfg().DescTimeType
    else
        return self:GetSkillCfg().Desc
    end
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

function XSCRoleSkill:GetHintText()
    local skillCfg = self:GetSkillCfg()
    local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    local isTimeType = battleManager:IsTimeType()
    if isTimeType then
        return skillCfg.HintTextTimeType
    else
        return skillCfg.HintText
    end
end

function XSCRoleSkill:GetEnergyCost(skillId)
    return self:GetSkillCfg(skillId).EnergyCost
end

function XSCRoleSkill:GetBuffIds(skillId)
    return self:GetSkillCfg(skillId).BuffIds
end

function XSCRoleSkill:IsForbidInTime(skillId)
    -- 增加步数的技能禁止在限时关卡使用
    local buffIds = self:GetBuffIds(skillId)
    for _, buffId in pairs(buffIds) do
        local buffCfg = XSameColorGameConfigs.GetBuffConfig(buffId)
        if buffCfg.Step ~= 0 then
            return true
        end
    end

    return false
end

function XSCRoleSkill:GetSkillComboType(skillId)
    return self:GetSkillCfg(skillId).SkillComboType
end

return XSCRoleSkill
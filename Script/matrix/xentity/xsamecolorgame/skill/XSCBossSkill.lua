local XSCBossSkill = XClass(nil, "XSCBossSkill")

function XSCBossSkill:Ctor(id)
    self.Config = XSameColorGameConfigs.GetBossSkillConfig(id)
end

function XSCBossSkill:GetId()
    return self.Config.Id
end

function XSCBossSkill:GetName()
    return self.Config.Name
end

function XSCBossSkill:GetIcon()
    return self.Config.Icon
end

function XSCBossSkill:GetDesc()
    return self.Config.Desc
end

function XSCBossSkill:GetTriggerRound()
    return self.Config.TriggerRound
end

function XSCBossSkill:GetSkipDamage()
    return self.Config.SkipDamage
end

return XSCBossSkill
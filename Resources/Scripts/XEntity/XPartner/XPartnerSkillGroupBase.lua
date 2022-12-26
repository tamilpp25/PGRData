local XPartnerSkillGroupBase = XClass(nil, "XPartnerSkillGroupBase")

function XPartnerSkillGroupBase:GetId()
    return self.Id
end

function XPartnerSkillGroupBase:GetLevel()
    return self.Level
end

function XPartnerSkillGroupBase:GetLevelStr()
    return self.Level < self.LevelLimit and self.Level or "MAX"
end

function XPartnerSkillGroupBase:GetActiveSkillId()
    return self.ActiveSkillId
end

function XPartnerSkillGroupBase:GetLevelLimit()
    return self.LevelLimit
end

function XPartnerSkillGroupBase:GetIsLock()
    return self.IsLock
end

function XPartnerSkillGroupBase:GetIsCarry()
    return self.IsCarry
end

--------------------------------------------SkillInfo---------------------------------------------------
function XPartnerSkillGroupBase:GetSkillInfoCfgByLevel(skillId, level)
    return XPartnerConfigs.GetPartnerSkillInfoByIdAndLevel(skillId or self.ActiveSkillId, level or self.Level) or {}
end

function XPartnerSkillGroupBase:GetSkillName(skillId, level)
    return self:GetSkillInfoCfgByLevel(skillId, level).Name
end

function XPartnerSkillGroupBase:GetSkillIcon(skillId, level)
    return self:GetSkillInfoCfgByLevel(skillId, level).Icon
end

function XPartnerSkillGroupBase:GetSkillDesc(skillId, level)
    return self:GetSkillInfoCfgByLevel(skillId, level).Desc
end

------------------------------------------SkillEffect-----------------------------------------------------
function XPartnerSkillGroupBase:GetActiveSkillEffectCfgByLevel(level)
    return XPartnerConfigs.GetPartnerSkillEffectByIdAndLevel(self.ActiveSkillId, level or self.Level) or {}
end

function XPartnerSkillGroupBase:GetActiveSkillAbility(level)
    return self:GetActiveSkillEffectCfgByLevel(level).Ability
end

function XPartnerSkillGroupBase:GetActiveSkillBornMagic(level)
    return self:GetActiveSkillEffectCfgByLevel(level).BornMagic
end

function XPartnerSkillGroupBase:GetActiveSkillSubSkillId(level)
    return self:GetActiveSkillEffectCfgByLevel(level).SubSkillId
end

function XPartnerSkillGroupBase:GetActiveSkillSubMagicId(level)
    return self:GetActiveSkillEffectCfgByLevel(level).SubMagicId
end

return XPartnerSkillGroupBase
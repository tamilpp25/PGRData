local XPartnerSkillGroupBase = require("XEntity/XPartner/XPartnerSkillGroupBase")
local XPartnerPassiveGroupSkill = XClass(XPartnerSkillGroupBase, "XPartnerPassiveGroupSkill")
local DefaultIndex = 1

function XPartnerPassiveGroupSkill:Ctor(id)
    self.Id = id
    self.Level = 1
    self.IsCarry = false
    self.IsLock = false--被动技能暂时不会上锁
    self:SetDefaultActiveSkillId()
    self.LevelLimit = XPartnerConfigs.GetPartnerSkillLevelLimit(self.ActiveSkillId)
end

function XPartnerPassiveGroupSkill:UpdateData(data)
    for key, value in pairs(data) do
        self[key] = value
    end
end

function XPartnerPassiveGroupSkill:GetSkillType()
    return XPartnerConfigs.SkillType.PassiveSkill
end

function XPartnerPassiveGroupSkill:SetDefaultActiveSkillId()
    self.ActiveSkillId = self:GetSkillIdList()[DefaultIndex]
end

function XPartnerPassiveGroupSkill:GetCfg()
    return XPartnerConfigs.GetPartnerPassiveSkillGroupById(self.Id)
end

function XPartnerPassiveGroupSkill:GetSkillIdList()
    return self:GetCfg().SkillId
end

return XPartnerPassiveGroupSkill
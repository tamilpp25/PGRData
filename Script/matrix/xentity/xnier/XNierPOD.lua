local XNierPOD = XClass(nil, "XNierPOD")

local Default = {
    Id = 0,
    Level = 0,
    Exp = 0
}

function XNierPOD:Ctor(data)
    self:UpdateNierPOD(data)
end

function XNierPOD:UpdateNierPOD(data)
    self.Id = data.SupportId
    self.Level = data.Level
    self.Exp = data.Exp
    self.SelectSkillId = data.SelectSkillId
    self.Config = XNieRConfigs.GetNieRSupportConfig(self.Id)
    self.SkillLevelDic = {}
    self.SkillInfoDic = {}
    for _, skill in ipairs(data.Skills) do
        self.SkillLevelDic[skill.SkillId] = skill.SkillLevel
    end

    self:InitSkillId()
end

function XNierPOD:InitSkillId()
    self.SkillList = {}
    for index, skillId in ipairs(self.Config.SkillIds) do
        local tmpSkill = {}
        tmpSkill.SkillId = skillId
        tmpSkill.PassiveFlags = self.Config.SkillPassiveFlags[index] or 0
        tmpSkill.Condit = self.Config.SkillConditions[index] or 0
        table.insert(self.SkillList, tmpSkill)
        self.SkillInfoDic[skillId] = tmpSkill
    end
end

function XNierPOD:GetNieRPODId()
    return self.Id
end

function XNierPOD:GetNieRPODLevel()
    return self.Level
end

function XNierPOD:GetNieRPODExp()
    return self.Exp
end

function XNierPOD:SetNieRPODSelectSkillId(skillId)
    self.SelectSkillId = skillId
end

function XNierPOD:GetNieRPODSelectSkillId()
    return self.SelectSkillId
end

function XNierPOD:GetFightSkillList()
    local skillList = {}
    for _, skillInfo in ipairs(self.SkillList) do
        
        if skillInfo.PassiveFlags == XNieRConfigs.NieRPodSkillType.ActiveSkill then
            local tmpSkillInfo = {}
            tmpSkillInfo.SkillId = skillInfo.SkillId
            tmpSkillInfo.IsActive, tmpSkillInfo.Desc = self:CheckNieRPODSkillActive(skillInfo.SkillId)
            table.insert(skillList, tmpSkillInfo)
        end
    end
    table.sort(skillList, function(a, b)
        if a.IsActive and not b.IsActive then
            return true
        elseif (a.IsActive and b.IsActive) or ( not a.IsActive and not b.IsActive ) then
            return a.SkillId < b.SkillId
        end
        return false
    end)
    return skillList
end

function XNierPOD:CheckNieRPODMaxLevel()
    return self:GetNieRPODLevel() >= XNieRConfigs.GetNieRSupportMaxLevelById(self:GetNieRPODId()) 
end

function XNierPOD:GetNieRPODMaxExp()
    return XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(self:GetNieRPODId(), self:GetNieRPODLevel()).MaxExp
end

function XNierPOD:GetNieRPODIcon()
    return XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(self:GetNieRPODId(), self:GetNieRPODLevel()).Icon
end

function XNierPOD:GetNieRPODHeadIcon()
    return XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(self:GetNieRPODId(), self:GetNieRPODLevel()).HeadIcon
end

function XNierPOD:GetNieRPODHeadBigIcon()
    return XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(self:GetNieRPODId(), self:GetNieRPODLevel()).HeadBigIcon
end

function XNierPOD:GetNieRPODModel()
    return XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(self:GetNieRPODId(), self:GetNieRPODLevel()).Model
end

function XNierPOD:GetNieRPODSkillList()
    return self.SkillList
end

function XNierPOD:GetNieRPODSkillLevelById(skillId)
    return self.SkillLevelDic[skillId] or 1
end

function XNierPOD:AddNieRPODSkillLevelById(skillId)
    if XNieRConfigs.GetNieRSupportMaxSkillLevelById(skillId) > self.SkillLevelDic[skillId] then
        self.SkillLevelDic[skillId] = self.SkillLevelDic[skillId] + 1
    end
end

function XNierPOD:GetNieRPODName()
    return XNieRConfigs.GetNieRSupportClientConfig(self:GetNieRPODId()).Name
end

function XNierPOD:GetNieRPODUpLevelItemId()
    return XNieRConfigs.GetNieRSupportClientConfig(self:GetNieRPODId()).UpLevelItem
end

function XNierPOD:CheckNieRPODSkillActive(skillId)
    local info = self.SkillInfoDic[skillId]
    local condit, desc = true, ""
    if info.Condit and info.Condit ~= 0 then
        condit, desc = XConditionManager.CheckCondition(info.Condit)
    end
    return condit, desc
end

function XNierPOD:CheckNieRPODSkillActiveSkill(skillId)
    local info = self.SkillInfoDic[skillId]
    if info and info.PassiveFlags == XNieRConfigs.NieRPodSkillType.ActiveSkill then
        return true
    end
    return false
end

function XNierPOD:CheckNieRPODSkillUpLevel(skillId)
    local info = XNieRConfigs.GetNieRSupportSkillLevelCfgBuyIdAndLevel(skillId, self:GetNieRPODSkillLevelById(skillId))
    local level = self:GetNieRPODSkillLevelById(skillId)
    local maxLevel = XNieRConfigs.GetNieRSupportMaxSkillLevelById(skillId)
    if level >= maxLevel then
        return false, ""
    end
    local condit, desc = true, ""
    if info.UpgradeCondition and info.UpgradeCondition ~= 0 then
        condit, desc = XConditionManager.CheckCondition(info.UpgradeCondition)
    end
    return condit, desc
end

function XNierPOD:GetNieRPODSkillUpLevelItem(skillId)
    local info = XNieRConfigs.GetNieRSupportSkillLevelCfgBuyIdAndLevel(skillId, self:GetNieRPODSkillLevelById(skillId))
    return info.UpgradeConsumeId, info.UpgradeConsumeCount
end

function XNierPOD:GetNieRPODSkillName(skillId)
    local info = XNieRConfigs.GetNieRSupportSkillClientConfig(skillId, self:GetNieRPODSkillLevelById(skillId))
    return info.Name
end

function XNierPOD:GetNieRPODSkillIcon(skillId)
    local info = XNieRConfigs.GetNieRSupportSkillClientConfig(skillId, self:GetNieRPODSkillLevelById(skillId))
    return info.Icon
end

function XNierPOD:GetNieRPODSkillDesc(skillId)
    local info = XNieRConfigs.GetNieRSupportSkillClientConfig(skillId, self:GetNieRPODSkillLevelById(skillId))
    return info.Desc
end

function XNierPOD:GetUpSkillLevelItem()
    return XNieRConfigs.GetNieRSupportClientConfig(self:GetNieRPODId()).UpSkillLevelItem
end

return XNierPOD
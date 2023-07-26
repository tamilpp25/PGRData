local XAdventureSkill = XClass(nil, "XAdventureSkill")

function XAdventureSkill:Ctor(id)
    self.Config = XTheatreConfigs.GetTheatreSkill(id)
end

function XAdventureSkill:GetId()
    return self.Config.Id
end

function XAdventureSkill:GetIcon()
    return self.Config.Icon
end

function XAdventureSkill:GetQualityIcon()
    return XTheatreConfigs.GetClientConfig("SkillQualityIcon", self.Config.Quality)
end

function XAdventureSkill:GetLevelQualityIcon()
    return XTheatreConfigs.GetClientConfig("SkillLevelQualityIcon", self.Config.Quality)
end

function XAdventureSkill:GetName()
    return self.Config.Name
end

function XAdventureSkill:GetDesc()
    return self.Config.Desc
end

function XAdventureSkill:GetLevelDesc()
    return XUiHelper.GetText("TheatreSkillLevelDesc"
        , XTheatreConfigs.GetClientConfig("SkillPosDesc", self.Config.Pos))
end

function XAdventureSkill:GetCurrentLevel()
    return self.Config.Lv
end

-- XTheatreConfigs.SkillType
function XAdventureSkill:GetSkillType()
    return self.Config.Type
end

-- 技能附加的战力
function XAdventureSkill:GetAdditionalPower()
    return self.Config.FightAbility
end

function XAdventureSkill:GetPowerId()
    return self.Config.PowerId
end

function XAdventureSkill:GetPowerIcon()
    return XTheatreConfigs.GetClientConfig("SkillPowerIcon", self:GetPowerId())
end

function XAdventureSkill:GetPowerTitle()
    return XTheatreConfigs.GetClientConfig("SkillPowerTitle", self:GetPowerId())
end

function XAdventureSkill:GetPos()
    return self.Config.Pos
end

-- 获取技能操作类型，升级或替换
function XAdventureSkill:GetSkillOperationType()
    if self.Config.Type == XTheatreConfigs.SkillType.Additional then
        return XTheatreConfigs.SkillOperationType.AddBuff, self
    end
    local allSkills = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentSkills()
    for _, skill in ipairs(allSkills) do
        if skill:GetPowerId() == self:GetPowerId() 
            and skill:GetPos() == self:GetPos() then
            return XTheatreConfigs.SkillOperationType.LevelUp, skill
        end
        if skill:GetPos() == self:GetPos() then
            return XTheatreConfigs.SkillOperationType.Replace, skill
        end
    end
    return XTheatreConfigs.SkillOperationType.LevelUp, self
end

return XAdventureSkill
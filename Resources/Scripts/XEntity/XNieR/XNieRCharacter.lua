local XNieRCharacter = XClass(nil, "XNieRCharacter")

function XNieRCharacter:Ctor(data)
    self:UpdateNieRCharacter(data)
end

function XNieRCharacter:UpdateNieRCharacter(data)
    self.Id = data.CharacterId
    self.Level = data.Level
    self.Exp = data.Exp
    self.FashionId = data.FashionId
    self.Config = XNieRConfigs.GetCharacterConfigById(data.CharacterId)
    self.ClientConfig = XNieRConfigs.GetCharacterClientConfigById(data.CharacterId)
    if not self.LastLevel or self.LastLevel ~= self.Level then
        self.LevelConfig = XNieRConfigs.GetCharacterLevelConfig(data.CharacterId, data.Level)
    end
    self.LastLevel = data.Level
    self.NeedUpdateNieRCharAbility = true
end

function XNieRCharacter:ResetNeedUpdateNieRCharAbility()
    self.NeedUpdateNieRCharAbility = true
end

function XNieRCharacter:GetAllNieRAbilityConfigList()
    return XNieRConfigs.GetAbilityGroupConfigByGroupId(self.Config.AbilityGroupId) or {}
end

function XNieRCharacter:UpdateCharacterAbility()
    if not self.NeedUpdateNieRCharAbility then return end
    self.NeedUpdateNieRCharAbility = false
    local configList = XNieRConfigs.GetAbilityGroupConfigByGroupId(self.Config.AbilityGroupId)
    table.sort(configList, function(a, b)
        return a.Id > b.Id
    end)

    local tmpConfig = {}
    local configCount = #configList
    --tmpConfig.Skills = {}
    tmpConfig.SkillsData = {}
    tmpConfig.FashionIds = {}
    for index = 1, configCount, 1 do
        local config = configList[index]

        if config.Condition == 0 or XConditionManager.CheckCondition(config.Condition) then

            if config.SkillId ~= 0 and config.SkillLevel ~= 0 and (not tmpConfig.SkillsData[config.SkillId] or (tmpConfig.SkillsData[config.SkillId] and tmpConfig.SkillsData[config.SkillId]) < config.SkillLevel) then
                --tmpConfig.Skills[config.SkillId] = config.Id
                tmpConfig.SkillsData[config.SkillId] = config.SkillLevel
            elseif config.FashionId ~= 0 then
                tmpConfig.FashionIds[config.FashionId] = config.Id
            elseif not tmpConfig.WeaponConfigId and config.WeaponId ~= 0 then
                tmpConfig.WeaponConfigId = config.Id
                tmpConfig.WeaponId = config.WeaponId
            elseif not tmpConfig.FourWafer and #(config.WaferId) == 4 then
                tmpConfig.FourWafer = config.Id
            elseif not tmpConfig.TwoWafer and #(config.WaferId) == 2 then
                tmpConfig.TwoWafer = config.Id
            end

        end
    end


    tmpConfig.Wafers = {}
    if tmpConfig.FourWafer and tmpConfig.FourWafer ~= 0 then
        local config = XNieRConfigs.GetAbilityGroupConfigById(tmpConfig.FourWafer)
        for key, waferId in pairs(config.WaferId) do
            tmpConfig.Wafers[waferId] = config.WaferBreakThrough[key]
        end
    end

    if tmpConfig.TwoWafer and tmpConfig.TwoWafer ~= 0 then
        local config = XNieRConfigs.GetAbilityGroupConfigById(tmpConfig.TwoWafer)
        for key, waferId in pairs(config.WaferId) do
            tmpConfig.Wafers[waferId] = config.WaferBreakThrough[key]
        end
    end
    self.AbilityConfig = tmpConfig
end

function XNieRCharacter:GetNieRCharacterId()
    return self.Id
end

function XNieRCharacter:GetNieRCharacterLevel()
    return self.Level or 0
end

function XNieRCharacter:GetNieRCharacterExp()
    return self.Exp or 0
end

function XNieRCharacter:GetNieRCharacterCfgEasterEggFightTag()
    return self.Config.EasterEggFightTag
end

function XNieRCharacter:ChangeNieRFashionId(fashionId)
    self.FashionId = fashionId
end

function XNieRCharacter:CheckNieRCharacterMaxLevel()
    local maxLevel = XNieRConfigs.GetCharacterMaxLevelById(self:GetNieRCharacterId())
    return self:GetNieRCharacterLevel() >= maxLevel
end

function XNieRCharacter:CheckNieRCharacterCondition()
    local check, desc = true, ""
    if self.Config.Condition ~= 0 then
        check, desc = XConditionManager.CheckCondition(self.Config.Condition)
    end
    return check, desc
end

function XNieRCharacter:GetNieRFashionId()
    local fashionId = self.FashionId
    if not fashionId or fashionId == 0 then
        local robotCfg = XRobotManager.GetRobotTemplate(self:GetNieRCharacterRobotId())
        fashionId = robotCfg.FashionId
    end
    return fashionId
end

function XNieRCharacter:GetNieRFashionList()
    self:UpdateCharacterAbility()
    local fashionList = {}
    for fId, confId in pairs(self.AbilityConfig.FashionIds) do
        table.insert(fashionList, fId)
    end
    local dressFashionId = self:GetNieRFashionId()
    if #fashionList > 1 then
        table.sort(fashionList, function(a, b)
            local status1, status2 = a == dressFashionId and 1 or 0, b == dressFashionId and 1 or 0

            if status1 ~= status2 then
                return status1 > status2
            end

            return XDataCenter.FashionManager.GetFashionPriority(a) > XDataCenter.FashionManager.GetFashionPriority(b)
        end)
    end
    return fashionList
end

function XNieRCharacter:GetNieRCharacterMaxExp()
    return self.LevelConfig.MaxExp
end

function XNieRCharacter:GetNieRCharacterRobotId()
    return self.LevelConfig.RobotId
end

function XNieRCharacter:GetNieRWeaponId()
    self:UpdateCharacterAbility()
    local weaponId = self.AbilityConfig.WeaponId
    if not weaponId or weaponId == 0 then
        local robotCfg = XRobotManager.GetRobotTemplate(self:GetNieRCharacterRobotId())
        weaponId = robotCfg.WeaponId
    end
    return weaponId
end

function XNieRCharacter:GetNieRWeaponLevel()
    self:UpdateCharacterAbility()
    local weaponLevel = self.LevelConfig.WeaponLevel
    local limitLevel = 0
    if self.AbilityConfig.WeaponId then
        limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(self.AbilityConfig.WeaponId, self:GetNieRWeaponBreakThrough())
        weaponLevel = weaponLevel > limitLevel and limitLevel or weaponLevel
    else
        weaponLevel = 1
    end

    return weaponLevel
end

function XNieRCharacter:GetNieRWeaponBreakThrough()
    self:UpdateCharacterAbility()
    if not self.AbilityConfig.WeaponConfigId then
        return 0
    end
    return XNieRConfigs.GetAbilityGroupConfigById(self.AbilityConfig.WeaponConfigId).WeaponBreakThrough
end

function XNieRCharacter:GetNieRWaferLevel(waferId)
    self:UpdateCharacterAbility()
    local waferLevel = self.LevelConfig.WaferLevel
    local limitLevel = 0
    if self.AbilityConfig.Wafers[waferId] then
        limitLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(waferId, self:GetNieRWaferBreakThroughById(waferId))
        waferLevel = waferLevel > limitLevel and limitLevel or waferLevel
    else
        waferLevel = 1
    end
    return waferLevel
end

function XNieRCharacter:GetNieRWaferBreakThroughById(id)
    self:UpdateCharacterAbility()
    return self.AbilityConfig.Wafers[id] or 0
end

function XNieRCharacter:GetAbilityList()
    local configList = XNieRConfigs.GetAbilityGroupConfigByGroupId(self.Config.AbilityGroupId)
    local abilityList = {}
    local tmpAbility = {}
    for _, cfg in pairs(configList) do
        if cfg.Condition ~= 0 then
            if cfg.SkillId ~= 0 then
                tmpAbility = {}
                tmpAbility.ConfigId = cfg.Id
                tmpAbility.Type = XNieRConfigs.AbilityType.Skill
            elseif cfg.FashionId ~= 0 then
                tmpAbility = {}
                tmpAbility.ConfigId = cfg.Id
                tmpAbility.Type = XNieRConfigs.AbilityType.Fashion
            elseif cfg.WeaponId ~= 0 then
                tmpAbility = {}
                tmpAbility.ConfigId = cfg.Id
                tmpAbility.Type = XNieRConfigs.AbilityType.Weapon
            elseif #(cfg.WaferId) == 4 then
                tmpAbility = {}
                tmpAbility.ConfigId = cfg.Id
                tmpAbility.Type = XNieRConfigs.AbilityType.FourWafer
            elseif #(cfg.WaferId) == 2 then
                tmpAbility = {}
                tmpAbility.ConfigId = cfg.Id
                tmpAbility.Type = XNieRConfigs.AbilityType.TwoWafer
            end
            table.insert(abilityList, tmpAbility)
        end
    end

    table.sort(abilityList, function(a, b)
        local aPriority, bPriority = XNieRConfigs.GetAbilityGroupConfigById(a.ConfigId).Priority or 0, XNieRConfigs.GetAbilityGroupConfigById(b.ConfigId).Priority or 0
        return aPriority < bPriority
    end)

    return abilityList
end

function XNieRCharacter:UpdateAttribs()
    self:UpdateCharacterAbility()

    local robotId = self:GetNieRCharacterRobotId()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    local robotTemp = XRobotManager.GetRobotTemp(robotId)

    local equips = {}
    if self.AbilityConfig.WeaponId and self.AbilityConfig.WeaponId ~= 0 then
        local weapon = {
            AwakeSlotList = {},
            TemplateId = self.AbilityConfig.WeaponId,
            Level = self:GetNieRWeaponLevel(),
            ResonanceInfo = {},
            Breakthrough = self:GetNieRWeaponBreakThrough()
        }
        table.insert(equips, weapon)
    else
        local weapon = {
            AwakeSlotList = {},
            TemplateId = robotCfg.WeaponId,
            Level = robotCfg.WeaponLevel,
            ResonanceInfo = {},
            Breakthrough = robotCfg.WeaponBeakThrough
        }
        table.insert(equips, weapon)
    end
    if self.AbilityConfig.Wafers and next(self.AbilityConfig.Wafers) ~= nil then
        for waferId, breakthrough in pairs(self.AbilityConfig.Wafers) do
            local newAware = {
                AwakeSlotList = {},
                TemplateId = waferId,
                Level = self:GetNieRWaferLevel(waferId),
                ResonanceInfo = {},
                Breakthrough = breakthrough
            }
            table.insert(equips, newAware)
        end
    else
        for index, waferId in ipairs(robotCfg.WaferId) do
            local newAware = {
                AwakeSlotList = {},
                TemplateId = waferId,
                Level = robotCfg.WaferLevel[index],
                ResonanceInfo = {},
                Breakthrough = robotCfg.WaferBreakThrough[index]
            }
            table.insert(equips, newAware)
        end
    end
    robotTemp:SetEquips(equips)

    self.Attribs = robotTemp:GetAtrributes()
end

function XNieRCharacter:GetAttribs()
    self:UpdateAttribs()
    return self.Attribs
end

function XNieRCharacter:UpdateAbility()
    self:UpdateCharacterAbility()
    local attribs = self:GetAttribs()
    local attribAbility = XAttribManager.GetAttribAbility(attribs)
    local skillData = XRobotManager.GetRobotSkillLevelDic(self:GetNieRCharacterRobotId())
    if next(self.AbilityConfig.SkillsData) ~= nil then
        for skillId, skillLevel in pairs(self.AbilityConfig.SkillsData) do
            skillData[skillId] = skillLevel
        end
    end
    local skillAbility = XDataCenter.CharacterManager.GetSkillAbility(skillData)
    self.AbilityNum = attribAbility + skillAbility
end

function XNieRCharacter:GetAbilityNum()
    self:UpdateAbility()
    return self.AbilityNum
end

function XNieRCharacter:GetTeachingStageIds()
    return self.Config.TeachingStageIds
end

function XNieRCharacter:GetRobotCharacterId()
    return XRobotManager.GetCharacterId(self:GetNieRCharacterRobotId())
end

function XNieRCharacter:GetRobotCharacterCareerType()
    local characterDetailCfg = XCharacterConfigs.GetCharDetailTemplate(self:GetRobotCharacterId())
    return characterDetailCfg.Career
end

function XNieRCharacter:GetNieRCharacterUpLevelItemId()
    return self.ClientConfig.UpLevelItem or 0
end

function XNieRCharacter:GetNieRCharacterIcon()
    return self.ClientConfig.Icon
end

function XNieRCharacter:GetNieRClientPos()
    return self.ClientConfig.Pos
end

function XNieRCharacter:GetNieRClientSkipId()
    return self.ClientConfig.SkipId
end

function XNieRCharacter:GetNieRCharName()
    local characterId = self:GetRobotCharacterId()
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    local nameStr = charConfig.Name
    -- if charConfig.TradeName ~= "" then
    --     nameStr = nameStr .. "·" .. charConfig.TradeName
    -- end
    return nameStr
end

return XNieRCharacter
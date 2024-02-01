local XRobot = require("XEntity/XRobot/XRobot")
local type = type
local MAIN_SKILL_INDEX = 4  --主动技能
local PASSIVE_SKILL_INDEX = 5 --被动技能

---@class XTheatreAdventureRole
local XAdventureRole = XClass(nil, "XAdventureRole")

function XAdventureRole:Ctor(id)
    -- XCharacter | XRobot
    self.RawData = nil
    self.Config = XTheatreConfigs.GetTheatreRole(id)
    -- 是否在本地角色
    self.IsLocalRole = false
    self.Id = self:GetFilterId() -- 适配筛选
end

function XAdventureRole:GetFilterId()
    if not self:GetIsLocalRole() then
        return self:GetRawData():GetId()
    end
    return self:GetCharacterId()
end

function XAdventureRole:GetId()
    if self:GetIsLocalRole() then
        return self:GetRawData():GetId()
    end
    return self.Config.Id
end

function XAdventureRole:GetRawDataId()
    return self:GetRawData():GetId()
end

-- value : XCharacter
function XAdventureRole:SetCharacter(value)
    self.RawData = value
    self.IsLocalRole = true
    self.Id = self:GetFilterId() -- 适配筛选
end

-- 职业标签
function XAdventureRole:GetProfessionTag()
    -- todo
end

function XAdventureRole:GetRawData()
    if self.RawData == nil and not self:GetIsLocalRole() then
        self:GenerateNewRobot()
    end
    return self.RawData
end

function XAdventureRole:GetAllRobotConfigs()
    if self.IsLocalRole then return {} end
    return XTheatreConfigs.GetRoleRobotConfig(self.Config.Id)
end

-- 生成新的机器人
function XAdventureRole:GenerateNewRobot(level)
    -- 本地角色不需要生成机器人
    if self.IsLocalRole then return end
    if level == nil then
        level = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentLevel()
    end
    local robotConfig = XTheatreConfigs.GetRoleRobotConfig(self.Config.Id, level)
    local newRobotId = robotConfig.RobotId
    if self.RawData == nil or self.RawData:GetId() ~= newRobotId then
        self.RawData = XRobot.New(newRobotId)
    end
    return self.RawData
end

-- 生成自身角色
function XAdventureRole:GenerateLocalRole()
    if self.IsLocalRole then return end
    local characterId = self:GetCharacterId()
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    if not character then return end
    local role = XDataCenter.TheatreManager.GetCurrentAdventureManager():AddRoleById(characterId, self.Config.Id)
    role:SetCharacter(character)
end

---@return XCharacterViewModel
function XAdventureRole:GetCharacterViewModel()
    local characterViewModel = self:GetRawData():GetCharacterViewModel()
    if not self:GetIsLocalRole() then
        characterViewModel:UpdateAbility(self:GetAbility())
    end
    return characterViewModel
end

-- 获取配置显示标签图标
function XAdventureRole:GetTagIcons()
    return self.Config.TagIcons
end

function XAdventureRole:GetProfessionName()
    return "todo"
end

function XAdventureRole:GetProfessionIcon()
    return "todo"
end

function XAdventureRole:GetIsLocalRole()
    return self.IsLocalRole
end

function XAdventureRole:GetAbility()
    if not self:GetIsLocalRole() then
        --角色本身基础战力
        local level = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentLevel()
        local robotConfig = XTheatreConfigs.GetRoleRobotConfig(self.Config.Id, level)
        local baseAbility = robotConfig.FightAbility

        --当前拥有的TheatreSkill表技能的战力
        local skillsPower = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentSkillsPower()

        return math.floor(baseAbility + skillsPower)
    end
    return self:GetCharacterViewModel():GetAbility()
end

--返回最小排序值的属性Id
function XAdventureRole:GetMinSortOrderElementId(stageId)
    local elementList = self:GetElementList()
    local elementSortOrder
    local elementSortOrderTemp
    local isomer = self:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Isomer
    for _, elementId in ipairs(elementList) do
        elementSortOrderTemp = XTheatreConfigs.GetTheatreAutoTeamElementSortOrder(stageId, elementId, isomer)
        elementSortOrder = (elementSortOrder and elementSortOrder < elementSortOrderTemp) and elementSortOrder or elementSortOrderTemp
    end
    return elementSortOrder
end

--返回是否有相同的属性
function XAdventureRole:IsSameElement(stageId, elementId)
    local elementList = self:GetElementList()

    --只判断单属性
    if XTheatreConfigs.GetTheatreAutoTeamIsOnlyOneElement(stageId, elementId) then
        return #elementList == 1 and elementList[1] == elementId
    end
    
    --判断是否含有相同的属性
    for _, elementIdSelf in ipairs(elementList) do
        if elementIdSelf == elementId then
            return true
        end
    end
    return false
end

function XAdventureRole:GetSmallHeadIcon()
    return self:GetCharacterViewModel():GetSmallHeadIcon()
end

function XAdventureRole:GetRoleName()
    return self:GetCharacterViewModel():GetFullName()
end

function XAdventureRole:IsRobot()
    return not self.IsLocalRole
end

function XAdventureRole:GetCharacterType()
    return self:GetCharacterViewModel():GetCharacterType()
end

function XAdventureRole:GetElementList()
    return self:GetCharacterViewModel():GetObtainElements()
end

function XAdventureRole:GetCharacterId()
    return self:GetCharacterViewModel():GetId()
end

function XAdventureRole:GetCareerType()
    return self:GetCharacterViewModel():GetCareer()
end

-- 获得装备中的武器
function XAdventureRole:GetWeaponEquip()
    if self:GetIsLocalRole() then
        local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(self:GetCharacterId())
        return XDataCenter.EquipManager.GetEquip(equipId)        
    end
    
    local rawdData = self:GetRawData()
    local weaponviewModel = rawdData:GetWeaponViewModel()
    return weaponviewModel:GetEquip()
end

-- 获得装备中的意识
function XAdventureRole:GetWearingEquipBySite(equipSite)
    if self:GetIsLocalRole() then
        local characterId = self:GetCharacterId()
        return XDataCenter.EquipManager.GetWearingEquipBySite(characterId, equipSite)
    end
    
    local rawdData = self:GetRawData()
    local awarenessViewModelDic = rawdData:GetAwarenessViewModelDic()
    local viewModel = awarenessViewModelDic[equipSite]
    return viewModel and viewModel:GetEquip() 
end

--获得激活的意识4件套和2件套
function XAdventureRole:GetSuitMergeActiveDatas()
    local datas = {}
    local suitIdSet = {}
    local suitIdToLevelDec = {}
    local setSuitMaxLv = 0 --已设置2件套的最高等级
    if self:GetIsLocalRole() then
        local characterId = self:GetCharacterId()
        local wearingAwarenessIds = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(characterId)
        for _, equipId in pairs(wearingAwarenessIds) do
            local suitId = XDataCenter.EquipManager.GetSuitId(equipId)
            if suitId > 0 then
                local count = suitIdSet[suitId]
                suitIdSet[suitId] = count and count + 1 or 1

                local equip = XDataCenter.EquipManager.GetEquip(equipId)
                local level = equip.Level
                if not suitIdToLevelDec[suitId] or suitIdToLevelDec[suitId] < level then
                    suitIdToLevelDec[suitId] = level
                end
            end
        end
    else
        local rawdData = self:GetRawData()
        local awarenessViewModelDic = rawdData:GetAwarenessViewModelDic()
        for equipSite, viewModel in pairs(awarenessViewModelDic) do
            local suitId = viewModel:GetSuitId()
            if suitId > 0 then
                local count = suitIdSet[suitId]
                suitIdSet[suitId] = count and count + 1 or 1

                if not suitIdToLevelDec[suitId] or suitIdToLevelDec[suitId] < viewModel:GetLevel() then
                    suitIdToLevelDec[suitId] = viewModel:GetLevel()
                end
            end
        end
    end

    --设置4件套数据，并找出需要设置2件套数据的套装Id
    local setTwoSuitId
    for suitId, count in pairs(suitIdSet) do
        if count >= 4 then
            table.insert(datas, {
                SuitId = suitId,
                Count = count,
                Level = suitIdToLevelDec[suitId],
                Icon = XDataCenter.EquipManager.GetSuitIconBagPath(suitId)
            })
        elseif count >= 2 and suitIdToLevelDec[suitId] > setSuitMaxLv then
            setTwoSuitId = suitId
            setSuitMaxLv = suitIdToLevelDec[suitId]
        end
    end

    if setTwoSuitId then
        table.insert(datas, {
            SuitId = setTwoSuitId,
            Count = suitIdSet[setTwoSuitId],
            Level = suitIdToLevelDec[setTwoSuitId],
            Icon = XDataCenter.EquipManager.GetSuitIconBagPath(setTwoSuitId)
        })
    end
    return datas
end

function XAdventureRole:GetLevel()
    if self:GetIsLocalRole() then
        return self:GetCharacterViewModel():GetLevel()
    end
    return XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentLevel()
end

function XAdventureRole:GetSkill()
    local characterId = self:GetCharacterId()
    local character
    local skills
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    if self:GetIsLocalRole() then
        skills = XMVCA.XCharacter:GetCharacterSkills(characterId)
    else
        local npcData = self:GetRawData():GetNpcData()
        local skillLevelMap = XFightCharacterManager.GetCharSkillLevelMap(npcData)
        skills = {}
        for i = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
            skills[i] = {}
            skills[i].subSkills = {}
            local posDic = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(characterId)
            local skillGroupIds = posDic[i]
            local skillIdList = {}
            for _, skillGroupId in pairs(skillGroupIds) do
                local skillId = XMVCA.XCharacter:GetGroupDefaultSkillId(skillGroupId)
                if skillId > 0 then
                    table.insert(skillIdList, skillId)
                end
            end

            for _, skillId in pairs(skillIdList) do
                local skillCo = {}
                local skillType = XMVCA.XCharacter:GetSkillType(skillId)
                local spSkillLevel = self:GetRawData():GetAfterSpSkillLevel(skillId)

                skillCo.Level = adventureManager:GetCoreSkillLv(skillType) or (spSkillLevel and spSkillLevel or skillLevelMap[skillId]) or 0
                local configDes = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillCo.Level)
                if configDes then
                    skillCo.configDes = configDes
                end

                table.insert(skills[i].subSkills, skillCo)
            end
        end
    end

    return skills
end

function XAdventureRole:GetCurExp()
    local charViewModel = self:GetCharacterViewModel()
    local curExp = charViewModel:GetCurExp()
    if self:GetIsLocalRole() then
        return curExp
    end

    local isMaxLevel = self:GetLevel() == self:GetMaxLevel()
    return isMaxLevel and curExp or 0 
end

function XAdventureRole:GetNextLevelExp()
    local charViewModel = self:GetCharacterViewModel()
    return charViewModel:GetNextLevelExp()
end

function XAdventureRole:GetMaxLevel()
    if self:GetIsLocalRole() then
        local charViewModel = self:GetCharacterViewModel()
        return charViewModel:GetMaxLevel()
    end
    return XTheatreConfigs.GetMaxLevel()
end

return XAdventureRole
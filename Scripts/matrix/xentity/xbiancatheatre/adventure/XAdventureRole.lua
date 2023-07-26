local XRobot = require("XEntity/XRobot/XRobot")
local type = type
local MAIN_SKILL_INDEX = 4  --主动技能
local PASSIVE_SKILL_INDEX = 5 --被动技能

local XAdventureRole = XClass(nil, "XAdventureRole")

function XAdventureRole:Ctor(id, isRobot, isDecay)
    -- XCharacter | XRobot
    self.RawData = nil
    self.Id = id    --BiancaTheatreBaseCharacter表的CharacterId
    -- 是否实际有本地角色
    self.IsLocalRole = false
    --是否是试玩角色
    self.IsRobot = isRobot or false
    -- 是否腐化
    self.IsDecay = isDecay or false
    --羁绊星级
    self.Level = 1 
    self.MaxRank = XBiancaTheatreConfigs.GetCharacterMaxLevel(id)
    self:InitChildComboIdDic()
end

--初始化角色拥有的羁绊Id字典
function XAdventureRole:InitChildComboIdDic()
    self.ChildComboIdDic = {}
    for _, childComboId in ipairs(self:GetCharacterComboIds()) do
        self.ChildComboIdDic[childComboId] = true
    end
end

function XAdventureRole:GetBaseId()
    return self.Id
end

function XAdventureRole:GetId()
    if self:GetIsRobot() then
        return self:GetRawDataId()
    end
    return self.Id
end

function XAdventureRole:GetRawDataId()
    return self:GetRawData():GetId()
end

-- value : XCharacter
function XAdventureRole:SetCharacter(value)
    self.RawData = value
    self.IsLocalRole = true
end

function XAdventureRole:UpdateLevel(level)
    if XTool.IsNumberValid(level) then
        self.Level = level
        self:GenerateNewRobot()
    end
end

function XAdventureRole:UpdateDecay(IsDecay)
    self.IsDecay = IsDecay
end

function XAdventureRole:GetIsDecay()
    return self.IsDecay
end

--================
--获取角色等级展示字符串
--================
function XAdventureRole:GetLevelStr()
    local level = self:GetLevel()
    if level >= self.MaxRank then return CS.XTextManager.GetText("ExpeditionMaxRank") end
    return level
end

-- 该角色是否已被招募
function XAdventureRole:GetIsInRecruit()
    return XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetRole(self:GetId()) and true or false
end

function XAdventureRole:GetLevel()
    return self.Level
end

-- 职业标签
function XAdventureRole:GetProfessionTag()
    -- todo
end

function XAdventureRole:SetRawData(rawData)
    self.RawData = rawData
end

function XAdventureRole:GetRawData()
    if self:GetIsRobot() then
        return self:GenerateNewRobot()
    end
    
    return self.RawData or self:GenerateNewRobot()  --无本地角色，用试玩角色的
end

function XAdventureRole:GetRobotRole()
    if not self.RobotAdventureRole then
        self.RobotAdventureRole = XTool.Clone(self)
        self.RobotAdventureRole:SetIsRobot(true)
    end
    return self.RobotAdventureRole
end

-- 生成新的机器人
function XAdventureRole:GenerateNewRobot()
    local baseId = self:GetBaseId()
    local level = self:GetLevel()
    local characterLevelId = XBiancaTheatreConfigs.GetTheatreCharacterId(baseId, level)
    if not characterLevelId then
        XLog.Error(string.format("生成机器人数据失败，Id：%s, Level：%s", baseId, level))
        return
    end

    local newRobotId = XBiancaTheatreConfigs.GetCharacterRobotId(characterLevelId)
    local robotRole = self:GetRobotRole()
    local rawData = robotRole.RawData
    if rawData == nil or rawData:GetId() ~= newRobotId or robotRole:GetLevel() ~= level then
        rawData = XRobot.New(newRobotId)
        robotRole:SetRawData(rawData)
        robotRole:UpdateLevel(level)
    end
    return rawData
end

-- 生成自身角色
function XAdventureRole:GenerateLocalRole()
    if self:GetIsLocalRole() then return end
    local characterId = self:GetCharacterId()
    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    if not character then return end
    self:SetCharacter(character)
end

function XAdventureRole:GetCharacterViewModel()
    local characterViewModel = self:GetRawData():GetCharacterViewModel()
    return characterViewModel
end

-- 获取配置显示标签图标
function XAdventureRole:GetTagIcons()
    
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

function XAdventureRole:SetIsRobot(isRobot)
    self.IsRobot = isRobot
end

function XAdventureRole:GetIsRobot()
    return self.IsRobot
end

function XAdventureRole:GetAbility()
    local ability = self:GetCharacterViewModel():GetAbility()
    local starAbility = self:GetStarAbility()
    return ability + starAbility
end

--获得星级加成战力
function XAdventureRole:GetStarAbility()
    local id = XBiancaTheatreConfigs.GetTheatreCharacterId(self:GetBaseId(), self:GetLevel())
    return XBiancaTheatreConfigs.GetCharacterFightAbility(id)
end

--返回最小排序值的属性Id
function XAdventureRole:GetMinSortOrderElementId(stageId)
    local elementList = self:GetElementList()
    local elementSortOrder
    local elementSortOrderTemp
    local isomer = self:GetCharacterType() == XCharacterConfigs.CharacterType.Isomer
    for _, elementId in ipairs(elementList) do
        elementSortOrderTemp = XBiancaTheatreConfigs.GetTheatreAutoTeamElementSortOrder(stageId, elementId, isomer)
        elementSortOrder = (elementSortOrder and elementSortOrder < elementSortOrderTemp) and elementSortOrder or elementSortOrderTemp
    end
    return elementSortOrder
end

--返回是否有相同的属性
function XAdventureRole:IsSameElement(stageId, elementId)
    local elementList = self:GetElementList()

    --只判断单属性
    if XBiancaTheatreConfigs.GetTheatreAutoTeamIsOnlyOneElement(stageId, elementId) then
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

function XAdventureRole:GetRoleNotFullName()
    return self:GetCharacterViewModel():GetName()
end

--================
--获取角色机型名称
--================
function XAdventureRole:GetCharacterTradeName()
    return self:GetCharacterViewModel():GetTradeName()
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

function XAdventureRole:GetSkill()
    local characterId = self:GetCharacterId()
    local character
    local skills
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    if self:GetIsLocalRole() then
        skills = XCharacterConfigs.GetCharacterSkills(characterId)
    else
        local npcData = self:GetRawData():GetNpcData()
        local skillLevelMap = XFightCharacterManager.GetCharSkillLevelMap(npcData)
        skills = {}
        for i = 1, XCharacterConfigs.MAX_SHOW_SKILL_POS do
            skills[i] = {}
            skills[i].subSkills = {}
            local posDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
            local skillGroupIds = posDic[i]
            local skillIdList = {}
            for _, skillGroupId in pairs(skillGroupIds) do
                local skillId = XCharacterConfigs.GetGroupDefaultSkillId(skillGroupId)
                if skillId > 0 then
                    table.insert(skillIdList, skillId)
                end
            end

            for _, skillId in pairs(skillIdList) do
                local skillCo = {}
                local skillType = XCharacterConfigs.GetSkillType(skillId)
                skillCo.Level = adventureManager:GetCoreSkillLv(skillType) or skillLevelMap[skillId] or 0
                local configDes = XCharacterConfigs.GetSkillGradeDesConfig(skillId, skillCo.Level)
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
    return XBiancaTheatreConfigs.GetMaxLevel()
end

--获得角色拥有的羁绊Id列表
function XAdventureRole:GetCharacterComboIds()
    local id = XBiancaTheatreConfigs.GetBaseCharacterId(self:GetBaseId())
    return XBiancaTheatreConfigs.GetBaseCharacterReferenceComboId(id)
end

function XAdventureRole:IsCombo(childComboId)
    return self.ChildComboIdDic[childComboId]
end

return XAdventureRole
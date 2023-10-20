---@class XCharacterAgency : XAgency
---@field _Model XCharacterModel
local XCharacterAgency = XClass(XAgency, "XCharacterAgency")
local type = type
local pairs = pairs

local table = table
local tableSort = table.sort
local tableInsert = table.insert
local mathMin = math.min
local mathMax = math.max
local stringFormat = string.format
local CsXTextManagerGetText = CsXTextManagerGetText

-- service config begin --
local METHOD_NAME = {
    LevelUp = "CharacterLevelUpRequest",
    ActivateStar = "CharacterActivateStarRequest",
    PromoteQuality = "CharacterPromoteQualityRequest",
    PromoteGrade = "CharacterPromoteGradeRequest",
    ExchangeCharacter = "CharacterExchangeRequest",
    UnlockSubSkill = "CharacterUnlockSkillGroupRequest",
    UpgradeSubSkill = "CharacterUpgradeSkillGroupRequest",
    SwitchSkill = "CharacterSwitchSkillRequest",
    UnlockEnhanceSkill = "CharacterUnlockEnhanceSkillRequest",
    UpgradeEnhanceSkill = "CharacterUpgradeEnhanceSkillRequest",
}

function XCharacterAgency:OnInit()
    --初始化一些变量
end

function XCharacterAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyCharacterDataList = handler(self, self.NotifyCharacterDataListV2P6)
end

function XCharacterAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
-- 检查该角色是否是碎片


---**********************************************************************************************************************************

-- service config end --
function XCharacterAgency:HasDuplicateCharId(tbl)
    local seen = {}

    for index, value in pairs(tbl) do
        local charId = XRobotManager.GetCharacterId(value)
        if seen[charId] then
            return true, index
        end
        seen[charId] = true
    end

    return false
end

-- 是否展示独域/跃升技能
function XCharacterAgency:CheckIsShowEnhanceSkill(charId)
    local characterType = self:GetCharacterType(charId)
    local character = self:GetCharacter(charId)
    local functionId = characterType == XCharacterConfigs.CharacterType.Normal and XFunctionManager.FunctionName.CharacterEnhanceSkill or XFunctionManager.FunctionName.SpCharacterEnhanceSkill
    local IsShowEnhanceSkill = character:GetIsHasEnhanceSkill() and not XFunctionManager.CheckFunctionFitter(functionId)
    return IsShowEnhanceSkill
end

-- 是否展示跃升技能开启的提示
function XCharacterAgency:CheckIsShowNewEnhanceTips(characterId)
    -- 只有泛用机的跃升技能才提示
    if self:GetIsIsomer(characterId) then
        return false
    end

    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterEnhanceSkill) then
        return false
    end

    -- 已经查看过了
    local character = self:GetCharacter(characterId)
    if not character or character.IsEnhanceSkillNotice then
        return false
    end

    -- 角色是否有开启跃升技能功能
    if not character:GetIsHasEnhanceSkill() then
        return false
    end

    -- 黑名单
    local blackList = CS.XGame.ClientConfig:GetString("CharacterEnhanceSkillTipsBlackList")
    blackList = string.Split(blackList)
    if table.contains(blackList, tostring(characterId)) then
        return false
    end

    return true
end

function XCharacterAgency:CheckIsCharOrRobot(id)
    if XRobotManager.CheckIsRobotId(id) then
        return true
    end

    if self:GetCharacterTemplate(id) then
        return true
    end
    
    return false
end

function XCharacterAgency:CheckIsFragment(id)
    if self:IsOwnCharacter(id) then
        return false
    end
    
    if XRobotManager.CheckIsRobotId(id) then
        return false
    end
    
    return true
end

function XCharacterAgency:CheckIsNewStateForSort(id)
    local char = self:GetCharacter(id)
    if char.CollectState then
        return false
    end

    return XTool.IsNumberValid(char.NewFlag)
end

function XCharacterAgency:GetCharUnlockFragment(templateId)
    if not templateId then
        XLog.Error("self:GetCharUnlockFragment函数参数错误, 参数templateId不能为空")
        return
    end

    local curCharItemId = self:GetCharacterTemplate(templateId).ItemId
    if not curCharItemId then
        XLog.ErrorTableDataNotFound("self:GetCharUnlockFragment",
        "curCharItemId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    local item = XDataCenter.ItemManager.GetItem(curCharItemId)

    if not item then
        return 0
    end

    return item.Count
end

function XCharacterAgency:NewCharacter(character)
    if character == nil or character.Id == nil then
        XLog.Error("self:NewCharacter函数参数不能为空或者参数的Id字段不能为空")
        return
    end
    return XCharacter.New(character)
end

function XCharacterAgency:InitCharacters(characters)
    for _, character in pairs(characters) do
        self._Model.OwnCharacters[character.Id] = self:NewCharacter(character)
    end
end

---@return XCharacter
function XCharacterAgency:GetCharacter(id)
    return self._Model.OwnCharacters[id]
end

function XCharacterAgency:IsOwnCharacter(characterId)
    return self._Model.OwnCharacters[characterId] ~= nil
end

local DefaultSort = function(a, b)
    if a.Level ~= b.Level then
        return a.Level > b.Level
    end

    if a.Quality ~= b.Quality then
        return a.Quality > b.Quality
    end

    local priorityA = XMVCA.XCharacter:GetCharacterPriority(a.Id)
    local priorityB = XMVCA.XCharacter:GetCharacterPriority(b.Id)

    if priorityA ~= priorityB then
        return priorityA < priorityB
    end

    return a.Id > b.Id
end

function XCharacterAgency:GetDefaultSortFunc()
    return DefaultSort
end

--==============================--
--desc: 获取卡牌列表(获得)
--@return 卡牌列表
--==============================--
function XCharacterAgency:GetCharacterList(characterType, isUseTempSelectTag, isAscendOrder, isUseNewSort)
    local characterList = {}

    local isNeedIsomer
    if characterType then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            isNeedIsomer = false
        elseif characterType == XCharacterConfigs.CharacterType.Isomer then
            isNeedIsomer = true
        end
    end

    local unOwnCharList = {}
    for k, v in pairs(self:GetCharacterTemplates()) do
        if not isUseNewSort or XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(k, characterType, isUseTempSelectTag) then
            if self._Model.OwnCharacters[k] then
                if isNeedIsomer == nil then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                elseif isNeedIsomer and XCharacterConfigs.IsIsomer(k) then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                elseif isNeedIsomer == false and not XCharacterConfigs.IsIsomer(k) then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                end
            else
                if isNeedIsomer == nil then
                    tableInsert(unOwnCharList, v)
                elseif isNeedIsomer and XCharacterConfigs.IsIsomer(k) then
                    tableInsert(unOwnCharList, v)
                elseif isNeedIsomer == false and not XCharacterConfigs.IsIsomer(k) then
                    tableInsert(unOwnCharList, v)
                end
            end
        end
    end

    -- 合并列表
    for _, char in pairs(unOwnCharList) do
        tableInsert(characterList, char)
    end
    -- v2.6 使用筛选器拍戏了不需要再在这排序
    -- characterList = XDataCenter.CommonCharacterFiltManager.DoSort(characterList)

    return characterList
end

function XCharacterAgency:GetOwnCharacterList(characterType, isUseNewSort)
    local characterList = {}

    local isNeedIsomer
    if characterType then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            isNeedIsomer = false
        elseif characterType == XCharacterConfigs.CharacterType.Isomer then
            isNeedIsomer = true
        end
    end

    for characterId, v in pairs(self._Model.OwnCharacters) do
        if not isUseNewSort or XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(characterId, characterType) then
            if isNeedIsomer == nil then
                tableInsert(characterList, v)
            elseif isNeedIsomer and XCharacterConfigs.IsIsomer(characterId) then
                tableInsert(characterList, v)
            elseif isNeedIsomer == false and not XCharacterConfigs.IsIsomer(characterId) then
                tableInsert(characterList, v)
            end
        end
    end

    tableSort(characterList, function(a, b)
        if isUseNewSort then
            return XDataCenter.RoomCharFilterTipsManager.GetSort(a.Id, b.Id, characterType)
        end
        return DefaultSort(a, b)
    end)

    return characterList
end

function XCharacterAgency:GetCharacterCountByAbility(ability)
    local count = 0
    for _, v in pairs(self._Model.OwnCharacters) do
        local curAbility = self:GetCharacterAbility(v)
        if curAbility and curAbility >= ability then
            count = count + 1
        end
    end

    return count
end


--队伍预设列表排序特殊处理
function XCharacterAgency:GetSpecilOwnCharacterList()
    local characterList = {}
    for _, v in pairs(self._Model.OwnCharacters) do
        tableInsert(characterList, v)
    end

    tableSort(characterList, function(a, b)
        return DefaultSort(a, b)
    end)

    local specilList = {}

    for k, v in pairs(characterList) do
        if k % 2 ~= 0 then
            tableInsert(specilList, v)
        end
    end

    for k, v in pairs(characterList) do
        if k % 2 == 0 then
            tableInsert(specilList, v)
        end
    end

    return specilList
end

function XCharacterAgency:GetCharacterListInTeam(characterType)
    local characterList = self:GetOwnCharacterList(characterType)

    tableSort(characterList, function(a, b)
        local isInteamA = XDataCenter.TeamManager.CheckInTeam(a.Id)
        local isInteamB = XDataCenter.TeamManager.CheckInTeam(b.Id)

        if isInteamA ~= isInteamB then
            return isInteamA
        end

        return DefaultSort(a, b)
    end)

    return characterList
end

function XCharacterAgency:GetCharacterIdListInTeam(characterType)
    local characterList = self:GetOwnCharacterList(characterType)
    local idList = {}
    tableSort(characterList, function(a, b)
        local isInteamA = XDataCenter.TeamManager.CheckInTeam(a.Id)
        local isInteamB = XDataCenter.TeamManager.CheckInTeam(b.Id)

        if isInteamA ~= isInteamB then
            return isInteamA
        end

        return DefaultSort(a, b)
    end)

    for _, char in pairs(characterList) do
        table.insert(idList, char.Id)
    end
    return idList
end

function XCharacterAgency:GetAssignCharacterListInTeam(characterType, tmpTeamIdDic)
    local characterList = self:GetOwnCharacterList(characterType)

    tableSort(characterList, function(a, b)
        local isInteamA = tmpTeamIdDic[a.Id]
        local isInteamB = tmpTeamIdDic[b.Id]

        if isInteamA ~= isInteamB then
            return isInteamB
        end
        return DefaultSort(a, b)
    end)
    return characterList
end

function XCharacterAgency:GetRobotAndCharacterIdList(robotIdList, characterType)
    local characterList = self:GetOwnCharacterList(characterType)
    local idList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    for _, char in pairs(characterList) do
        table.insert(idList, char.Id)
    end
    return idList
end

--根据robotIdList返回已拥有的角色Id列表
function XCharacterAgency:GetRobotCorrespondCharacterIdList(robotIdList, characterType)
    if XTool.IsNumberValid(characterType) then
        robotIdList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    end

    local ownCharacterIdList = {}
    local charId
    for _, robotId in ipairs(robotIdList) do
        charId = XRobotManager.GetCharacterId(robotId)
        if self:IsOwnCharacter(charId) then
            table.insert(ownCharacterIdList, charId)
        end
    end
    return ownCharacterIdList
end

--根据robotIdList返回已拥有的角色列表
function XCharacterAgency:GetRobotCorrespondCharacterList(robotIdList, characterType)
    if XTool.IsNumberValid(characterType) then
        robotIdList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    end

    local ownCharacterList = {}
    for _, robotId in ipairs(robotIdList) do
        local charId = XRobotManager.GetCharacterId(robotId)
        local char  = self:GetCharacter(charId)
        if char then
            table.insert(ownCharacterList, char)
        end
    end
    return ownCharacterList
end

--根据robotIdList返回试玩和已拥有的角色列表
function XCharacterAgency:GetRobotAndCorrespondCharacterIdList(robotIdList, characterType)
    robotIdList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    local characterList = self:GetRobotCorrespondCharacterIdList(robotIdList)
    local idList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    for _, charId in pairs(characterList) do
        table.insert(idList, charId)
    end
    return idList
end

function XCharacterAgency:IsUseItemEnough(itemIds, itemCounts)
    if not itemIds then
        return true
    end

    if type(itemIds) == "number" then
        if type(itemCounts) == "table" then
            itemCounts = itemCounts[1]
        end

        return XDataCenter.ItemManager.CheckItemCountById(itemIds, itemCounts)
    end

    itemCounts = itemCounts or {}
    for i = 1, #itemIds do
        local key = itemIds[i]
        local count = itemCounts[i] or 0

        if not XDataCenter.ItemManager.CheckItemCountById(key, count) then
            return false
        end
    end

    return true
end

function XCharacterAgency:AddCharacter(charData)
    local character = self:NewCharacter(charData)
    self._Model.OwnCharacters[character.Id] = character
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ADD_SYNC, character)
    return character
end

local function GetAttribGroupIdList(character)
    local npcTemplate = XCharacterConfigs.GetNpcTemplate(character.NpcId)
    if not npcTemplate then
        return
    end

    return XDataCenter.BaseEquipManager.GetAttribGroupIdListByType(npcTemplate.Type)
end

function XCharacterAgency:GetSkillPlus(character)
    local list = XDataCenter.FubenAssignManager.GetSkillPlusIdList()

    if not list then
        return
    end

    local skillPlus = {}
    for _, plusId in pairs(list) do
        local plusList = XCharacterConfigs.GetSkillPlusList(character.Id, character.Type, plusId)
        if plusList then
            for _, skillId in pairs(plusList) do
                local level = character:GetSkillLevelBySkillId(skillId)
                if level and level > 0 then
                    if skillPlus[skillId] then
                        skillPlus[skillId] = skillPlus[skillId] + 1
                    else
                        skillPlus[skillId] = 1
                    end
                end
            end
        end
    end

    return skillPlus
end

function XCharacterAgency:GetSkillPlusOther(character, assignChapterRecords)
    local list = XDataCenter.FubenAssignManager.GetSkillPlusIdListOther(assignChapterRecords)
    if not list then
        return
    end
    local skillPlus = {}
    for _, plusId in pairs(list) do
        local plusList = XCharacterConfigs.GetSkillPlusList(character.Id, character.Type, plusId)
        if plusList then
            for _, skillId in pairs(plusList) do
                local level = character:GetSkillLevelBySkillId(skillId)
                if level and level > 0 then
                    if skillPlus[skillId] then
                        skillPlus[skillId] = skillPlus[skillId] + 1
                    else
                        skillPlus[skillId] = 1
                    end
                end
            end
        end
    end

    return skillPlus
end

function XCharacterAgency:GetFightNpcData(characterId)
    local character = characterId

    if type(characterId) == "number" then
        character = self:GetCharacter(characterId)
        if not character then
            return
        end
    end

    local equipDataList = XDataCenter.EquipManager.GetCharacterWearingEquips(character.Id)
    if not equipDataList then
        return
    end

    local groupIdList = GetAttribGroupIdList(character)
    if not groupIdList then
        return
    end

    return {
        Character = character,
        Equips = equipDataList,
        AttribGroupList = groupIdList, --基地装备用（已废弃）
        CharacterSkillPlus = self:GetSkillPlus(character)
    }
end

function XCharacterAgency:GetFightNpcDataOther(character, equipList, assignChapterRecords)
    local equipDataList = equipList
    if not equipDataList then
        return
    end

    local groupIdList = GetAttribGroupIdList(character)
    if not groupIdList then
        return
    end

    return {
        Character = character,
        Equips = equipDataList,
        AttribGroupList = groupIdList,
        CharacterSkillPlus = self:GetSkillPlusOther(character, assignChapterRecords)
    }
end


function XCharacterAgency:GetCharacterAttribs(character)
    local npcData = self:GetFightNpcData(character)
    if not npcData then
        return
    end

    return XAttribManager.GetNpcAttribs(npcData)
end

function XCharacterAgency:GetCharacterAttribsOther(character, equipList, assignChapterRecords)
    local npcData = self:GetFightNpcDataOther(character, equipList, assignChapterRecords)
    if not npcData then
        return
    end

    return XAttribManager.GetNpcAttribs(npcData)
end

local function GetSkillAbility(skillList)
    local ability = 0
    for id, level in pairs(skillList) do
        ability = ability + XCharacterConfigs.GetSubSkillAbility(id, level)
    end
    return ability
end

local function GetResonanceSkillAbility(skillList, useSkillMap)
    if not skillList then
        return 0
    end

    if not useSkillMap then
        return 0
    end

    local ability = 0
    for id, level in pairs(skillList) do
        if useSkillMap[id] then
            ability = ability + XCharacterConfigs.GetResonanceSkillAbility(id, level)
        end
    end
    return ability
end
XCharacterAgency.GetResonanceSkillAbility = GetResonanceSkillAbility

local function GetPlusSkillAbility(skillList, useSkillMap)
    if not skillList then
        return 0
    end

    if not useSkillMap then
        return 0
    end

    local ability = 0
    for id, level in pairs(skillList) do
        if useSkillMap[id] then
            ability = ability + XCharacterConfigs.GetPlusSkillAbility(id, level)
        end
    end

    return ability
end

function XCharacterAgency:GetCharacterAbility(character)
    local npcData = self:GetFightNpcData(character)
    if not npcData then
        return 0
    end

    --属性战力
    local baseAbility = XAttribManager.GetAttribAbility(character.Attribs) or 0

    --技能战力
    local skillLevel = XFightCharacterManager.GetCharSkillLevelMap(npcData)
    local skillAbility = GetSkillAbility(skillLevel)
    
    --补强技能战力
    local enhanceSkillAbility = 0
    if character.GetEnhanceSkillAbility then
        enhanceSkillAbility = character:GetEnhanceSkillAbility()
    end

    --装备共鸣战力
    local resonanceSkillLevel = XFightCharacterManager.GetResonanceSkillLevelMap(npcData)
    local resonanceSkillAbility = GetResonanceSkillAbility(resonanceSkillLevel, skillLevel)

    --边界公约驻守增加技能等级战力
    local plusSkillAbility = GetPlusSkillAbility(npcData.CharacterSkillPlus, skillLevel)

    --装备技能战力
    local equipAbility = XDataCenter.EquipManager.GetEquipSkillAbility(character.Id) or 0

    --伙伴战力
    local partnerAbility = XDataCenter.PartnerManager.GetCarryPartnerAbilityByCarrierId(character.Id)

    --武器超限战力
    local equip = XDataCenter.EquipManager.GetCharacterWearingWeapon(character.Id)
    local overrunAbility = equip and equip:GetOverrunAbility() or 0

    return baseAbility + skillAbility + resonanceSkillAbility + plusSkillAbility + equipAbility + partnerAbility + enhanceSkillAbility + overrunAbility
end

-- partner : XPartner
function XCharacterAgency:GetCharacterAbilityOther(character, equipList, assignChapterRecords, partner)
    local npcData = self:GetFightNpcDataOther(character, equipList, assignChapterRecords)
    if not npcData then
        return
    end

    local attribs = self:GetCharacterAttribsOther(character, equipList, assignChapterRecords)
    local baseAbility = XAttribManager.GetAttribAbility(attribs)
    if not baseAbility then
        return
    end

    local skillLevel = XFightCharacterManager.GetCharSkillLevelMap(npcData)
    local skillAbility = GetSkillAbility(skillLevel)
    
    --补强技能战力
    local enhanceSkillAbility = 0
    if character.GetEnhanceSkillAbility then
        enhanceSkillAbility = character:GetEnhanceSkillAbility()
    end

    local resonanceSkillLevel = XFightCharacterManager.GetResonanceSkillLevelMap(npcData)
    local resonanceSkillAbility = GetResonanceSkillAbility(resonanceSkillLevel, skillLevel)

    local plusSkillAbility = GetPlusSkillAbility(npcData.CharacterSkillPlus, skillLevel)

    local equipAbility = XDataCenter.EquipManager.GetEquipSkillAbilityOther(character, equipList)
    if not equipAbility then
        return
    end
    -- 宠物战力
    local partnerAbility = XDataCenter.PartnerManager.GetCarryPartnerAbility(partner)

    --武器超限战力
    local overrunAbility = 0
    for _, equip in pairs(equipList) do
        if equip and equip:IsWeapon() then 
            overrunAbility = equip:GetOverrunAbility()
        end
    end

    return baseAbility + skillAbility + resonanceSkillAbility + plusSkillAbility + equipAbility + partnerAbility + enhanceSkillAbility + overrunAbility
end

-- 根据id获得身上角色战力
function XCharacterAgency:GetCharacterAbilityById(characterId)
    local character = self._Model.OwnCharacters[characterId]
    return character and self:GetCharacterAbility(character) or 0
end

function XCharacterAgency:GetMaxOwnCharacterAbility()
    local maxAbility = 0

    for _, character in pairs(self._Model.OwnCharacters) do
        local ability = self:GetCharacterAbility(character)
        maxAbility = mathMax(ability, maxAbility)
    end

    return maxAbility
end

function XCharacterAgency:GetNpcBaseAttrib(npcId)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)
    if not npcTemplate then
        XLog.ErrorTableDataNotFound("self:GetNpcBaseAttrib", "npcTemplate", "Client/Fight/Npc/Npc.tab", "npcId", tostring(npcId))
        return
    end
    return XAttribManager.GetBaseAttribs(npcTemplate.AttribId)
end

-- 升级相关begin --
function XCharacterAgency:IsOverLevel(templateId)
    local curLevel = XPlayer.Level
    local char = self:GetCharacter(templateId)
    return char and char.Level >= curLevel
end

function XCharacterAgency:IsMaxLevel(templateId)
    local char = self:GetCharacter(templateId)
    local maxLevel = self:GetCharMaxLevel(templateId)
    return char and char.Level >= maxLevel
end

function XCharacterAgency:CalLevelAndExp(character, exp)
    local teamLevel = XPlayer.Level
    local id = character.Id
    local curExp = character.Exp + exp
    local curLevel = character.Level

    local maxLevel = self:GetCharMaxLevel(id)

    while curLevel do
        local nextLevelExp = self:GetNextLevelExp(id, curLevel)
        if ((curExp >= nextLevelExp) and (curLevel < teamLevel)) then
            if curLevel == maxLevel then
                curExp = nextLevelExp
                break
            else
                curExp = curExp - nextLevelExp
                curLevel = curLevel + 1
                if (curLevel >= teamLevel) then
                    break
                end
            end
        else
            break
        end
    end
    return curLevel, curExp
end

function XCharacterAgency:GetMaxAvailableLevel(templateId)
    if not templateId then
        return
    end

    local charMaxLevel = self:GetCharMaxLevel(templateId)
    local playerMaxLevel = XPlayer.Level

    return mathMin(charMaxLevel, playerMaxLevel)
end

function XCharacterAgency:GetMaxLevelNeedExp(character)
    local id = character.Id
    local levelUpTemplateId = self:GetCharacterTemplate(id).LevelUpTemplateId
    local levelUpTemplate = XCharacterConfigs.GetLevelUpTemplate(levelUpTemplateId)
    local maxLevel = self:GetCharMaxLevel(id)
    local totalExp = 0
    for i = character.Level, maxLevel - 1 do
        totalExp = totalExp + levelUpTemplate[i].Exp
    end

    return totalExp - character.Exp
end
-- 升级相关end --
-- 品质相关begin --
function XCharacterAgency:IsMaxQuality(character)
    if not character then
        XLog.Error("self:IsMaxQuality函数参数character不能为空")
        return
    end

    return character.Quality >= self:GetCharMaxQuality(character.Id)
end

function XCharacterAgency:IsMaxQualityById(characterId)
    if not characterId then
        return
    end

    local character = self:GetCharacter(characterId)
    return character and character.Quality >= self:GetCharMaxQuality(character.Id)
end

function XCharacterAgency:IsCanActivateStar(character)
    if not character then
        XLog.Error("self:IsCanActivateStar函数参数character不能为空")
        return
    end

    if character.Quality >= self:GetCharMaxQuality(character.Id) then
        return false
    end

    if character.Star >= XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        return false
    end

    return true
end

function XCharacterAgency:IsActivateStarUseItemEnough(templateId, quality, star)
    if not templateId or not quality or not star then
        local tmpStr = "self:IsCharQualityStarUseItemEnough函数参数错误:, 参数templateId是"
        XLog.Error(tmpStr .. templateId .. " 参数quality是" .. quality .. " 参数star是" .. star)
        return
    end

    local template = self:GetCharacterTemplate(templateId)
    if not template then
        XLog.ErrorTableDataNotFound("self:IsCharQualityStarUseItemEnough",
        "template", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    if quality < 1 then
        XLog.Error("self:IsCharQualityStarUseItemEnough错误: 参数quality不能小于1, 参数quality是: " .. quality)
        return
    end

    if star < 1 or star > XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        local tmpStr = "self:IsCharQualityStarUseItemEnough函数错误: 参数star不能小于1或者大于"
        XLog.Error(tmpStr .. XEnumConst.CHARACTER.MAX_QUALITY_STAR .. ", 参数star是: " .. star)
        return
    end

    local itemKey = template.ItemId
    local characterType = self:GetCharacterType(templateId)
    local itemCount = XCharacterConfigs.GetStarUseCount(characterType, quality, star)

    return self:IsUseItemEnough(itemKey, itemCount)
end

function XCharacterAgency:IsCanPromoted(characterId)
    local character = self:GetCharacter(characterId)
    local hasCoin = XDataCenter.ItemManager.GetCoinsNum()
    local characterType = self:GetCharacterType(characterId)
    local useCoin = XCharacterConfigs.GetPromoteUseCoin(characterType, character.Quality)

    return hasCoin >= useCoin
end

--得到角色需要展示的 fashionId
function XCharacterAgency:GetShowFashionId(templateId, isNotSelf)
    -- 默认优先拿自己的数据
    if isNotSelf == nil then isNotSelf = false end
    -- 不属于自身数据的直接获取本地即可
    if isNotSelf then
        return self:GetCharacterTemplate(templateId).DefaultNpcFashtionId
    end
    if self:IsOwnCharacter(templateId) == true then
        return self._Model.OwnCharacters[templateId].FashionId
    else
        return self:GetCharacterTemplate(templateId).DefaultNpcFashtionId
    end
end

--得到角色需要展示的时装头像信息
function XCharacterAgency:GetCharacterFashionHeadInfo(templateId, isNotSelf)
    local headFashionId, headFashionType = self:GetShowFashionId(templateId, isNotSelf), XFashionConfigs.HeadPortraitType.Default

    --不是自己拥有的角色，返回默认头像类型，默认涂装Id
    if isNotSelf then
        return headFashionId, headFashionType
    end

    local character = self._Model.OwnCharacters[templateId]
    if not XTool.IsTableEmpty(character) then
        local headInfo = character.CharacterHeadInfo or {}
        if XTool.IsNumberValid(headInfo.HeadFashionId) then
            headFashionId = headInfo.HeadFashionId
        end
        if headInfo.HeadFashionType then
            headFashionType = headInfo.HeadFashionType
        end
    end

    return headFashionId, headFashionType
end

function XCharacterAgency:CharacterSetHeadInfoRequest(characterId, headFashionId, headFashionType, cb)
    local req = { TemplateId = characterId, CharacterHeadInfo = {
        HeadFashionId = headFashionId or self:GetShowFashionId(characterId),
        HeadFashionType = headFashionType or XFashionConfigs.HeadPortraitType.Default,
    } }

    XNetwork.Call("CharacterSetHeadInfoRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:GetCharHalfBodyBigImage(templateId) --获得角色半身像（剧情用）
    local fashionId = self:GetShowFashionId(templateId)

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharHalfBodyBigImage",
        "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    return XDataCenter.FashionManager.GetFashionHalfBodyImage(fashionId)
end

function XCharacterAgency:GetCharHalfBodyImage(templateId) --获得角色半身像（通用）
    local fashionId = self:GetShowFashionId(templateId)

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharHalfBodyImage",
        "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    return XDataCenter.FashionManager.GetRoleCharacterBigImage(fashionId)
end

function XCharacterAgency:GetCharSmallHeadIcon(templateId, isNotSelf, headFashionId, headFashionType) --获得角色小头像
    local characterId = XCharacterCuteConfig.GetCharacterIdByNpcId(templateId)
    if characterId then
        local stageId = XDataCenter.FubenManager.GetCurrentStageId()
        if XDataCenter.FubenSpecialTrainManager.IsStageCute(stageId) then
            return XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
        end
        templateId = characterId
    end

    if not XTool.IsNumberValid(headFashionId)
    or not headFashionType
    then
        headFashionId, headFashionType = self:GetCharacterFashionHeadInfo(templateId, isNotSelf)
    end
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(headFashionId, headFashionType)
end

function XCharacterAgency:GetCharSmallHeadIconByCharacter(character) --获得角色小头像(战斗用)
    local headInfo = character.CharacterHeadInfo or {}
    return self:GetCharSmallHeadIcon(character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
end

function XCharacterAgency:GetCharBigHeadIcon(templateId, isNotSelf, headFashionId, headFashionType) --获得角色大头像
    if not XTool.IsNumberValid(headFashionId)
    or not headFashionType
    then
        headFashionId, headFashionType = self:GetCharacterFashionHeadInfo(templateId, isNotSelf)
    end
    return XDataCenter.FashionManager.GetFashionBigHeadIcon(headFashionId, headFashionType)
end

function XCharacterAgency:GetCharRoundnessHeadIcon(templateId) --获得角色圆头像
    local fashionId = self:GetShowFashionId(templateId)

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharRoundnessHeadIcon",
        "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    return XDataCenter.FashionManager.GetFashionRoundnessHeadIcon(fashionId)
end

function XCharacterAgency:GetCharBigRoundnessHeadIcon(templateId) --获得角色大圆头像
    local fashionId = self:GetShowFashionId(templateId)

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharBigRoundnessHeadIcon",
        "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    return XDataCenter.FashionManager.GetFashionBigRoundnessHeadIcon(fashionId)
end

function XCharacterAgency:GetCharBigRoundnessNotItemHeadIcon(templateId, liberateLv) --获得角色圆头像(非物品使用)
    local fashionId = self:GetShowFashionId(templateId)

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharBigRoundnessNotItemHeadIcon",
        "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    -- local isAchieveMaxLiberation = not liberateLv and XDataCenter.ExhibitionManager.IsAchieveLiberation(templateId, XCharacterConfigs.GrowUpLevel.Higher) 
    -- or (liberateLv > XCharacterConfigs.GrowUpLevel.Higher)
    local isAchieveMaxLiberation = nil
    if liberateLv then
        isAchieveMaxLiberation = liberateLv >= XCharacterConfigs.GrowUpLevel.Higher
    else
        isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsAchieveLiberation(templateId, XCharacterConfigs.GrowUpLevel.Higher)
    end

    local result = isAchieveMaxLiberation and XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId) or
    XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
    return result
end

function XCharacterAgency:GetFightCharHeadIcon(character, characterId) --获得战斗角色头像
    local fashionId = character.FashionId
    local isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsAchieveLiberation(characterId or character.Id, XCharacterConfigs.GrowUpLevel.Higher)
    if isAchieveMaxLiberation then
        return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId)
    else
        return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
    end
end

function XCharacterAgency:GetCharShowFashionSceneUrl(templateId) --获取角色需要显示时装所关联的场景路径
    if not templateId then
        XLog.Error("self:GetCharShowFashionSceneUrl函数参数错误, 参数templateId不能为空")
        return
    end

    local fashionId = self:GetShowFashionId(templateId)
    if not fashionId then
        XLog.Error("self:GetCharShowFashionSceneUrl函数参数错误, 获取fashionId失败")
        return
    end

    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(fashionId)
    return sceneUrl
end

--v1.28-升阶拆分-获取角色所有品质升阶信息
function XCharacterAgency:GetCharQualitySkillInfo(characterId)
    local character = self:GetCharacter(characterId)
    local skillList = character.SkillList
    local data = XCharacterConfigs.GetCharSkillQualityApartDicByCharacterId(characterId)
    local result = {}
    for _, template in pairs(data) do
        for _, templateId in pairs(template) do
            for _, id in pairs(templateId) do
                local skillId = XCharacterConfigs.GetCharSkillQualityApartSkillId(id)
                local _, index = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
                if character:IsSkillUsing(skillId) then
                    table.insert(result, id)
                elseif not skillList[index] then
                    table.insert(result, templateId[1])
                end
            end
        end
    end
    table.sort(result, function (a, b)
        if XCharacterConfigs.GetCharSkillQualityApartQuality(a) == XCharacterConfigs.GetCharSkillQualityApartQuality(b) then
            return XCharacterConfigs.GetCharSkillQualityApartPhase(a) < XCharacterConfigs.GetCharSkillQualityApartPhase(b)
        else
            return XCharacterConfigs.GetCharSkillQualityApartQuality(a) < XCharacterConfigs.GetCharSkillQualityApartQuality(b)
        end
    end)
    return result
end

--v1.28-升阶拆分-获取角色升阶技能文本
function XCharacterAgency:GetCharQualitySkillName(characterId, quality, star)
    local character = self:GetCharacter(characterId)
    local skillList = character.SkillList
    local data = XCharacterConfigs.GetCharSkillQualityApartDicByStar(characterId, quality, star)
    for _, templateId in pairs(data) do
        local skillId = XCharacterConfigs.GetCharSkillQualityApartSkillId(templateId)
        local _, index = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
        if character:IsSkillUsing(skillId) then
            local skillName = XCharacterConfigs.GetCharSkillQualityApartName(templateId)
            local skillLevel = XCharacterConfigs.GetCharSkillQualityApartLevel(templateId)
            return XUiHelper.GetText("CharacterQualitySkillTipText", skillName, skillLevel)
        elseif not skillList[index] then
            local skillName = XCharacterConfigs.GetCharSkillQualityApartName(data[1])
            local skillLevel = XCharacterConfigs.GetCharSkillQualityApartLevel(data[1])
            return XUiHelper.GetText("CharacterQualitySkillTipText", skillName, skillLevel)
        end
    end
    return ""
end

function XCharacterAgency:GetCharQualityAttributeInfo(characterId)
    local attributeData = {}
    local characterMinQuality = self:GetCharMinQuality(characterId)
    local characterMaxQuality = self:GetCharMaxQuality(characterId)
    local attritubues = {}
    for i = characterMinQuality, characterMaxQuality do
        local attrbis = self:GetNpcPromotedAttribByQuality(characterId, i)
        local temp = {}
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Life])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.AttackNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.DefenseNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Crit])))
        table.insert(temp, i)
        table.insert(attritubues, temp)
    end
    --处理品质前后数值变化
    for i = 1, #attritubues - 1 do
        local result = {}
        table.insert(result, attritubues[i])
        table.insert(result, attritubues[i + 1])
        table.insert(attributeData, result)
    end

    return attributeData
end

function XCharacterAgency:GetCharQualityAttributeInfoV2P6(characterId)
    local characterMinQuality = self:GetCharMinQuality(characterId)
    local characterMaxQuality = self:GetCharMaxQuality(characterId)
    local attritubues = {}
    for i = characterMinQuality, characterMaxQuality do
        local attrbis = self:GetNpcPromotedAttribByQuality(characterId, i)
        local temp = {}
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Life])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.AttackNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.DefenseNormal])))
        table.insert(temp, stringFormat("%.2f", FixToDouble(attrbis[XNpcAttribType.Crit])))
        table.insert(temp, i)
        table.insert(attritubues, temp)
    end

    return attritubues
end

function XCharacterAgency:GetCharQualityAddAttributeTotalInfoV2P6(characterId, targetQuality, targetStarIndex)
    local char = self:GetCharacter(characterId)
    local addAttrRes = {}
    for starIndex = 1, (targetStarIndex or char.Star) do
        local attribs = self:GetCharCurStarAttribsV2P6(characterId, targetQuality or char.Quality, starIndex)
        for k, v in pairs(attribs or {}) do
            local value = FixToDouble(v)
            if value > 0 then
                if not addAttrRes[k] then
                    addAttrRes[k] = 0
                end
                addAttrRes[k] = addAttrRes[k] + value
                break -- 只取第一个有效值
            end
        end
    end
    return addAttrRes
end

-- 品质相关end --
-- 改造相关begin --
function XCharacterAgency:IsMaxCharGrade(character)
    return character.Grade >= self:GetCharMaxGrade(character.Id)
end

function XCharacterAgency:IsPromoteGradeUseItemEnough(templateId, grade)
    if not templateId or not grade then
        XLog.Error("self:IsPromoteGradeUseItemEnough参数不能为空: 参数templateId是 " .. templateId .. " 参数grade是" .. grade)
        return
    end

    local gradeConfig = XCharacterConfigs.GetGradeTemplates(templateId, grade)
    if not gradeConfig then
        XLog.ErrorTableDataNotFound("self:IsPromoteGradeUseItemEnough",
        "gradeConfig", "Share/Character/Grade/CharacterGrade.tab", "grade", tostring(grade))
        return
    end

    local itemKey, itemCount = gradeConfig.UseItemKey, gradeConfig.UseItemCount
    if not itemKey then
        return true
    end

    return self:IsUseItemEnough(itemKey, itemCount)
end

-- 查看有没有设置过超解球颜色，并返回球的颜色
function XCharacterAgency:CheckHasSuperExhibitionBallColor(charId)
    local character  = self:GetCharacter(charId)
    if not character then
        return nil
    end

    local magicIdColorBallList = CS.XGame.Config:GetString("HigherLiberateLvMagicId")
    magicIdColorBallList = string.Split(magicIdColorBallList, "|")

    local magicList = character.MagicList
    for k, v in pairs(magicList or {}) do
        for k2, magicId in pairs(magicIdColorBallList) do
            if v.Id == tonumber(magicId)  then
                return k2 -- 球的颜色 具体看枚举 XCharacterConfigs.CharacterLiberateBallColorType
            end
        end
    end

    return nil
end

-- 检测角色是否所有技能满级
function XCharacterAgency:CheckCharacterAllSkillMax(charId)
    if not self:IsOwnCharacter(charId) then
        return false
    end

    -- 普通技能
    local skills = XCharacterConfigs.GetCharacterSkills(charId)
    for k, skill in pairs(skills) do
        for k, subSkill in pairs(skill.subSkills) do
            local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(subSkill.SubSkillId)
            if (subSkill.Level < min_max.Max) then
                return false
            end
        end
    end

    if not self:CheckIsShowEnhanceSkill(charId) then
        return true
    end
    
    -- 独域/跃升技能
    local char = self:GetCharacter(charId)
    local skillGroupIdList = char:GetEnhanceSkillGroupIdList() or {}
    for index, skillGroupId in pairs(skillGroupIdList) do
        local skillGroup = char:GetEnhanceSkillGroupData(skillGroupId)
        if not skillGroup:GetIsMaxLevel() then
            return false
        end
    end
    return true
end

function XCharacterAgency:CheckCanUpdateSkill(charId, subSkillId, subSkillLevel)
    local char = self:GetCharacter(charId)
    if (char == nil) then
        return false
    end

    local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(subSkillId)
    if (subSkillLevel >= min_max.Max) then
        return false
    end

    local gradeConfig = XCharacterConfigs.GetSkillGradeConfig(subSkillId, subSkillLevel)
    if not gradeConfig then return false end

    if gradeConfig.ConditionId then
        for _, v in pairs(gradeConfig.ConditionId) do
            if not XConditionManager.CheckCondition(v, charId) then
                return false
            end
        end
    end

    if (not self:IsUseItemEnough(XDataCenter.ItemManager.ItemId.SkillPoint, gradeConfig.UseSkillPoint)) then
        return false
    end

    if (not self:IsUseItemEnough(XDataCenter.ItemManager.ItemId.Coin, gradeConfig.UseCoin)) then
        return false
    end

    return true
end

--处理一次多级的请求升级是否满足条件
function XCharacterAgency:CheckCanUpdateSkillMultiLevel(charId, subSkillId, subSkillLevel, subSkillLevelUp)
    local char = self:GetCharacter(charId)
    if (char == nil) then
        return false
    end

    local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(subSkillId)
    if (subSkillLevelUp >= min_max.Max) then
        return false
    end

    local useCoin = 0
    local useSkillPoint = 0
    for i = subSkillLevel, subSkillLevelUp do
        local tempGradeConfig = XCharacterConfigs.GetSkillGradeConfig(subSkillId, i)
        if not tempGradeConfig then
            return false
        end
        for _, v in pairs(tempGradeConfig.ConditionId) do
            if not XConditionManager.CheckCondition(v, charId) then
                return false
            end
        end
        useCoin = useCoin + tempGradeConfig.UseCoin
        useSkillPoint = useSkillPoint + tempGradeConfig.UseSkillPoint
    end

    if (not self:IsUseItemEnough(XDataCenter.ItemManager.ItemId.SkillPoint, useSkillPoint)) then
        return false
    end

    if (not self:IsUseItemEnough(XDataCenter.ItemManager.ItemId.Coin, useCoin)) then
        return false
    end

    return true
end

--得到人物技能共鸣等级
function XCharacterAgency:GetResonanceSkillLevel(characterId, skillId)
    if not characterId or characterId == 0 then return 0 end
    if not self:IsOwnCharacter(characterId) then return 0 end
    local npcData = {}
    npcData.Character = self:GetCharacter(characterId)
    npcData.Equips = XDataCenter.EquipManager.GetCharacterWearingEquips(characterId)
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
    return resonanceSkillLevelMap[skillId] or 0
end

--得到人物技能驻守等级
function XCharacterAgency:GetAssignSkillLevel(characterId, skillId)
    if not characterId or characterId == 0 then return 0 end
    if not self:IsOwnCharacter(characterId) then return 0 end
    return XDataCenter.FubenAssignManager.GetSkillLevel(characterId, skillId)
end

--得到人物技能总加成等级
function XCharacterAgency:GetSkillPlusLevel(characterId, skillId)
    return self:GetResonanceSkillLevel(characterId, skillId) + self:GetAssignSkillLevel(characterId, skillId)
end

--==============================--
--desc: 获取队长技能描述
--@characterId: 卡牌数据
--@return 技能Data
--==============================--
function XCharacterAgency:GetCaptainSkillInfoByCharId(characterId)
    local captianSkillId = self:GetCharacterCaptainSkill(characterId)
    local skillLevel = self:GetSkillLevel(captianSkillId)
    return self:GetCaptainSkillInfo(characterId, skillLevel)
end

function XCharacterAgency:GetCaptainSkillInfo(characterId, skillLevel)
    local captianSkillId = self:GetCharacterCaptainSkill(characterId)
    if not skillLevel then
        local config = SubSkillMinMaxLevelDicGrade[captianSkillId]
        if not config then
            XLog.ErrorTableDataNotFound("XCharacter:GetCaptainSkillInfo",
            "SubSkillMinMaxLevelDicGrade", TABLE_CHARACTER_SKILL_GRADE, "characterId", tostring(characterId))
            return
        end
        skillLevel = config.Min
    end

    return self:GetSkillGradeDesWithDetailConfig(captianSkillId, skillLevel)
end

--==============================--
--desc: 获取队长技能描述
--@characterId: 卡牌数据
--@isOnlyShowIntro: 是否只显示技能描述
--==============================--
function XCharacterAgency:GetCaptainSkillDesc(characterId, isOnlyShowIntro)
    local captianSkillInfo = self:GetCaptainSkillInfoByCharId(characterId)
    return (captianSkillInfo and captianSkillInfo.Level > 0 or isOnlyShowIntro) and captianSkillInfo.Intro or stringFormat("%s%s", captianSkillInfo.Intro, CsXTextManagerGetText("CaptainSkillLock"))
end

function XCharacterAgency:GetSkillLevel(skillId)
    local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
    local character = self:GetCharacter(characterId)
    return character and character:GetSkillLevelBySkillId(skillId) or 0
end

function XCharacterAgency:GetSpecialWeaponSkillDes(skillId)
    local skillLevel = self:GetSkillLevel(skillId)

    local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
    local addLevel = self:GetSkillPlusLevel(characterId, skillId)

    skillLevel = skillLevel + addLevel
    skillLevel = skillLevel == 0 and 1 or skillLevel

    return XCharacterConfigs.GetSkillGradeDesConfigWeaponSkillDes(skillId, skillLevel)
end

--解锁角色终阶解放技能
function XCharacterAgency:UnlockMaxLiberationSkill(characterId)
    local skillGroupId = XCharacterConfigs.GetCharMaxLiberationSkillGroupId(characterId)
    local character = self._Model.OwnCharacters[characterId]
    if character then
        local skillLevel = character:GetSkillLevel(skillGroupId)
        if not skillLevel or skillLevel <= 0 then
            self:UnlockSubSkill(nil, characterId, nil, skillGroupId)
        end
    end
end

-- 技能相关end --
-- 服务端相关begin--
function XCharacterAgency:ExchangeCharacter(templateId, cb)
    if self:IsOwnCharacter(templateId) then
        XUiManager.TipCode(XCode.CharacterManagerExchangeCharacterAlreadyOwn)
        return
    end

    local char = self:GetCharacterTemplate(templateId)
    if not char then
        XUiManager.TipCode(XCode.CharacterManagerGetCharacterTemplateNotFound)
        return
    end

    local itemId = char.ItemId
    local bornQulity = self:GetCharMinQuality(templateId)
    local characterType = self:GetCharacterType(templateId)
    local itemCount = XCharacterConfigs.GetComposeCount(characterType, bornQulity)

    if not self:IsUseItemEnough(itemId, itemCount) then
        XUiManager.TipText("CharacterManagerItemNotEnough")
        return
    end

    XNetwork.Call(METHOD_NAME.ExchangeCharacter, { TemplateId = templateId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_SYN, templateId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:OnSyncCharacter(protoData)
    if not self._Model.OwnCharacters[protoData.Id] then
        self:AddCharacter(protoData)

        local templateId = protoData.Id
        if self:GetCharacterNeedFirstShow(templateId) ~= 0 then
            XUiHelper.PushInFirstGetIdList(templateId, XArrangeConfigs.Types.Character)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_FIRST_GET, templateId)

        return
    end

    self._Model.OwnCharacters[protoData.Id]:Sync(protoData)
end

function XCharacterAgency:OnSyncCharacterEquipChange(charIdDic)
    if not next(charIdDic) then return end

    for charId, _ in pairs(charIdDic) do
        local character = self._Model.OwnCharacters[charId]
        character:RefreshAttribs()
    end

    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_CHARACTER_EQUIP_CHANGE, charIdDic)
end

function XCharacterAgency:OnSyncCharacterVitality(characterId, vitality)
    local character = self._Model.OwnCharacters[characterId]
    if not character then return end
    character.Vitality = vitality
end

function XCharacterAgency:AddExp(character, itemDict, cb)
    if type(character) == "number" then
        character = self._Model.OwnCharacters[character]
    end

    cb = cb and cb or function() end

    XMessagePack.MarkAsTable(itemDict)

    local oldLevel = character.Level
    XNetwork.Call(METHOD_NAME.LevelUp, { TemplateId = character.Id, UseItems = itemDict }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local exp = 0
        for k, v in pairs(itemDict) do
            exp = exp + XDataCenter.ItemManager.GetCharExp(k, character.Type) * v
        end

        -- 不升级用小弹窗，升级用大窗
        if character.Level <= oldLevel then
            local useStr = CS.XTextManager.GetText("CharacterExpItemsUse")
            local addStr = CS.XTextManager.GetText("ExpAdd", exp)
            XUiManager.PopupLeftTip(useStr, addStr)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_LEVEL_UP, character.Id)

        cb()
    end)
end

function XCharacterAgency:ActivateStar(character, cb)
    if type(character) == "number" then
        character = self._Model.OwnCharacters[character]
    end

    cb = cb or function() end

    if self:IsMaxQuality(character) then
        XUiManager.TipCode(XCode.CharacterManagerMaxQuality)
        return
    end

    if character.Star >= XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        XUiManager.TipCode(XCode.CharacterManagerActivateStarMaxStar)
        return
    end

    local star = character.Star + 1

    if not self:IsActivateStarUseItemEnough(character.Id, character.Quality, star) then
        XUiManager.TipText("CharacterManagerItemNotEnough")
        return
    end

    local oldAttribs = self:GetCharStarAttribs(character.Id, character.Quality, character.Star)

    XNetwork.Call(METHOD_NAME.ActivateStar, { TemplateId = character.Id }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- v1.28 升阶拆分 属性加成文本
        local attrText = ""
        for k, v in pairs(oldAttribs) do
            local value = FixToDouble(v)
            if value > 0 then
                attrText = XAttribManager.GetAttribNameByIndex(k) .. "+" .. stringFormat("%.2f", value)
                break
            end
        end
        -- v1.28 升阶拆分 技能加成文本
        local skillText = self:GetCharQualitySkillName(character.Id, character.Quality, character.Star)

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_QUALITY_STAR_PROMOTE, character.Id)
        -- XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, CS.XTextManager.GetText("CharacterActivation"), XUiHelper.GetText("CharacterQualityTip", attrText, skillText))
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("CharacterActivation"), XUiHelper.GetText("CharacterQualityTip", attrText, skillText))

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:PromoteQuality(character, cb)
    if type(character) == "number" then
        character = self._Model.OwnCharacters[character]
    end

    if self:IsMaxQuality(character) then
        XUiManager.TipCode(XCode.CharacterManagerMaxQuality)
        return
    end

    if character.Star < XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        XUiManager.TipCode(XCode.CharacterManagerPromoteQualityStarNotEnough)
        return
    end

    local characterType = self:GetCharacterType(character.Id)
    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
    XCharacterConfigs.GetPromoteUseCoin(characterType, character.Quality),
    1,
    function()
        self:PromoteQuality(character, cb)
    end,
    "CharacterManagerItemNotEnough") then
        return
    end

    XNetwork.Call(METHOD_NAME.PromoteQuality, { TemplateId = character.Id }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_QUALITY_PROMOTE, character.Id)

        if cb then
            cb()
        end
    end)
end

--------------------------------------------------------------------------
function XCharacterAgency:PromoteGrade(character, cb)
    if type(character) == "number" then
        character = self._Model.OwnCharacters[character]
    end

    if self:IsMaxCharGrade(character) then
        XUiManager.TipCode(XCode.CharacterManagerMaxGrade)
        return
    end

    if not self:IsPromoteGradeUseItemEnough(character.Id, character.Grade) then
        XUiManager.TipText("CharacterManagerCoinNotEnough")
        return
    end

    cb = cb or function() end

    local oldGrade = character.Grade
    XNetwork.Call(METHOD_NAME.PromoteGrade, { TemplateId = character.Id }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_GRADE, character.Id)

        cb(oldGrade)
    end)
end

function XCharacterAgency:UnlockSubSkill(skillId, characterId, cb, skillGroupId)
    skillGroupId = skillGroupId or XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local req = { SkillGroupId = skillGroupId }

    XNetwork.Call(METHOD_NAME.UnlockSubSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, characterId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:UpgradeSubSkillLevel(characterId, skillId, cb, countLevel)
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local count = countLevel or 1
    local req = { SkillGroupId = skillGroupId, Count = count }
    XNetwork.Call(METHOD_NAME.UpgradeSubSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SKILL_UP, characterId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:IsSkillUsing(skillId)
    local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
    local character = self:GetCharacter(characterId)
    return character and character:IsSkillUsing(skillId) or false
end

function XCharacterAgency:ReqSwitchSkill(skillId, cb)
    local req = { SkillId = skillId }

    XNetwork.Call(METHOD_NAME.SwitchSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
        local character = self:GetCharacter(characterId)
        character:SwithSkill(skillId)

        if cb then
            cb()
        end
    end)
end

-- 服务端相关end--
function XCharacterAgency:GetCharModel(templateId, quality)
    if not templateId then
        XLog.Error("self:GetCharModel函数参数错误: 参数templateId不能为空")
        return
    end

    if not quality then
        quality = self:GetCharMinQuality(templateId)
    end

    local npcId = self:GetCharNpcId(templateId, quality)

    if npcId == nil then
        return
    end

    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)

    if npcTemplate == nil then
        XLog.ErrorTableDataNotFound("self:GetCharModel", "npcTemplate", " Client/Fight/Npc/Npc.tab", "npcId", tostring(npcId))
        return
    end

    return npcTemplate.ModelId
end

function XCharacterAgency:GetCharResModel(resId)
    if not resId then
        XLog.Error("self:GetCharResModel函数参数错误: 参数resId不能为空")
        return
    end

    local npcTemplate = CS.XNpcManager.GetNpcResTemplate(resId)

    if npcTemplate == nil then
        XLog.ErrorTableDataNotFound("self:GetCharResModel", "npcTemplate", "Share/Fight/Npc/NpcRes.tab", "resId", tostring(resId))
        return
    end

    return npcTemplate.ModelId
end

--获取角色解放等级到对应的ModelId
function XCharacterAgency:GetCharLiberationLevelModelId(characterId, growUpLevel)
    if not characterId then
        XLog.Error("self:GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
        return
    end
    growUpLevel = growUpLevel or XCharacterConfigs.GrowUpLevel.New

    local modelId = XCharacterConfigs.GetCharLiberationLevelModelId(characterId, growUpLevel)
    if not modelId then
        local character = self:GetCharacter(characterId)
        return self:GetCharModel(characterId, character.Quality)
    end

    return modelId
end

--获取角色解放等级到对应的解放特效名称和模型挂点名
function XCharacterAgency:GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    if not characterId then
        XLog.Error("self:GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
        return
    end
    growUpLevel = growUpLevel or XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)

    return XCharacterConfigs.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
end

--获取已解放角色时装到对应的解放特效名称和模型挂点名（传入growUpLevel为预览，否则为自己的角色）
function XCharacterAgency:GetCharFashionLiberationEffectRootAndPath(characterId, growUpLevel, fashionId)
    if not characterId then
        XLog.Error("self:GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
        return
    end

    --自己的角色
    if not growUpLevel then
        --拥有该角色
        if not self:IsOwnCharacter(characterId) then
            return
        end

        growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)
    end

    --解放等级达到终解
    local isAchieveMaxLiberation = growUpLevel >= XCharacterConfigs.GrowUpLevel.Higher
    if not isAchieveMaxLiberation then
        return
    end

    fashionId = fashionId or XDataCenter.FashionManager.GetFashionIdByCharId(characterId)
    return XDataCenter.FashionManager.GetFashionLiberationEffectRootAndPath(fashionId)
end

function XCharacterAgency:GetCharResIcon(resId)
    if not resId then
        XLog.Error("self:GetCharResModel函数参数错误: 参数resId不能为空")
        return
    end

    local npcTemplate = CS.XNpcManager.GetNpcResTemplate(resId)

    if npcTemplate == nil then
        XLog.ErrorTableDataNotFound("self:GetCharResIcon", "npcTemplate", "Share/Fight/Npc/NpcRes.tab", "resId", tostring(resId))
        return
    end

    return npcTemplate.HeadImageName
end

--角色类型描述,根据类型字段判断职业预览类型说明
function XCharacterAgency:GetCareerIdsByCharacterType(characterType)
    local careerIds = XCharacterConfigs.GetAllCharacterCareerIds()
    local showId = 0
    local typeIds = {}
    for id, v in ipairs(careerIds) do
        showId = XCharacterConfigs.GetNpcTypeShowId(v)
        if showId == characterType or showId == 0 then
            tableInsert(typeIds, id)
        end
    end
    table.sort(typeIds,function(id1,id2)
        return XCharacterConfigs.GetNpcTypeSortId(id1) > XCharacterConfigs.GetNpcTypeSortId(id2)
    end)
    return typeIds
end

--红点相关-----------------------------
function XCharacterAgency:CanLevelUp(characterId)
    if not characterId then
        return false
    end

    if not self:IsOwnCharacter(characterId) then
        return false
    end

    local character = self:GetCharacter(characterId)
    if not character then return false end

    if self:IsOverLevel(characterId) or self:IsMaxLevel(characterId) then
        return false
    end

    local expItemsInfo = XDataCenter.ItemManager.GetCardExpItems()
    return next(expItemsInfo)
end

--检测是否可以提升品质
function XCharacterAgency:CanPromoteQuality(characterId)

    if not characterId then
        return false
    end

    if not self:IsOwnCharacter(characterId) then
        return false
    end

    local character = self:GetCharacter(characterId)

    if self:IsMaxQuality(character) then
        return false
    end

    --最大星级时可以进化到下一阶
    if character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        return self:IsCanPromoted(character.Id)
    end

    local star = character.Star + 1
    if not self:IsActivateStarUseItemEnough(character.Id, character.Quality, star) then
        return false
    end

    return true
end

--检测是否可以晋升
function XCharacterAgency:CanPromoteGrade(characterId)

    if not characterId then
        return false
    end

    if not self:IsOwnCharacter(characterId) then
        return false
    end

    local character = self:GetCharacter(characterId)

    if self:IsMaxCharGrade(character) then
        return false
    end

    if not self:CheckCanPromoteGradePrecondition(characterId, character.Id, character.Grade) then
        return false
    end

    if not self:IsPromoteGradeUseItemEnough(character.Id, character.Grade) then
        return false
    end

    return true
end

function XCharacterAgency:CheckCanPromoteGradePrecondition(characterId, templateId, grade)
    local gradeTemplate = XCharacterConfigs.GetGradeTemplates(templateId, grade)
    if not gradeTemplate then
        return
    end

    if #gradeTemplate.ConditionId > 0 then
        for i = 1, #gradeTemplate.ConditionId do
            local coditionId = gradeTemplate.ConditionId[i]
            if not XConditionManager.CheckCondition(coditionId, characterId) then
                return false
            end
        end

        return true
    else
        return true
    end
end

--是否有技能红点
function XCharacterAgency:CanPromoteSkill(characterId)
    if not characterId then
        return false
    end

    local character = self._Model.OwnCharacters[characterId]
    if not character then
        return false
    end

    local canUpdate = false
    local skills = XCharacterConfigs.GetCharacterSkills(characterId)
    for _, skill in pairs(skills) do
        for _, subSkill in ipairs(skill.subSkills) do
            if (self:CheckCanUpdateSkill(characterId, subSkill.SubSkillId, subSkill.Level)) then
                canUpdate = true
                break
            end
        end
    end

    return canUpdate
end

--判断是否能解锁
function XCharacterAgency:CanCharacterUnlock(characterId)
    if not characterId then
        return false
    end

    if self:IsOwnCharacter(characterId) then
        return false
    end

    if XRobotManager.CheckIsRobotId(characterId) then
        return false
    end

    local character = self:GetCharacterTemplate(characterId)

    local itemId = character.ItemId
    local bornQulity = self:GetCharMinQuality(characterId)
    local characterType = self:GetCharacterType(characterId)
    local itemCount = XCharacterConfigs.GetComposeCount(characterType, bornQulity)

    if not self:IsUseItemEnough(itemId, itemCount) then
        return false
    end

    return true
end

function XCharacterAgency:NotifyCharacterDataList(data)
    local characterList = data.CharacterDataList
    if not characterList then
        return
    end

    for _, character in pairs(characterList) do
        self:OnSyncCharacter(character)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SYN, characterList)
end

function XCharacterAgency:GetCharacterLevel(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        return XRobotManager.GetRobotCharacterLevel(characterId)
    end
    local ownCharacter = self:GetCharacter(characterId)
    return ownCharacter and ownCharacter.Level or 0
end

-- 角色当前阶级
function XCharacterAgency:GetCharacterGrade(characterId)
    local ownCharacter = self:GetCharacter(characterId)
    if ownCharacter then
        return ownCharacter.Grade or 1
    end
end

-- 角色当前品质
function XCharacterAgency:GetCharacterQuality(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        return XRobotManager.GetRobotCharacterQuality(characterId)
    end
    local ownCharacter = self:GetCharacter(characterId)
    if ownCharacter then
        return ownCharacter.Quality or 0
    end
    return self:GetCharMinQuality(characterId)
end

-- 角色初始品质(不是自己的角色也可以用)
function XCharacterAgency:GetCharacterInitialQuality(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end
    return self:GetCharMinQuality(characterId)
end

-- 职业类型(不是自己的角色也可以用)
function XCharacterAgency:GetCharacterCareer(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
    if not detailConfig then
        return
    end

    local careerConfig = XCharacterConfigs.GetNpcTypeTemplate(detailConfig.Career)
    if not careerConfig then
        return
    end
    return careerConfig.Type
end

-- 元素类型(物理为纯物，不读elementList)(不是自己的角色也可以用)
function XCharacterAgency:GetCharacterElement(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end
    return self._Model:GetCharacter()[characterId].Element
end

function XCharacterAgency:GetCharacterElementIcon(characterId)
    local elementId = self:GetCharacterElement(characterId)
    return XCharacterConfigs.GetCharElement(elementId).Icon2
end

function XCharacterAgency:GetCharacterHaveRobotAbilityById(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        return XRobotManager.GetRobotAbility(characterId)
    end
    local ownCharacter = self:GetCharacter(characterId)
    return ownCharacter and ownCharacter.Ability or 0
end

-- 兼容robotId
function XCharacterAgency:GetIsIsomer(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end
    return XCharacterConfigs.IsIsomer(characterId)
end

-- 根据品质id和角色id获取当前品质处于什么状态
function XCharacterAgency:GetQualityState(characterId, quality)
    local character = self:GetCharacter(characterId)

    local charQuality = character.Quality
    local isMaxQuality = self:GetCharMaxQuality(character.Id) == character.Quality
    local isMaxStars = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR

    -- 必须先判断最大品质 因为和非最大star冲突
    if charQuality == quality and isMaxQuality then
        return XEnumConst.CHARACTER.QualityState.ActiveFinish
    elseif charQuality == quality and not isMaxStars then
        return XEnumConst.CHARACTER.QualityState.Activing
    elseif charQuality == quality and not isMaxQuality and isMaxStars then
        return XEnumConst.CHARACTER.QualityState.EvoEnable
    elseif charQuality > quality then
        return XEnumConst.CHARACTER.QualityState.ActiveFinish
    elseif charQuality < quality then
        return XEnumConst.CHARACTER.QualityState.Lock
    end
end
-----------------------------------------------补强技能相关--------------------------------------------- 
function XCharacterAgency:CheckCharacterEnhanceSkillShowRed(characterId)
    local character = self._Model.OwnCharacters[characterId]
    if not character then
        return false
    end
    local groupDic = character:GetEnhanceSkillGroupDataDic()
    for _,group in pairs(groupDic) do
        local IsPassCondition,_ = self:GetEnhanceSkillIsPassCondition(group, characterId)
        if self:CheckEnhanceSkillIsCanUnlockOrLevelUp(group) and IsPassCondition then
            return true
        end
    end
    return false
end

function XCharacterAgency:GetEnhanceSkillIsPassCondition(enhanceSkillGroup, characterId)
    local passCondition = true
    local conditionDes = ""
    local conditions = enhanceSkillGroup:GetConditionList()
    if conditions then
        for _, conditionId in pairs(conditions) do
            if conditionId ~= 0 then
                passCondition, conditionDes = XConditionManager.CheckCondition(conditionId, characterId)
                if not passCondition then
                    break
                end
            end
        end
    end
    return passCondition, conditionDes
end
    
function XCharacterAgency:CheckEnhanceSkillIsCanUnlockOrLevelUp(enhanceSkillGroup)
    local useItemList = enhanceSkillGroup:GetCostItemList()
    for _,useItem in pairs(useItemList or {}) do
        local curCount = XDataCenter.ItemManager.GetCount(useItem.Id)
        if curCount < useItem.Count then
            return false
        end
    end
    return true and not enhanceSkillGroup:GetIsMaxLevel()
end
    
function XCharacterAgency:UnlockEnhanceSkillRequest(skillGroupId, characterId, cb)
    local req = { SkillGroupId = skillGroupId }

    XNetwork.Call(METHOD_NAME.UnlockEnhanceSkill, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, characterId)

            if cb then
                cb()
            end
        end)
end

function XCharacterAgency:UpgradeEnhanceSkillRequest(skillGroupId, count, characterId, cb)
    local req = { SkillGroupId = skillGroupId, Count = count }

    XNetwork.Call(METHOD_NAME.UpgradeEnhanceSkill, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, characterId)

            if cb then
                cb()
            end
        end)
end

XCharacterAgency.GetSkillAbility = GetSkillAbility

----------public end----------

----------private start----------


----------private end----------

-- GetModel
function XCharacterAgency:GetModelCharacterElement()
    return self._Model:GetCharacterElement()
end

---@return XTableCharacterElement
function XCharacterAgency:GetModelCharacterElementById(elementId)
    local configs = self._Model:GetCharacterElement()
    return configs and configs[elementId]
end

function XCharacterAgency:GetModelCharacterFilterController()
    return self._Model:GetCharacterFilterController()
end

function XCharacterAgency:GetModelCharacter()
    return self._Model:GetCharacter()
end

function XCharacterAgency:GetModelCharacterConfigById(charId)
    return self:GetModelCharacter()[charId]
end

function XCharacterAgency:GetModelLevelUpTemplate()
    return self._Model:GetLevelUpTemplate()
end

function XCharacterAgency:GetModelCharacterCareer()
    return self._Model:GetCharacterCareer()
end

function XCharacterAgency:GetModelCharacterGraph()
    return self._Model:GetCharacterGraph()
end

function XCharacterAgency:GetModelCharacterRecommend()
    return self._Model:GetCharacterRecommend()
end

function XCharacterAgency:GetModelCharacterTabId()
    return self._Model:GetCharacterTabId()
end

--- @return XTableCharacterQualityIcon
function XCharacterAgency:GetModelCharacterLiberation()
    return self._Model:GetCharacterLiberation()
end

function XCharacterAgency:GetModelGetCharacterLiberationIcon()
    return self._Model:GetCharacterLiberationIcon()
end

function XCharacterAgency:GetModelCharacterQualityIcon(quality)
    return self._Model:GetCharacterQualityIconByQuality(quality)
end

function XCharacterAgency:GetModelCharacterSkillQualityApart()
    return self._Model:GetCharacterSkillQualityApart()
end

function XCharacterAgency:GetModelCharacterSkillQualityBigEffectBall()
    return self._Model:GetCharacterSkillQualityBigEffectBall()
end

function XCharacterAgency:GetModelCharacterQuality()
    return self._Model:GetCharacterQuality()
end

function XCharacterAgency:GetModelCharacterSkillExchangeDes()
    return self._Model:GetCharacterSkillExchangeDes()
end

function XCharacterAgency:GetModelCharacterSkillGate()
    return self._Model:GetCharacterSkillGate()
end

function XCharacterAgency:GetModelGetCharacterSkillUpgradeDetail()
    return self._Model:GetCharacterSkillUpgradeDetail()
end

--region getModeComplex 以下是需要对model里的get表接口做数据处理再返回的方法

-- 该接口会把detail数据合并，是优化了原表后拆分，再在数据层面的合并
function XCharacterAgency:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    subSkillLevel = subSkillLevel or 0

    local targetId = subSkillId * 100 + subSkillLevel 
    local allConfig = self._Model:GetCharacterSkillUpgradeDes()
    local descConfig = XTool.Clone(allConfig[targetId])
    -- 开始合并detail数据
    local detailConfig = self:GetModelGetCharacterSkillUpgradeDetail()[descConfig.RefId]
    local detailData = XTool.Clone(detailConfig)
    -- 加载SpecificDes数据
    for spec_Index, v in pairs(detailData.SpecificDes) do
        local specificDesNum = descConfig.SpecificDesNum[spec_Index]
        local spec_nums = {}
        if not string.IsNilOrEmpty(specificDesNum) then
            spec_nums = string.Split(descConfig.SpecificDesNum[spec_Index])
        end
        
        local newText = nil
        if XTool.IsTableEmpty(spec_nums) then
            newText = v
        else
            newText = XUiHelper.FormatText(v, table.unpack(spec_nums))
        end
        newText = XUiHelper.ReplaceTextNewLine(newText)
        detailData.SpecificDes[spec_Index] = newText
    end
    for k, v in pairs(detailData) do
        descConfig[k] = v
    end
    -- 整合intro
    descConfig.Intro = XCharacterConfigs.GetGradeDesConfigIntro(descConfig)
    -- 合并结束

    return descConfig
end

function XCharacterAgency:GetSkillIconById(skillId)
    local config = self:GetSkillGradeDesWithDetailConfig(skillId)
    return config.Icon
end

-- 获取核心切换技能的描述
function XCharacterAgency:GetCharacterSkillExchangeDesBySkillIdAndLevel(skillId, skillLevel)
    local levelString = (skillLevel >= 10) and skillLevel or ("0"..skillLevel)
    local targetId = tonumber((skillId *100)..levelString)
    return self:GetModelCharacterSkillExchangeDes()[targetId]
end

-- 获得当前品质的各个star的进化表演阶段
---@return table
function XCharacterAgency:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local config = self:GetModelCharacterSkillQualityBigEffectBall()[quality]
    local res = {}
    for k, areaStr in pairs(config.PerformArea) do
        local areaTable = string.Split(areaStr, '|')
        -- 把area做成table 且转换为number
        for j, v in pairs(areaTable) do
            areaTable[j] = tonumber(v)
        end
        res[k] = areaTable
    end

    return res
end

-- 根据角色获得当前其处在哪个表演阶段
function XCharacterAgency:GetCharQualityPerformArea(charId, quality)
    local char = self:GetCharacter(charId)
    if not char then
        return
    end

    local allAreas = self:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local curQualityState = self:GetQualityState(charId, quality)
    if curQualityState == XEnumConst.CHARACTER.QualityState.ActiveFinish then
        return #allAreas -- 最大阶段
    end

    if curQualityState == XEnumConst.CHARACTER.QualityState.Lock then
        return XEnumConst.CHARACTER.PerformState.One
    end

    local star = char.Star
    for k, area in pairs(allAreas) do
        local areaMin = area[1]
        local areaMax = area[2]
        if star >= areaMin and star <= areaMax then
            return k
        end 
    end
end

--clientLevel获取对应等级数据 (v2.8移植完成)
function XCharacterAgency:GetCharacterSkillsByCharacter(character, clientLevel, selectSubSkill)
    local templateId = character.Id
    --
    local SkillGateConfig = self:GetModelCharacterSkillGate()
    --

    local skills = {}
    for i = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        skills[i] = {}
        skills[i].subSkills = {}
        skills[i].configDes = {}

        skills[i].config = {}
        skills[i].config.Pos = i

        if not SkillGateConfig[i] then
            XLog.ErrorTableDataNotFound("XCharacterAgency.GetCharacterSkillsByCharacter", "SkillGateConfig", "Id", tostring(i))
        else
            skills[i].Icon = self:GetModelCharacterSkillGate()[i].Icon
            skills[i].Name = SkillGateConfig[i].Name
            skills[i].EnName = SkillGateConfig[i].EnName
            skills[i].TotalLevel = 0

            --skills[i].SkillIdList = CharacterSkillDictTemplates[templateId][i]-- todo optimize
            --way1:construct a using skillId list
            --way2:reconstruct this shit code
            local skillIdList = {}
            local posDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(templateId)
            local skillGroupIds = posDic[i]

            for _, skillGroupId in pairs(skillGroupIds) do
                local skillId = character:GetGroupCurSkillId(skillGroupId)
                if skillId > 0 then
                    tableInsert(skillIdList, skillId)
                end
            end
            skills[i].SkillIdList = skillIdList--forgive me to choose way1 before deadline

            for _, skillId in pairs(skillIdList) do
                local skillCo = {}
                skillCo.SubSkillId = skillId

                local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
                local selectSkillId = selectSubSkill and selectSubSkill.SubSkillId == skillId --客户端刷新只更新选中的技能
                skillCo.Level = selectSkillId and clientLevel or character:GetSkillLevel(skillGroupId)
                skills[i].TotalLevel = skills[i].TotalLevel + skillCo.Level

                if XTool.IsNumberValid(skillId) and skillCo.Level >= 0 then
                    skillCo.config = XCharacterConfigs.GetSkillGradeConfig(skillId, skillCo.Level)
                    skillCo.configDes = self:GetSkillGradeDesWithDetailConfig(skillId, skillCo.Level)
                end

                tableInsert(skills[i].subSkills, skillCo)
            end
        end
    end

    return skills
end

-- 兼容robotId
function XCharacterAgency:GetCharacterTemplate(templateId)
    if XRobotManager.CheckIsRobotId(templateId) then
        templateId = XRobotManager.GetCharacterId(templateId)
    end
    local template = self:GetModelCharacterConfigById(templateId)
    if template == nil then
        XLog.ErrorTableDataNotFound("self:GetCharacterTemplate",
        "CharacterTemplates", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    return template
end

function XCharacterAgency:GetCharacterTemplates()
    local characterList = {}
    for _, config in pairs(self:GetModelCharacter()) do
        if self:IsCharacterCanShow(config.Id) then
            characterList[config.Id] = config
        end
    end
    return characterList
end

function XCharacterAgency:GetCharacterFullNameStr(templateId)
    local name = self:GetCharacterName(templateId)
    local tradeName = self:GetCharacterTradeName(templateId)

    return XUiHelper.GetText("CharacterFullName", name, tradeName)
end

function XCharacterAgency:GetCharacterEquipType(templateId)
    return self:GetModelCharacterConfigById(templateId).EquipType
end

function XCharacterAgency:GetCharacterName(templateId)
    return self:GetModelCharacterConfigById(templateId).Name
end

function XCharacterAgency:GetCharacterTradeName(templateId)
    return self:GetModelCharacterConfigById(templateId).TradeName
end

function XCharacterAgency:GetCharacterLogName(templateId)
    return self:GetModelCharacterConfigById(templateId).LogName
end

function XCharacterAgency:GetCharacterEnName(templateId)
    return self:GetModelCharacterConfigById(templateId).EnName
end

function XCharacterAgency:GetCharacterItemId(templateId)
    return self:GetModelCharacterConfigById(templateId).ItemId
end

-- function XCharacterAgency:GetCharacterElement(templateId)  -- 已经有2.6以前的移植了

function XCharacterAgency:IsCharacterForeShow(templateId)
    return self:GetModelCharacterConfigById(templateId).Foreshow == 0
end

function XCharacterAgency:GetCharacterLinkageType(templateId)
    return self:GetModelCharacterConfigById(templateId).LinkageType or 0
end

-- 体验包保留角色
function XCharacterAgency:IsIncludeCharacter(characterId)
    return not self._Model.IsHideFunc or self._Model.IncludeCharacterIds[characterId]
end

--是否可展示
function XCharacterAgency:IsCharacterCanShow(templateId)
    if not self:GetModelCharacterConfigById(templateId) then return false end

    -- 属于包体内容
    if not self:IsIncludeCharacter(templateId) then
        return false
    end

    -- 在展示时间内
    local timeId = self:GetModelCharacterConfigById(templateId).ShowTimeId
    return XFunctionManager.CheckInTimeByTimeId(timeId, true)
end

function XCharacterAgency:GetCharacterIntro(templateId)
    return self:GetModelCharacterConfigById(templateId).Intro
end

function XCharacterAgency:GetCharacterPriority(templateId)
    return self:GetModelCharacterConfigById(templateId).Priority
end

function XCharacterAgency:GetCharacterEmotionIcon(templateId)
    return self:GetModelCharacterConfigById(templateId).EmotionIcon
end

function XCharacterAgency:GetCharacterCaptainSkill(templateId)
    return self:GetModelCharacterConfigById(templateId).CaptainSkillId
end

function XCharacterAgency:GetCharacterStoryChapterId(templateId)
    return self:GetModelCharacterConfigById(templateId).StoryChapterId
end

function XCharacterAgency:GetCharacterCodeStr(templateId)
    return self:GetModelCharacterConfigById(templateId).Code
end

function XCharacterAgency:GetCharacterType(templateId)
    local config = self:GetCharacterTemplate(templateId)
    return config.Type
end

--首次获得弹窗
function XCharacterAgency:GetCharacterNeedFirstShow(templateId)
    return self:GetModelCharacterConfigById(templateId).NeedFirstShow
end

function XCharacterAgency:GetNextLevelExp(templateId, level)
    local levelUpTemplateId = self:GetModelCharacterConfigById(templateId).LevelUpTemplateId
    local levelUpTemplate = XCharacterConfigs.GetLevelUpTemplate(levelUpTemplateId)

    return levelUpTemplate[level].Exp
end

function XCharacterAgency:GetCharacterTemplatesCount()
    return self._Model.CharacterTemplatesCount
end

function XCharacterAgency:GetCharcterIdByFragmentItemId(itemId)
    local charId = self._Model.ItemIdToCharacterIdDic[itemId]
    if not charId then
        for id, v in pairs(self:GetModelCharacter()) do
            if v.ItemId == itemId then
                charId = id
            end
        end
    end

    return charId
end

function XCharacterAgency:GetCharacterDefaultEquipId(templateId)
    local template = self:GetCharacterTemplate(templateId)
    if template then
        return template.EquipId
    end
end

function XCharacterAgency:GetCharacterBorderTemplate(templateId) -- 替换 CharBorderTemplates 字典
    local data = self._Model.CharBorderTemplates[templateId]
    if not data then
        XLog.Error("边界属性无数据 id:", templateId)
    end
    return data
end

-- 升级相关begin --
function XCharacterAgency:GetCharMaxLevel(templateId)
    if not templateId then
        XLog.Error("XCharacterAgency:GetCharMaxLevel函数参数templateId不能为空")
        return
    end

    return self:GetCharacterBorderTemplate(templateId).MaxLevel
end

function XCharacterAgency:GetCharMinQuality(templateId)
    if not templateId then
        XLog.Error("XCharacterAgency:GetCharMinQuality函数参数templateId不能为空")
        return
    end

    if not self:GetCharacterBorderTemplate(templateId) then
        return
    end

    return self:GetCharacterBorderTemplate(templateId).MinQuality
end

function XCharacterAgency:GetCharMaxQuality(templateId)
    if not templateId then
        XLog.Error("XCharacterAgency:GetCharMaxQuality函数参数templateId为空")
        return
    end

    return self:GetCharacterBorderTemplate(templateId).MaxQuality
end

function XCharacterAgency:GetCharMaxGrade(templateId)
    return self:GetCharacterBorderTemplate(templateId).MaxGrade
end

function XCharacterAgency:GetCharMinGrade(templateId)
    return self:GetCharacterBorderTemplate(templateId).MinGrade
end

--==============================--
--desc: 获取所有角色Id和对应的NpcId（C#调试用）
--@return: characterList
--==============================--
function XCharacterAgency:GetCharacterNpcDic()
    local characterDic = {}
    for _, config in pairs(self._Model.CharQualityTemplates) do
        for _, v in pairs(config) do
            characterDic[v.CharacterId] = v.NpcId
            break
        end
    end
    return characterDic
end

--==============================--
--desc: 获取NpcId对应的角色Id（C#调试用）
--@return: characterId
--==============================--
function XCharacterAgency:GetCharacterIdByNpcId(npcId)
    for _, config in pairs(self._Model.CharQualityTemplates) do
        for _, v in pairs(config) do
            if v.NpcId == npcId then
                return v.CharacterId
            end
        end
    end

    return 0
end

function XCharacterAgency:GetQualityTemplate(templateId, quality)
    if templateId == nil or quality == nil then
        XLog.Error("XCharacterAgency:GetQualityTemplate 函数参数不能为空")
        return
    end

    if quality <= 0 then
        XLog.Error("XCharacterAgency:GetQualityTemplate 函数参数quality：" .. quality .. "不能小于等于0")
        return
    end

    local config = self._Model.CharQualityTemplates[templateId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterAgency:GetQualityTemplate",
        "self._Model.CharQualityTemplates", "Share/Character/Quality/CharacterQuality.tab", "templateId", tostring(templateId))
        return
    end

    local qualityConfig = config[quality]
    if qualityConfig == nil then
        XLog.ErrorTableDataNotFound("XCharacterAgency:GetQualityTemplate",
        "self._Model.CharQualityTemplates", "Share/Character/Quality/CharacterQuality.tab", "templateId", tostring(templateId))
        return
    end

    return qualityConfig
end

function XCharacterAgency:GetCharNpcId(templateId, quality)
    local qualityConfig = self:GetQualityTemplate(templateId, quality)
    if not qualityConfig then
        return
    end

    return qualityConfig.NpcId
end

function XCharacterAgency:GetNpcPromotedAttribByQuality(templateId, quality)
    local npcId = self:GetCharNpcId(templateId, quality)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)
    return XAttribManager.GetPromotedAttribs(npcTemplate.PromotedId)
end

function XCharacterAgency:GetCharStarAttribId(templateId, quality, star)
    if not templateId then
        XLog.Error("XCharacterAgency:GetCharStarAttribIdca函数参数templateId为空")
        return
    end

    if not quality or (quality < 1 or quality > self:GetCharMaxQuality(templateId)) then
        XLog.Error("XCharacterAgency:GetCharStarAttribId函数参数不规范，参数是quality：" .. quality)
        return
    end

    if not star or (star < 1 or star > XEnumConst.CHARACTER.MAX_QUALITY_STAR) then
        XLog.Error("XCharacterAgency:GetCharStarAttribId函数参数不规范，参数是star：" .. star)
        return
    end

    local template = self._Model.CharQualityTemplates[templateId]
    if not template[quality] then
        XLog.ErrorTableDataNotFound("XCharacterAgency:GetCharStarAttribId",
        "CharQualityTemplates", "Share/Character/Quality/CharacterQuality.tab", "templateId", tostring(templateId))
        return
    end

    local attrIds = template[quality].AttrId

    if attrIds and attrIds[star] then
        if attrIds[star] > 0 then
            return attrIds[star]
        end
    end
end

function XCharacterAgency:GetCharStarAttribs(templateId, quality, star)
    if not templateId and not quality and not star then
        XLog.Error("XCharacterAgency:GetCharStarAttribs函数参数不规范，参数是templateId, quality, star", templateId, quality, star)
        return
    end

    if star < XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        local attrId = self:GetCharStarAttribId(templateId, quality, star + 1)
        if not attrId then
            XLog.Error("XCharacterAgency:GetCharStarAttribs CharacterQuality.tab could not find :", templateId, quality, star)
            return
        end

        return XAttribManager.GetBaseAttribs(attrId)
    end
end

function XCharacterAgency:GetCharCurStarAttribsV2P6(templateId, quality, star)
    if not templateId and not quality and not star then
        XLog.Error("XCharacterAgency.GetCharCurStarAttribsV2P6 函数参数不规范，参数是templateId, quality, star")
        return
    end

    if star <= XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        local attrId = self:GetCharStarAttribId(templateId, quality, star)
        if not attrId then
            XLog.Error("XCharacterAgency:GetCharCurStarAttribsV2P6 CharacterQuality.tab could not find :", templateId, quality, star)
            return
        end

        return XAttribManager.GetBaseAttribs(attrId)
    end
end

-- 获取品质字母图标 B-A-S-SS-SSS
function XCharacterAgency:GetCharQualityIcon(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterAgency:GetCharQualityIcon函数参数不规范，参数是quality：", quality)
        return
    end

    local template = self:GetModelCharacterQualityIcon(quality)
    return template.Icon
end

-- 获取品质字母图标 B-A-S-SS-SSS
function XCharacterAgency:GetCharacterQualityIcon(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterAgency:GetCharacterQualityIcon函数参数不规范，参数是quality：", quality)
        return
    end

    local template = self:GetModelCharacterQualityIcon(quality)
    return template.IconCharacter
end

function XCharacterAgency:GetCharQualityIconGoods(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterAgency:GetCharQualityIconGoods函数参数不规范，参数是quality：", quality)
        return
    end

    local template = self:GetModelCharacterQualityIcon(quality)
    return template.IconGoods
end

function XCharacterAgency:GetCharQualityDesc(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterAgency:GetCharQualityDesc函数参数不规范，参数是quality：", quality)
        return
    end

    local template = self:GetModelCharacterQualityIcon(quality)
    return template.Desc
end

--endregion getModeComplex结束

--region XCharacterConfigs临时接口后期整改 这里的接口和XCharacterConfigs里的接口一一对应
--endregion

-- 埋点
function XCharacterAgency:BuryingUiCharacterAction(uiName, actionType, characterId)
    local dict = {}
    dict["ui_name"] = uiName -- 当前的ui
    dict["action_type"] = actionType or 0  -- 当前的交互枚举(枚举：1进化界面入口按钮，2培养界面入口按钮，3装备推荐按钮 ........  10. 拖拽装备界面)
    dict["character_id"] = characterId or 0 -- 当前操作的角色Id
    dict["role_id"] = XPlayer.Id -- 玩家id
    CS.XRecord.Record(dict, "1000001", "UiCharacterV2P6")
end

-- Notify协议相关

function XCharacterAgency:NotifyCharacterDataListV2P6(data)
    self:NotifyCharacterDataList(data)
    XDataCenter.CharacterManager.NotifyCharacterDataList(data)
end

return XCharacterAgency
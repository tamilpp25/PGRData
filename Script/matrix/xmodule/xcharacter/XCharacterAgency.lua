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
    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UP, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:AddAgencyEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
end

function XCharacterAgency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:RemoveAgencyEvent(XEventId.EVENT_CHARACTER_SKILL_UP, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:RemoveAgencyEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
    self:RemoveAgencyEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, self.RemoveTempCharactersActiveGeneralSkillIdListDic, self)
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

-- 检测进化技能提示面板是否可以显示，以第一个技能展示信息
function XCharacterAgency:CheckCharEvoSkillTipsShow(charId)
    local character = self:GetCharacter(charId)
    if not character then
        return false
    end

    local dataList = self:GetCharQualitySkillInfo(charId)
    local res = false
    local curSkillApartId = nil
    local curSkillId = nil
    local curLevel = nil
    local count = 0 -- 满足条件的技能数

    for index = #dataList, 1, -1 do
        local skillApartId = dataList[index]
        local skillApartLevel = self:GetCharSkillQualityApartLevel(skillApartId)
    
        local skillQuality = self:GetCharSkillQualityApartQuality(skillApartId)
        local skillPhase = self:GetCharSkillQualityApartPhase(skillApartId)
        local star = character.Star
        local charQuality = character.Quality
        local isActive = charQuality > skillQuality or (charQuality == skillQuality and star >= skillPhase)
        
        -- 不同的apartId可能对应同一个skillId
        if isActive then
            local skillId = self:GetCharSkillQualityApartSkillId(skillApartId)
            local skillGroupId, index = self:GetSkillGroupIdAndIndex(skillId)
            local skillLevel = character:GetSkillLevel(skillGroupId)

            if self:CheckCanUpdateSkill(charId, skillId, skillLevel, true) and skillLevel < skillApartLevel then  
                curSkillApartId = skillApartId       
                curSkillId = skillId       
                curLevel = skillLevel
                count = count + 1
                res = true
            end
        end
    end
    
    -- 是否显示，
    return res, curSkillApartId, curSkillId, curLevel, count
end

-- 检测是否有可以升级的进化技能
function XCharacterAgency:CheckCharEvoSkillTipsRed(charId)
    local character = self:GetCharacter(charId)
    if not character then
        return false
    end
    
    local dataList = self:GetCharQualitySkillInfo(charId)
    local res = false

    for k, skillApartId in ipairs(dataList) do
        local skillQuality = self:GetCharSkillQualityApartQuality(skillApartId)
        local skillPhase = self:GetCharSkillQualityApartPhase(skillApartId)
        local star = character.Star
        local charQuality = character.Quality
        local isActive = charQuality > skillQuality or (charQuality == skillQuality and star >= skillPhase)
        
        if isActive then
            local skillId = self:GetCharSkillQualityApartSkillId(skillApartId)
            local skillGroupId, index = self:GetSkillGroupIdAndIndex(skillId)
            local skillLevel = character:GetSkillLevel(skillGroupId)
            if self:CheckCanUpdateSkill(charId, skillId, skillLevel) then
                res = true
                break
            end
        end
    end
    
    return res
end

-- 是否展示独域/跃升技能
function XCharacterAgency:CheckIsShowEnhanceSkill(charId)
    local characterType = self:GetCharacterType(charId)
    local character = self:GetCharacter(charId)
    local functionId = characterType == XEnumConst.CHARACTER.CharacterType.Normal and XFunctionManager.FunctionName.CharacterEnhanceSkill or XFunctionManager.FunctionName.SpCharacterEnhanceSkill
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

-- 是否屏蔽联动角色
function XCharacterAgency:IsHideCollaborationCharacter(characterId)
    local config = XMVCA.XFavorability:GetModelGetCharacterCollaboration(characterId)
    if not config then
        return false
    end

    if config.IsNewCharacter then -- 当前版本的新角色不需要屏蔽，这个字段是策划手动每个版本控制的
        return
    end

    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local curFragment = XMVCA.XCharacter:GetCharUnlockFragment(characterId)
    local needFragment = XMVCA.XCharacter:GetComposeCount(characterType, bornQuality)
    
    return curFragment < needFragment
end

--==============================--
--desc: 获取卡牌列表(获得)
--@return 卡牌列表
--==============================--
function XCharacterAgency:GetCharacterList(characterType, isUseTempSelectTag, isAscendOrder, isUseNewSort)
    local characterList = {}

    local isNeedIsomer
    if characterType then
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            isNeedIsomer = false
        elseif characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            isNeedIsomer = true
        end
    end

    local unOwnCharList = {}
    for k, v in pairs(self:GetCharacterTemplates()) do
        if not isUseNewSort or XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(k, characterType, isUseTempSelectTag) then
            if self._Model.OwnCharacters[k] then
                if isNeedIsomer == nil then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                elseif isNeedIsomer and self:GetIsIsomer(k) then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                elseif isNeedIsomer == false and not self:GetIsIsomer(k) then
                    tableInsert(characterList, self._Model.OwnCharacters[k])
                end
            else
                -- 联动角色在碎片状态时屏蔽
                if self:IsHideCollaborationCharacter(k) then
                    goto continueFragment
                end

                if isNeedIsomer == nil then
                    tableInsert(unOwnCharList, v)
                elseif isNeedIsomer and self:GetIsIsomer(k) then
                    tableInsert(unOwnCharList, v)
                elseif isNeedIsomer == false and not self:GetIsIsomer(k) then
                    tableInsert(unOwnCharList, v)
                end

                ::continueFragment::
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
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            isNeedIsomer = false
        elseif characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            isNeedIsomer = true
        end
    end

    for characterId, v in pairs(self._Model.OwnCharacters) do
        if not isUseNewSort or XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(characterId, characterType) then
            if isNeedIsomer == nil then
                tableInsert(characterList, v)
            elseif isNeedIsomer and self:GetIsIsomer(characterId) then
                tableInsert(characterList, v)
            elseif isNeedIsomer == false and not self:GetIsIsomer(characterId) then
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
    local npcTemplate = XMVCA.XCharacter:GetNpcTemplate(character.NpcId)
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
        local plusList = self:GetSkillPlusList(character.Id, character.Type, plusId)
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
        local plusList = self:GetSkillPlusList(character.Id, character.Type, plusId)
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

    local equipDataList = XMVCA.XEquip:GetCharacterEquips(character.Id)
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

function XCharacterAgency:GetResonanceSkillAbility(skillList, useSkillMap)
    if not skillList then
        return 0
    end

    if not useSkillMap then
        return 0
    end

    local ability = 0
    for id, level in pairs(skillList) do
        if useSkillMap[id] then
            ability = ability + self:GetResonanceSkillAbilityByIdAndLv(id, level)
        end
    end
    return ability
end

function XCharacterAgency:GetPlusSkillAbility(skillList, useSkillMap)
    if not skillList then
        return 0
    end

    if not useSkillMap then
        return 0
    end

    local ability = 0
    for id, level in pairs(skillList) do
        if useSkillMap[id] then
            ability = ability + self:GetPlusSkillAbilityByIdAndLv(id, level)
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
    local skillAbility = self:GetSkillAbility(skillLevel)
    
    --补强技能战力
    local enhanceSkillAbility = 0
    if character.GetEnhanceSkillAbility then
        enhanceSkillAbility = character:GetEnhanceSkillAbility()
    end

    --装备共鸣战力
    local resonanceSkillLevel = XFightCharacterManager.GetResonanceSkillLevelMap(npcData)
    local resonanceSkillAbility = self:GetResonanceSkillAbility(resonanceSkillLevel, skillLevel)

    --边界公约驻守增加技能等级战力
    local plusSkillAbility = self:GetPlusSkillAbility(npcData.CharacterSkillPlus, skillLevel)

    --装备技能战力
    local equipAbility = XMVCA.XEquip:GetCharacterEquipsSkillAbility(character.Id) or 0

    --伙伴战力
    local partnerAbility = XDataCenter.PartnerManager.GetCarryPartnerAbilityByCarrierId(character.Id)

    --武器超限战力
    local equip = XMVCA.XEquip:GetCharacterWeapon(character.Id)
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
    local skillAbility = self:GetSkillAbility(skillLevel)
    
    --补强技能战力
    local enhanceSkillAbility = 0
    if character.GetEnhanceSkillAbility then
        enhanceSkillAbility = character:GetEnhanceSkillAbility()
    end

    local resonanceSkillLevel = XFightCharacterManager.GetResonanceSkillLevelMap(npcData)
    local resonanceSkillAbility = self:GetResonanceSkillAbility(resonanceSkillLevel, skillLevel)

    local plusSkillAbility = self:GetPlusSkillAbility(npcData.CharacterSkillPlus, skillLevel)

    local equipAbility = XMVCA.XEquip:GetEquipSkillAbilityOther(character, equipList)
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
    local id = character.Id
    local curExp = character.Exp + exp
    local curLevel = character.Level

    local maxLevel = self:GetCharMaxLevel(id)

    while curLevel do
        local nextLevelExp = self:GetNextLevelExp(id, curLevel)
        if (curExp >= nextLevelExp) then
            if curLevel == maxLevel then
                curExp = nextLevelExp
                break
            else
                curExp = curExp - nextLevelExp
                curLevel = curLevel + 1
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
    --local playerMaxLevel = XPlayer.Level
    --return mathMin(charMaxLevel, playerMaxLevel)
    
    return charMaxLevel
end

function XCharacterAgency:GetMaxLevelNeedExp(character)
    local id = character.Id
    local levelUpTemplateId = self:GetCharacterTemplate(id).LevelUpTemplateId
    local levelUpTemplate = self:GetLevelUpTemplate(levelUpTemplateId)
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
    local itemCount = self:GetStarUseCount(characterType, quality, star)

    return self:IsUseItemEnough(itemKey, itemCount)
end

function XCharacterAgency:IsCanPromoted(characterId)
    local character = self:GetCharacter(characterId)
    local hasCoin = XDataCenter.ItemManager.GetCoinsNum()
    local characterType = self:GetCharacterType(characterId)
    local useCoin = self:GetPromoteUseCoin(characterType, character.Quality)

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

    -- local isAchieveMaxLiberation = not liberateLv and XDataCenter.ExhibitionManager.IsAchieveLiberation(templateId, XEnumConst.CHARACTER.GrowUpLevel.Higher) 
    -- or (liberateLv > XEnumConst.CHARACTER.GrowUpLevel.Higher)
    local isAchieveMaxLiberation = nil
    if liberateLv then
        isAchieveMaxLiberation = liberateLv >= XEnumConst.CHARACTER.GrowUpLevel.Higher
    else
        isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsAchieveLiberation(templateId, XEnumConst.CHARACTER.GrowUpLevel.Higher)
    end

    local result = isAchieveMaxLiberation and XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId) or
    XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
    return result
end

function XCharacterAgency:GetCharLiberationAndDefaultHeadIcon(templateId, liberateLv) --获得角色圆头像(非物品使用)
    local fashionId = self:GetCharacterTemplate(templateId, true).DefaultNpcFashtionId

    if fashionId == nil then
        XLog.ErrorTableDataNotFound("self:GetCharLiberationAndDefaultHeadIcon",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
        return
    end

    local isAchieveMaxLiberation = nil
    if liberateLv then
        isAchieveMaxLiberation = liberateLv >= XEnumConst.CHARACTER.GrowUpLevel.Higher
    else
        isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsAchieveLiberation(templateId, XEnumConst.CHARACTER.GrowUpLevel.Higher)
    end

    local result = isAchieveMaxLiberation and XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId) or
        XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
    return result
end

function XCharacterAgency:GetFightCharHeadIcon(character, characterId) --获得战斗角色头像
    local headFashionId = character.CharacterHeadInfo.HeadFashionId
    local tempType = character.CharacterHeadInfo.HeadFashionType
    local headFashionType = tempType
    if tempType and tempType.value__ then -- value__是兼容c#传参回来的封装数据
        headFashionType = tempType.value__
    end
    if not XTool.IsNumberValid(headFashionId) then
        local config = self:GetCharacterTemplate(character.Id or characterId, true)
        if not config then
            XLog.Warning("GetFightCharHeadIcon error character:", character and character.Id)
            return
        end
        headFashionId = config.DefaultNpcFashtionId
        headFashionType = XFashionConfigs.HeadPortraitType.Default
    end

    if headFashionType == XFashionConfigs.HeadPortraitType.Liberation then
        return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(headFashionId)
    else
        return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(headFashionId)
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
    local data = self:GetCharSkillQualityApartDicByCharacterId(characterId)
    local result = {}
    for _, template in pairs(data) do
        for _, templateId in pairs(template) do
            for _, id in pairs(templateId) do
                local skillId = self:GetCharSkillQualityApartSkillId(id)
                local _, index = self:GetSkillGroupIdAndIndex(skillId)
                if character:IsSkillUsing(skillId) then
                    table.insert(result, id)
                elseif not skillList[index] then
                    table.insert(result, templateId[1])
                end
            end
        end
    end
    table.sort(result, function (a, b)
        if self:GetCharSkillQualityApartQuality(a) == self:GetCharSkillQualityApartQuality(b) then
            return self:GetCharSkillQualityApartPhase(a) < self:GetCharSkillQualityApartPhase(b)
        else
            return self:GetCharSkillQualityApartQuality(a) < self:GetCharSkillQualityApartQuality(b)
        end
    end)
    return result
end

--v1.28-升阶拆分-获取角色升阶技能文本
function XCharacterAgency:GetCharQualitySkillName(characterId, quality, star)
    local character = self:GetCharacter(characterId)
    local skillList = character.SkillList
    local data = self:GetCharSkillQualityApartDicByStar(characterId, quality, star)
    for _, templateId in pairs(data) do
        local skillId = self:GetCharSkillQualityApartSkillId(templateId)
        local _, index = self:GetSkillGroupIdAndIndex(skillId)
        if character:IsSkillUsing(skillId) then
            local skillName = self:GetCharSkillQualityApartName(templateId)
            local skillLevel = self:GetCharSkillQualityApartLevel(templateId)
            return XUiHelper.GetText("CharacterQualitySkillTipText", skillName, skillLevel)
        elseif not skillList[index] then
            local skillName = self:GetCharSkillQualityApartName(data[1])
            local skillLevel = self:GetCharSkillQualityApartLevel(data[1])
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

    local gradeConfig = self:GetGradeTemplates(templateId, grade)
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
                return k2 -- 球的颜色 具体看枚举 XEnumConst.CHARACTER.CharacterLiberateBallColorType
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
    local skills = self:GetCharacterSkills(charId)
    for k, skill in pairs(skills) do
        for k, subSkill in pairs(skill.subSkills) do
            local min_max = self:GetSubSkillMinMaxLevel(subSkill.SubSkillId)
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

function XCharacterAgency:CheckCanUpdateSkill(charId, subSkillId, subSkillLevel, isIgnoreItemEnough)
    local char = self:GetCharacter(charId)
    if (char == nil) then
        return false
    end

    local min_max = self:GetSubSkillMinMaxLevel(subSkillId)
    if (subSkillLevel >= min_max.Max) then
        return false
    end

    local gradeConfig = self:GetSkillGradeConfig(subSkillId, subSkillLevel)
    if not gradeConfig then return false end

    if gradeConfig.ConditionId then
        for _, v in pairs(gradeConfig.ConditionId) do
            if not XConditionManager.CheckCondition(v, charId) then
                return false
            end
        end
    end

    if isIgnoreItemEnough then
        return true
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

    local min_max = self:GetSubSkillMinMaxLevel(subSkillId)
    if (subSkillLevelUp >= min_max.Max) then
        return false
    end

    local useCoin = 0
    local useSkillPoint = 0
    for i = subSkillLevel, subSkillLevelUp do
        local tempGradeConfig = self:GetSkillGradeConfig(subSkillId, i)
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
    npcData.Equips = XMVCA.XEquip:GetCharacterEquips(characterId)
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
        local config = self._Model:GetCharacterSkillUpgradeMinMaxLevel()[captianSkillId]
        if not config then
            XLog.Error("CharacterSkillUpgrade.tab could not find characterId, skillLevel", characterId, skillLevel)
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
    local characterId = self:GetCharacterIdBySkillId(skillId)
    local character = self:GetCharacter(characterId)
    return character and character:GetSkillLevelBySkillId(skillId) or 0
end

function XCharacterAgency:GetSpecialWeaponSkillDes(skillId)
    local skillLevel = self:GetSkillLevel(skillId)

    local characterId = self:GetCharacterIdBySkillId(skillId)
    local addLevel = self:GetSkillPlusLevel(characterId, skillId)

    skillLevel = skillLevel + addLevel
    skillLevel = skillLevel == 0 and 1 or skillLevel

    return self:GetSkillGradeDesConfigWeaponSkillDes(skillId, skillLevel)
end

function XCharacterAgency:GetSkillGradeDesConfigWeaponSkillDes(subSkillId, subSkillLevel)
    local config = self:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    return config.WeaponSkillDes
end

--解锁角色终阶解放技能
function XCharacterAgency:UnlockMaxLiberationSkill(characterId)
    local skillGroupId = self:GetCharMaxLiberationSkillGroupId(characterId)
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
    local itemCount = self:GetComposeCount(characterType, bornQulity)

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
    self:GetPromoteUseCoin(characterType, character.Quality),
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
    local avtiveGenralSkillIdListBeforeUnlockSkill = self:GetCharactersActiveGeneralSkillIdList(characterId)
    skillGroupId = skillGroupId or self:GetSkillGroupIdAndIndex(skillId)
    local req = { SkillGroupId = skillGroupId }
    XNetwork.Call(METHOD_NAME.UnlockSubSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        -- 检测学习的新技能是否获得了新的机制且弹窗
        self:CheckNeedTipsGeneralByOldData(characterId, avtiveGenralSkillIdListBeforeUnlockSkill)

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SKILL_UNLOCK, characterId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:UpgradeSubSkillLevel(characterId, skillId, cb, countLevel)
    local avtiveGenralSkillIdListBeforeUnlockSkill = self:GetCharactersActiveGeneralSkillIdList(characterId)
    local skillGroupId = self:GetSkillGroupIdAndIndex(skillId)
    local count = countLevel or 1
    local req = { SkillGroupId = skillGroupId, Count = count }
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call(METHOD_NAME.UpgradeSubSkill, req, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:CheckNeedTipsGeneralByOldData(characterId, avtiveGenralSkillIdListBeforeUnlockSkill)
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SKILL_UP, characterId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:IsSkillUsing(skillId)
    local characterId = self:GetCharacterIdBySkillId(skillId)
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

        local characterId = self:GetCharacterIdBySkillId(skillId)
        local character = self:GetCharacter(characterId)
        character:SwithSkill(skillId)

        if cb then
            cb()
        end
    end)
end

function XCharacterAgency:CharacterSwitchEnhanceSkillRequest(skillId, cb)
    local req = { SkillId = skillId }

    XNetwork.Call("CharacterSwitchEnhanceSkillRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

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
    growUpLevel = growUpLevel or XEnumConst.CHARACTER.GrowUpLevel.New

    local config = self._Model:GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.ModelId
end

--获取角色解放等级到对应的解放特效名称和模型挂点名
function XCharacterAgency:GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    if not characterId then
        XLog.Error("self:GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
        return
    end
    growUpLevel = growUpLevel or XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)

    local config = self._Model:GetCharLiberationConfig(characterId, growUpLevel)
    return config.EffectRootName, config.EffectPath
end

function XCharacterAgency:GetCharLiberationLevelTitle(characterId, growUpLevel)
    local config = self._Model:GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.Title or ""
end

function XCharacterAgency:GetCharLiberationLevelDesc(characterId, growUpLevel)
    local config = self._Model:GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.Desc or ""
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
    local isAchieveMaxLiberation = growUpLevel >= XEnumConst.CHARACTER.GrowUpLevel.Higher
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
    local careerIds = self:GetAllCharacterCareerIds()
    local showId = 0
    local typeIds = {}
    for id, v in ipairs(careerIds) do
        showId = self:GetNpcTypeShowId(v)
        if showId == characterType or showId == 0 then
            tableInsert(typeIds, id)
        end
    end
    table.sort(typeIds,function(id1,id2)
        return self:GetNpcTypeSortId(id1) > self:GetNpcTypeSortId(id2)
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
    local gradeTemplate = self:GetGradeTemplates(templateId, grade)
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
    local skills = self:GetCharacterSkills(characterId)
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
    local itemCount = self:GetComposeCount(characterType, bornQulity)

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
    return 1
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

    local charConfig = self:GetCharacterTemplate(characterId)
    if not charConfig then
        return
    end

    local careerConfig = self:GetNpcTypeTemplate(charConfig.Career)
    if not careerConfig then
        return
    end
    return careerConfig.Type
end

-- 效应筛选 包括自机+机器人+未解锁 直接读表 不用动态取值
function XCharacterAgency:GetCharacterGeneralSkill(characterId)
    return self:GetCharacterGeneralSkillIds(characterId)
end

-- 元素类型(物理为纯物，不读elementList)(不是自己的角色也可以用)
function XCharacterAgency:GetCharacterElement(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end
    return self._Model:GetCharacter()[characterId].Element
end

-- v2.15新筛选器方法 元素 + 效应元素
function XCharacterAgency:GetCharacterElements(characterId)
    local elements = {}
    table.insert(elements, self:GetCharacterElement(characterId))
    if not self:IsForbidGeneralSkillElement() then
        -- 未解锁角色不用筛选其效应元素
        local isRobot = XRobotManager.CheckIsRobotId(characterId)
        if self:IsOwnCharacter(characterId) or isRobot then
            appendArray(elements, self:GetCharactersActiveGeneralElements(characterId, true))
        end
    end
    return elements
end

function XCharacterAgency:GetCharacterElementIcon(characterId)
    local elementId = self:GetCharacterElement(characterId)
    return self:GetCharElement(elementId).Icon2
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
    if not XTool.IsNumberValid(characterId) then 
        return false 
    end

    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    return self:GetCharacterType(characterId) == XEnumConst.CHARACTER.CharacterType.Isomer
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
    local avtiveGenralSkillIdListBeforeUnlockSkill = self:GetCharactersActiveGeneralSkillIdList(characterId)
    local req = { SkillGroupId = skillGroupId }
    XNetwork.Call(METHOD_NAME.UnlockEnhanceSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        
        local newGeneralSkillTipCb = function ()
            self:CheckNeedTipsGeneralByOldData(characterId, avtiveGenralSkillIdListBeforeUnlockSkill)
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK, characterId)

        if cb then
            cb(newGeneralSkillTipCb)
        end
    end)
end

function XCharacterAgency:UpgradeEnhanceSkillRequest(skillGroupId, count, characterId, cb)
    local avtiveGenralSkillIdListBeforeUnlockSkill = self:GetCharactersActiveGeneralSkillIdList(characterId)
    local req = { SkillGroupId = skillGroupId, Count = count }
    XNetwork.Call(METHOD_NAME.UpgradeEnhanceSkill, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:CheckNeedTipsGeneralByOldData(characterId, avtiveGenralSkillIdListBeforeUnlockSkill)

        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_ENHANCESKILL_UP, characterId)

        if cb then
            cb()
        end
    end)
end

-- 检测独域/跃升技能是否获得了新的机制且弹窗(只要保证在升级后调用这个检测即可)
function XCharacterAgency:CheckNeedTipsGeneralByOldData(characterId, avtiveGenralSkillIdListBeforeUnlockSkill)
    local avtiveGenralSkillIdListAfterUnlockSkill = self:GetCharactersActiveGeneralSkillIdList(characterId)
    local showGeneralSkillIds = {} -- 需要展示的机制（只有以前没拥有，现在学习了该技能后获得的新机制才需要展示）
    for _, generalSkillId in ipairs(avtiveGenralSkillIdListAfterUnlockSkill) do
        if not table.contains(avtiveGenralSkillIdListBeforeUnlockSkill, generalSkillId) then
            table.insert(showGeneralSkillIds, generalSkillId)
        end
    end
    
    if not XTool.IsTableEmpty(showGeneralSkillIds) then
        XLuaUiManager.Open("UiGeneralSkillObtainTips", showGeneralSkillIds, characterId)
    end
end

function XCharacterAgency:GetSkillAbility(skillList)
    local ability = 0
    for id, level in pairs(skillList) do
        ability = ability + self:GetSubSkillAbility(id, level)
    end
    return ability
end

----------public end----------

----------private start----------


----------private end----------

-- GetModel
---@return XTableCharacterElement[]
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

function XCharacterAgency:GetModelCharacterModelNodeEffectMapping()
    return self._Model:GetCharacterModelNodeEffectMapping()
end

function XCharacterAgency:GetModelCharacter()
    return self._Model:GetCharacter()
end

function XCharacterAgency:GetModelCharacterDetail()
    return self._Model:GetCharacterDetail()
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

function XCharacterAgency:GetModelGetCharacterLiberationIcon()
    return self._Model:GetCharacterLiberationIcon()
end

function XCharacterAgency:GetModelCharacterQualityIcon(quality)
    return self._Model:GetCharacterQualityIconByQuality(quality)
end

function XCharacterAgency:GetModelEnhanceSkill()
    return self._Model:GetEnhanceSkill()
end

function XCharacterAgency:GetModelEnhanceSkillGroup()
    return self._Model:GetEnhanceSkillGroup()
end

function XCharacterAgency:GetModelEnhanceSkillLevelEffect()
    return self._Model:GetEnhanceSkillLevelEffect()
end

function XCharacterAgency:GetModelEnhanceSkillPos()
    return self._Model:GetEnhanceSkillPos()
end

function XCharacterAgency:GetModelEnhanceSkillType()
    return self._Model:GetEnhanceSkillType()
end

function XCharacterAgency:GetModelEnhanceSkillUpgrade()
    return self._Model:GetEnhanceSkillUpgrade()
end

function XCharacterAgency:GetModelEnhanceSkillEntry()
    return self._Model:GetEnhanceSkillEntry()
end

function XCharacterAgency:GetModelEnhanceSkillTypeInfo()
    return self._Model:GetEnhanceSkillTypeInfo()
end

function XCharacterAgency:GetModelEnhanceSkillUpgradeDes()
    return self._Model:GetEnhanceSkillUpgradeDes()
end

function XCharacterAgency:GetModelCharacterSkillQualityApart()
    return self._Model:GetCharacterSkillQualityApart()
end

function XCharacterAgency:GetModelCharacterObsTriggerMagic()
    return self._Model:GetCharacterObsTriggerMagic()
end

function XCharacterAgency:GetModelCharacterSkill()
    return self._Model:GetCharacterSkill()
end

function XCharacterAgency:GetModelCharacterSkillGroup()
    return self._Model:GetCharacterSkillGroup()
end

function XCharacterAgency:GetModelCharacterSkillUpgrade()
    return self._Model:GetCharacterSkillUpgrade()
end

function XCharacterAgency:GetModelCharacterQualityFragment()
    return self._Model:GetCharacterQualityFragment()
end

function XCharacterAgency:GetModelCharacterQuality()
    return self._Model:GetCharacterQuality()
end

function XCharacterAgency:GetModelCharacterSkillType()
    return self._Model:GetCharacterSkillType()
end

function XCharacterAgency:GetModelCharacterSkillTypePlus()
    return self._Model:GetCharacterSkillTypePlus()
end

function XCharacterAgency:GetModelCharacterSkillEntry()
    return self._Model:GetCharacterSkillEntry()
end

function XCharacterAgency:GetModelCharacterSkillTeach()
    return self._Model:GetCharacterSkillTeach()
end

function XCharacterAgency:GetModelCharacterSkillGate()
    return self._Model:GetCharacterSkillGate()
end

function XCharacterAgency:GetModelCharacterSkillTypeInfo()
    return self._Model:GetCharacterSkillTypeInfo()
end

---@return XTableCharacterGeneralSkill[]
function XCharacterAgency:GetModelCharacterGeneralSkill()
    return self._Model:GetCharacterGeneralSkill()
end

function XCharacterAgency:GetModelGetCharacterSkillUpgradeDetail()
    return self._Model:GetCharacterSkillUpgradeDetail()
end

function XCharacterAgency:GetModelNpc()
    return self._Model:GetNpc()
end

--region getModeComplex 以下是需要对model里的get表接口做数据处理再返回的方法

-- 该接口会把detail数据合并，是优化了原表后拆分，再在数据层面的合并
function XCharacterAgency:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    subSkillLevel = subSkillLevel or 0

    local targetId = subSkillId * 100 + subSkillLevel 
    local allConfig = self._Model:GetCharacterSkillUpgradeDes()
    local descConfig = XTool.Clone(allConfig[targetId])
    if not descConfig then
        XLog.Error("Could not find targetId in CharacterSkillUpgradeDes.tab:", targetId, "skillId, Level:", subSkillId, subSkillLevel)
        return
    end

    local detailConfig = self:GetModelGetCharacterSkillUpgradeDetail()[descConfig.RefId]
    if not detailConfig then
        XLog.Error("Could not find Skill Id in CharacterSkillUpgradeDetail.tab , skillId, Level:", subSkillId, subSkillLevel)
        return
    end
    
    -- 开始合并detail数据
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
    descConfig.Intro = self:GetGradeDesConfigIntro(descConfig)
    -- 合并结束

    return descConfig
end

-- V1.29 返回详情描述的整合，原技能描述配置字段Intro字段配置表里已删除，该接口是为了兼容旧版Intro字段。
-- 技能描述请使用新字段BriefDes 简略 和SpecificDes 详情 两字段
-- GetCharacterSkillsByCharacter 接口的configDes信息里不包含Intro字段信息
function XCharacterAgency:GetGradeDesConfigIntro(gradeDesConfig)
    local tempData = nil
    for index, specificDes in pairs(gradeDesConfig.SpecificDes or {}) do
        local title = gradeDesConfig.Title[index]
        tempData = tempData and tempData .. "\n" or ""
        title = title and title .. "\n" or ""
        tempData = string.format("%s%s%s", tempData, title, specificDes)
    end
    return XUiHelper.ConvertLineBreakSymbol(tempData)
end

function XCharacterAgency:GetSkillIconById(skillId)
    local config = self:GetSkillGradeDesWithDetailConfig(skillId)
    return config.Icon
end

function XCharacterAgency:GetCharTeachById(charId)
    return self:GetModelCharacterSkillTeach()[charId]
end

--战中设置
function XCharacterAgency:GetCharTeachIconById(charId)
    local cfg = self:GetModelCharacterSkillTeach()[charId]
    return cfg and cfg.TeachIcon or nil
end

--战中设置
function XCharacterAgency:GetCharTeachDescriptionById(charId)
    local cfg = self:GetModelCharacterSkillTeach()[charId]
    return cfg and cfg.Description or {}
end

-- 战中设置
function XCharacterAgency:GetCharTeachHeadLineById(charId)
    local cfg = self:GetModelCharacterSkillTeach()[charId]
    return cfg and cfg.HeadLine or {}
end

function XCharacterAgency:GetCharTeachStageIdById(charId)
    local cfg = self:GetModelCharacterSkillTeach()[charId]
    return cfg and cfg.StageId
end

function XCharacterAgency:GetCharTeachWebUrlById(charId)
    local cfg = self:GetModelCharacterSkillTeach()[charId]
    return cfg and cfg.WebUrl
end

function XCharacterAgency:GetSkillTypeName(id)
    local cfg = self:GetModelCharacterSkillTypeInfo()[id]
    return cfg and cfg.Name or ""
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
            XLog.ErrorTableDataNotFound("XCharacterAgency:GetCharacterSkillsByCharacter", "SkillGateConfig", "Id", tostring(i))
        else
            skills[i].Icon = self:GetModelCharacterSkillGate()[i].Icon
            skills[i].Name = SkillGateConfig[i].Name
            skills[i].EnName = SkillGateConfig[i].EnName
            skills[i].TotalLevel = 0

            --skills[i].SkillIdList = CharacterSkillDictTemplates[templateId][i]-- todo optimize
            --way1:construct a using skillId list
            --way2:reconstruct this shit code
            local skillIdList = {}
            local posDic = self:GetChracterSkillPosToGroupIdDic(templateId)
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

                local skillGroupId = self:GetSkillGroupIdAndIndex(skillId)
                local selectSkillId = selectSubSkill and selectSubSkill.SubSkillId == skillId --客户端刷新只更新选中的技能
                skillCo.Level = selectSkillId and clientLevel or character:GetSkillLevel(skillGroupId)
                skills[i].TotalLevel = skills[i].TotalLevel + skillCo.Level

                if XTool.IsNumberValid(skillId) and skillCo.Level >= 0 then
                    skillCo.config = self:GetSkillGradeConfig(skillId, skillCo.Level)
                    skillCo.configDes = self:GetSkillGradeDesWithDetailConfig(skillId, skillCo.Level)
                end

                tableInsert(skills[i].subSkills, skillCo)
            end
        end
    end

    return skills
end
-- 兼容robotId

function XCharacterAgency:GetCharacterTemplate(templateId, notTipError)
    if XRobotManager.CheckIsRobotId(templateId) then
        templateId = XRobotManager.GetCharacterId(templateId)
    end
    local template = self:GetModelCharacterConfigById(templateId)
    if template == nil then
        if not notTipError then 
            XLog.ErrorTableDataNotFound("self:GetCharacterTemplate",
            "CharacterTemplates", "Share/Character/Character.tab", "templateId", tostring(templateId))
        end
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
    if not XTool.IsNumberValid(templateId) then
        return 0
    end
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
    local levelUpTemplate = self:GetLevelUpTemplate(levelUpTemplateId)

    return levelUpTemplate[level].Exp
end

function XCharacterAgency:GetAllCharacterCareerIds()
    local typeIds = {}
    for id, _ in pairs(self:GetModelCharacterCareer()) do
        tableInsert(typeIds, id)
    end
    return typeIds
end

function XCharacterAgency:GetNpcTypeTemplate(typeId)
    local config = self:GetModelCharacterCareer()[typeId]
    if not config then
        XLog.Error("CharacterCareer.tab not found type:", typeId)
        return
    end

    return config
end

function XCharacterAgency:GetCareerName(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.Name
end

function XCharacterAgency:GetCareerDes(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.Des
end

function XCharacterAgency:GetNpcTypeIcon(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.Icon
end

function XCharacterAgency:GetNpcTypeIconTranspose(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.IconTranspose
end

--obs专用icon
function XCharacterAgency:GetNpcTypeIconObs(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.IconObs
end

function XCharacterAgency:GetNpcTypeShowId(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.ShowId
end

function XCharacterAgency:GetNpcTypeSortId(typeId)
    local config = self:GetNpcTypeTemplate(typeId)
    return config.SortId
end


function XCharacterAgency:GetEnhanceSkillConfig(CharacterId)
    local cfg
    if CharacterId then
        cfg = self:GetModelEnhanceSkill()[CharacterId]
    else
        cfg = self:GetModelEnhanceSkill()
    end

    if CharacterId and not cfg then
        XLog.Error("CharacterId Is Not Exist In EnhanceSkill.tab", CharacterId)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillGroupConfig(Id)
    local cfg
    if Id then
        cfg = self:GetModelEnhanceSkillGroup()[Id]
    else
        cfg = self:GetModelEnhanceSkillGroup()
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In EnhanceSkillGroup.tab", Id)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillLevelEffectBySkillIdAndLevel(skillId, level)
    if not self._Model:GetEnhanceSkillLevelEffectDic()[skillId] then
        XLog.Error("Share/Character/EnhanceSkill/EnhanceSkillLevelEffect.tab 缺少 SkillId:" .. tostring(skillId))
        return
    end
    return self._Model:GetEnhanceSkillLevelEffectDic()[skillId][level]
end

function XCharacterAgency:GetEnhanceSkillPosConfig(CharacterId)
    local cfg
    if CharacterId then
        cfg = self:GetModelEnhanceSkillPos()[CharacterId]
    else
        cfg = self:GetModelEnhanceSkillPos()
    end
    if CharacterId and not cfg then
        XLog.Error("CharacterId Is Not Exist In EnhanceSkillPos.tab", CharacterId)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillTypeConfig(Id)
    local cfg
    if Id then
        cfg = self:GetModelEnhanceSkillType()[Id]
    else
        cfg = self:GetModelEnhanceSkillType()
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In EnhanceSkillType.tab", Id)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillGradeConfig(Id)
    local cfg
    if Id then
        cfg = self:GetModelEnhanceSkillUpgrade()[Id]
    else
        cfg = self:GetModelEnhanceSkillUpgrade()
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In EnhanceSkillUpgrade.tab", Id)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillGradeBySkillIdAndLevel(skillId, level)
    if not self._Model:GetEnhanceSkillGradeDic()[skillId] then
        XLog.Error("skillId Is Not Exist In EnhanceSkillUpgrade.tab", skillId)
        return
    end
    return self._Model:GetEnhanceSkillGradeDic()[skillId][level]
end

function XCharacterAgency:GetEnhanceSkillMaxLevelBySkillId(skillId)
    if not self._Model:GetEnhanceSkillMaxLevelDic()[skillId] then
        XLog.Error("skillId Is Not Exist In EnhanceSkillUpgrade.tab", skillId)
        return
    end
    return self._Model:GetEnhanceSkillMaxLevelDic()[skillId]
end

function XCharacterAgency:GetQualityUpgradeItemId(templateId, grade)
    return self._Model.CharGradeTemplates[templateId][grade].UseItemId
end

function XCharacterAgency:GetCharGradeIcon(templateId, grade)
    return self._Model.CharGradeTemplates[templateId][grade].GradeIcon
end

function XCharacterAgency:GetGradeTemplates(templateId, grade)
    return self._Model.CharGradeTemplates[templateId][grade]
end

function XCharacterAgency:GetCharGradeName(templateId, grade)
    grade = grade or self:GetCharMinGrade(templateId)
    return self._Model.CharGradeTemplates[templateId][grade].GradeName
end

function XCharacterAgency:GetCharGradeUseMoney(templateId, grade)
    local consumeItem = {}
    consumeItem.Id = self._Model.CharGradeTemplates[templateId][grade].UseItemKey
    consumeItem.Count = self._Model.CharGradeTemplates[templateId][grade].UseItemCount
    return consumeItem
end

function XCharacterAgency:GetCharGradeAttrId(templateId, grade)
    if not templateId or not grade then
        XLog.Error("XCharacterAgency:GetCharGradeAttrId函数参数错误，templateId为空或者grade为空")
        return
    end

    local template = self._Model.CharGradeTemplates[templateId]
    if not template then
        return
    end

    if template[grade] then
        if template[grade].AttrId and template[grade].AttrId > 0 then
            return template[grade].AttrId
        end
    end
end

function XCharacterAgency:GetNeedPartsGrade(templateId, grade)
    return self._Model.CharGradeTemplates[templateId][grade].PartsGrade
end

function XCharacterAgency:GetLevelUpTemplate(levelUpTemplateId)
    return self._Model.LevelUpTemplates[levelUpTemplateId]
end

function XCharacterAgency:GetCharDetailTemplate(templateId)
    return self:GetModelCharacterDetail()[templateId]
end

function XCharacterAgency:GetCharDetailCareer(templateId)
    local config = self:GetCharacterTemplate(templateId)
    return config and config.Career
end

function XCharacterAgency:GetCharFullBodyImg(templateId)
    local config = self:GetCharDetailTemplate(templateId)
    return config and config.FullBodyImg
end

function XCharacterAgency:GetCharDetailObtainElementList(templateId)
    local config = self:GetCharDetailTemplate(templateId)
    return config and config.ObtainElementList
end

---@return XTableCharacterElement
function XCharacterAgency:GetCharElement(elementId)
    local template = self:GetModelCharacterElement()[elementId]
    if template == nil then
        XLog.Error("CharacterElement.tab not found id", elementId)
        return
    end
    return template
end

function XCharacterAgency:GetCharacterElementPath()
    return "Client/Character/CharacterElement.tab"
end

function XCharacterAgency:GetCharacterTemplatesCount()
    return self._Model.CharacterTemplatesCount
end

function XCharacterAgency:GetCharDetailParnerTemplate(templateId)
    local config = self:GetModelCharacterRecommend()[templateId]
    if not config then
        XLog.Error("could not find id in CharacterRecommend.tab")
    end
    return config
end

local function voteNumSort(dataA, dataB)
    local voteA = XDataCenter.VoteManager.GetVote(dataA.Id).VoteNum
    local voteB = XDataCenter.VoteManager.GetVote(dataB.Id).VoteNum
    return voteA > voteB
end

function XCharacterAgency:GetCharacterRecommendListByIds(ids)
    local list = {}
    for _, id in ipairs(ids) do
        local config = self:GetCharDetailParnerTemplate(id)
        if config then
            tableInsert(list, config)
        end
    end

    tableSort(list, voteNumSort)

    return list
end

function XCharacterAgency:GetRecommendTabList(characterId, recommendType)
    local tabIdList = {}
    local typeMap = self._Model.CharacterTabToVoteGroupMap[characterId]
    if typeMap then
        local tabMap = typeMap[recommendType]
        if tabMap then
            for tmpRecommendType, _ in pairs(tabMap) do
                tableInsert(tabIdList, tmpRecommendType)
            end
        end
    end

    if XTool.IsTableEmpty(tabIdList) then
        return
    end

    tableSort(tabIdList)
    return tabIdList
end

function XCharacterAgency:GetRecommendTabTemplate(characterId, tabId, recommendType)
    local typeMap = self._Model.CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.Error("characterId not found in CharacterTabId.tab", characterId)
        return nil
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.Error("recommendType not found in CharacterTabId.tab",characterId, recommendType)
        return nil
    end

    local config = tabMap[tabId]
    if not config then
        return nil
    end

    return config
end

function XCharacterAgency:GetRecommendGroupId(characterId, tabId, recommendType)
    local typeMap = self._Model.CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.Error("characterId not found in CharacterTabId.tab", characterId)
        return
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.Error("recommendType not found in CharacterTabId.tab",characterId, recommendType)
        return
    end

    local config = tabMap[tabId]
    if not config then
        return
    end

    return config.GroupId
end

function XCharacterAgency:GetRecommendTabMap(characterId, recommendType)
    local typeMap = self._Model.CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.Error("characterId not found in CharacterTabId.tab", characterId)
        return
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.Error("recommendType not found in CharacterTabId.tab",characterId, recommendType)
        return
    end

    return tabMap
end

function XCharacterAgency:GetEnhanceSkillEntryConfig(Id)
    local cfg
    if Id then
        cfg = self:GetModelEnhanceSkillEntry()[Id]
    else
        cfg = self:GetModelEnhanceSkillEntry()
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In EnhanceSkillEntry.tab", Id)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillTypeInfoConfig(Type)
    local cfg
    if Type then
        cfg = self:GetModelEnhanceSkillTypeInfo()[Type]
    else
        cfg = self:GetModelEnhanceSkillTypeInfo()
    end
    if Type and not cfg then
        XLog.Error("Type Is Not Exist In EnhanceSkillTypeInfo.tab", Type)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillGradeDescConfig(Id)
    local cfg
    if Id then
        cfg = self:GetModelEnhanceSkillUpgradeDes()[Id]
    else
        cfg = self:GetModelEnhanceSkillUpgradeDes()
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In EnhanceSkillUpgradeDes.tab", Id)
    end
    return cfg
end

function XCharacterAgency:GetEnhanceSkillGradeDescBySkillIdAndLevel(skillId, level, notTipErr)
    if not self._Model:GetEnhanceSkillGradeDescDic()[skillId] then
        if not notTipErr then
            XLog.Error("skillId Is Not Exist In EnhanceSkillUpgradeDes.tab", skillId)
        end
        return
    end
    return self._Model:GetEnhanceSkillGradeDescDic()[skillId][level]
end

--技能词条 begin--
function XCharacterAgency:GetSkillEntryName(entryId)
    local config = self:GetModelCharacterSkillEntry()[entryId]
    return config.Name
end

function XCharacterAgency:GetSkillEntryDesc(entryId)
    local config = self:GetModelCharacterSkillEntry()[entryId]
    return XUiHelper.ConvertLineBreakSymbol(config.Description)
end

--获取角色技能词条描述列表
function XCharacterAgency:GetSkillGradeDesConfigEntryList(subSkillId, subSkillLevel)
    local entryList = {}
    local config = self:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    for _, entryId in ipairs(config.EntryId) do
        if XTool.IsNumberValid(entryId) then
            tableInsert(entryList, {
                Name = self:GetSkillEntryName(entryId),
                Desc = self:GetSkillEntryDesc(entryId),
            })
        end
    end
    return entryList
end
--技能词条 end--

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
        XLog.Error("XCharacterAgency:GetCharCurStarAttribsV2P6 函数参数不规范，参数是templateId, quality, star")
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

-- 获取品质字母图标 B-A-S-SS-SSS
function XCharacterAgency:GetCharacterQualityDesc(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterAgency:GetCharacterQualityIcon函数参数不规范，参数是quality：", quality)
        return ""
    end

    local template = self:GetModelCharacterQualityIcon(quality)
    return template.Desc
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

function XCharacterAgency:GetDecomposeCount(characterType, quality)
    local config = self._Model:GetCharQualityFragmentConfig(characterType, quality)
    return config.DecomposeCount
end

function XCharacterAgency:GetComposeCount(characterType, quality)
    local config = self._Model:GetCharQualityFragmentConfig(characterType, quality)
    return config.ComposeCount
end

function XCharacterAgency:GetStarUseCount(characterType, quality, star)
    if not quality or quality < 1 then
        XLog.Error("GetStarUseCount函数参数不规范，参数是quality：" .. quality)
        return
    end

    if not star or (star < 1 or star > XEnumConst.CHARACTER.MAX_QUALITY_STAR) then
        XLog.Error("GetStarUseCount函数参数不规范，参数是star：" .. star)
        return
    end

    local config = self._Model:GetCharQualityFragmentConfig(characterType, quality)
    local starUseCount = config.StarUseCount
    return starUseCount[star] or 0
end

function XCharacterAgency:GetPromoteUseCoin(characterType, quality)
    local config = self._Model:GetCharQualityFragmentConfig(characterType, quality)
    return config.PromoteUseCoin
end

function XCharacterAgency:GetPromoteItemId(characterType, quality)
    local config = self._Model:GetCharQualityFragmentConfig(characterType, quality)
    return config.PromoteItemId
end

function XCharacterAgency:GetCharSkillQualityApartQuality(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.Quality
end

function XCharacterAgency:GetCharSkillQualityApartPhase(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.Phase
end

function XCharacterAgency:GetCharSkillQualityApartLevel(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.Level
end

function XCharacterAgency:GetCharSkillQualityApartName(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.Name
end

function XCharacterAgency:GetCharSkillQualityApartIntro(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.Intro
end

-- 升阶拆分获取跳转技能Id
function XCharacterAgency:GetCharSkillQualityApartSkillId(Id)
    local config = self:GetModelCharacterSkillQualityApart()[Id]
    return config.SkillId
end

--返回 某一角色所有技能升阶数据
function XCharacterAgency:GetCharSkillQualityApartDicByCharacterId(characterId)
    if not characterId then
        XLog.Error("XCharacterAgency:GetCharSkillQualityApartTemplateByCharacterId函数参数characterId不能为空")
        return
    end
    local config = self._Model.CharSkillQualityApartDic[characterId]
    return config or {}
end

--返回 某一角色某一品质下所有技能升阶数据
function XCharacterAgency:GetCharSkillQualityApartDicByQuality(characterId, quality)
    if not quality then
        XLog.Error("GetCharSkillQualityApartDicByQuality 函数参数quality不能为空")
        return
    end
    local config = self:GetCharSkillQualityApartDicByCharacterId(characterId)
    return config[quality] or {}
end

--返回 某一角色某一品质某一星级的技能升阶数据
function XCharacterAgency:GetCharSkillQualityApartDicByStar(characterId, quality, star)
    if not star then
        XLog.Error("GetCharSkillQualityApartDicByStar 函数参数star不能为空")
        return
    end
    local config = self:GetCharSkillQualityApartDicByQuality(characterId, quality)
    return config[star] or {}
end

function XCharacterAgency:GetChracterSkillPosToGroupIdDic(characterId)
    local config = self._Model.CharacterSkillDictTemplates[characterId]
    if not config then
        XLog.Error("XCharacterAgency:GetChracterSkillPosToGroupIdDic， 字典 CharacterSkillDictTemplates 索引characterId为空", characterId)
        return
    end
    return config
end

function XCharacterAgency:GetCharacterSkills(templateId, clientLevel, selectSubSkill)
    local character = self:GetCharacter(templateId)
    return self:GetCharacterSkillsByCharacter(character, clientLevel, selectSubSkill)
end

function XCharacterAgency:GetCharMaxLiberationSkillGroupId(characterId)
    return self._Model.CharMaxLiberationSkillIdDic[characterId]
end

function XCharacterAgency:GetCharSkillGroupTemplatesById(id)
    return self:GetModelCharacterSkillGroup()[id]
end

function XCharacterAgency:GetGroupSkillIdsByGroupId(skillGroupId)
    return self._Model.CharSkillGroupDic[skillGroupId] or {}
end

function XCharacterAgency:GetSkillGroupIdAndIndex(skillId)
    local skillInfo = self._Model.CharSkillIdToGroupDic[skillId]
    if not skillInfo then return end
    return skillInfo.GroupId, skillInfo.Index
end

function XCharacterAgency:GetGroupSkillIds(skillId)
    local skillGroupId = self:GetSkillGroupIdAndIndex(skillId)
    if not skillGroupId then return {} end
    return self:GetGroupSkillIdsByGroupId(skillGroupId)
end

function XCharacterAgency:CanSkillSwith(skillId)
    return #self:GetGroupSkillIds(skillId) > 1
end

function XCharacterAgency:GetGroupDefaultSkillId(skillGroupId)
    return self:GetGroupSkillIdsByGroupId(skillGroupId)[1] or 0
end

function XCharacterAgency:GetSkillPlusList(characterId, charType, plusId)
    local skillTemplate = self:GetModelCharacterSkill()[characterId]
    if not skillTemplate then
        return
    end

    local plusTemplate = self:GetSkillTypePlusTemplate(plusId)
    if not plusTemplate then
        return
    end

    local isValidType = false
    for _, type in pairs(plusTemplate.CharacterType) do
        if type == charType then
            isValidType = true
            break
        end
    end

    if not isValidType then
        return
    end

    local plusList = {}
    for _, skillGroupId in pairs(skillTemplate.SkillGroupId) do
        local skillIds = self:GetGroupSkillIdsByGroupId(skillGroupId)
        for _, skillId in pairs(skillIds) do
            local type = self:GetSkillType(skillId)
            if type ~= 0 then
                for _, skillType in pairs(plusTemplate.SkillType) do
                    if skillType == type then
                        tableInsert(plusList, skillId)
                        break
                    end
                end
            end
        end
    end

    return plusList
end

function XCharacterAgency:GetCharacterIdBySkillId(skillId)
    local skillGroupId = self:GetSkillGroupIdAndIndex(skillId)
    return self._Model.CharSkillIdToCharacterIdDic[skillGroupId]
end

function XCharacterAgency:GetCharacterSkillPoolSkillInfo(skillId)
    if not self._Model.CharSkillPoolSkillIdDic[skillId] then
        XLog.Error("XCharacterAgency:GetCharacterSkillPoolSkillInfo CharacterSkillPoolSkillIdDic not found skillId: ", skillId)
    end

    return self._Model.CharSkillPoolSkillIdDic[skillId]
end

function XCharacterAgency:GetCharacterSkillPoolSkillInfos(poolId, characterId)
    local skillInfos = {}

    if not self._Model.CharPoolIdToSkillInfoDic[poolId] then return skillInfos end
    for _, skillInfo in pairs(self._Model.CharPoolIdToSkillInfoDic[poolId]) do
        local skillId = skillInfo.SkillId
        local skillGroupId = self:GetSkillGroupIdAndIndex(skillId)
        if characterId and skillGroupId and self._Model.CharSkillIdToCharacterIdDic[skillGroupId] == characterId then
            tableInsert(skillInfos, skillInfo)
        end
    end

    return skillInfos
end

function XCharacterAgency:GetSubSkillAbility(subSkillId, level)
    local config = self:GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.Ability or 0
end

-- 从CharacterConfig移植过来的同名函数，只能加后缀区分
function XCharacterAgency:GetResonanceSkillAbilityByIdAndLv(subSkillId, level) 
    local config = self:GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.ResonanceAbility or 0
end

-- 从CharacterConfig移植过来的同名函数，只能加后缀区分
function XCharacterAgency:GetPlusSkillAbilityByIdAndLv(subSkillId, level)
    local config = self:GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.PlusAbility or 0
end

function XCharacterAgency:GetSkillType(skillId)
    local cfg = self:GetModelCharacterSkillType()[skillId]
    return cfg and cfg.Type or 0
end

function XCharacterAgency:GetSkillTypePlusTemplate(id)
    return self:GetModelCharacterSkillTypePlus()[id]
end

function XCharacterAgency:GetSkillGradeConfig(subSkillId, subSkillLevel)
    if not subSkillLevel then
        subSkillLevel = 0
    end
    local targetId = subSkillId * 100 + subSkillLevel
    local config = self._Model:GetCharacterSkillUpgradeIdOptimize()[targetId]
    if not config then
        XLog.Error("XCharacterAgency:GetSkillGradeConfig CharacterSkillUpgradeIdOptimize not found targetId: ", targetId)
    end
    return config
end

-- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_LEVEL)
function XCharacterAgency:ClampSubSkillLeveByLevel(skillId, skillLevel)
    local fixSkillLevel = skillLevel
    if self._Model:GetCharacterSkillLevelEffectMinMaxLevel()[skillId].Max < fixSkillLevel then
        fixSkillLevel = self._Model:GetCharacterSkillLevelEffectMinMaxLevel()[skillId].Max
    elseif self._Model:GetCharacterSkillLevelEffectMinMaxLevel()[skillId].Min > fixSkillLevel then
        fixSkillLevel = self._Model:GetCharacterSkillLevelEffectMinMaxLevel()[skillId].Min
    end
    return fixSkillLevel
end

-- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_GRADE)
function XCharacterAgency:ClampSubSkillLevelByGrade(skillId, skillLevel)
    local fixSkillLevel = skillLevel
    if self._Model:GetCharacterSkillUpgradeMinMaxLevel()[skillId].Max < fixSkillLevel then
        fixSkillLevel = self._Model:GetCharacterSkillUpgradeMinMaxLevel()[skillId].Max
    elseif self._Model:GetCharacterSkillUpgradeMinMaxLevel()[skillId].Min > fixSkillLevel then
        fixSkillLevel = self._Model:GetCharacterSkillUpgradeMinMaxLevel()[skillId].Min
    end
    return fixSkillLevel
end

function XCharacterAgency:GetSubSkillMinMaxLevel(subSkillId)
    return self._Model:GetCharacterSkillUpgradeMinMaxLevel()[subSkillId]
end

function XCharacterAgency:GetSkillLevelEffectTemplate(skillId, level)
    local targetId = skillId * 100 + level 
    local config = self._Model:GetCharacterSkillLevelEffect()[targetId]
    if not config then
        XLog.Error("CharacterSkillLevelEffect.xlsm not found skillId, level", skillId, level)
        return
    end
    
    return config
end

function XCharacterAgency:GetNpcTemplate(id)
    local template = self._Model.NpcTemplates[id]
    if not template then
        XLog.Error("Could not found id in NpcTemplates ", id)
        return
    end

    return template
end

-- 获取NpcId对应的职业类型, 只能用于提示
function XCharacterAgency:GetCharacterCareerType(npcId)
    local npcTemplate = self:GetNpcTemplate(npcId)
    local realType = self._Model.Career2CareerType[npcTemplate.Type]
    return realType and realType or npcTemplate.Type
end

-- 获取角色的【机制】列表
function XCharacterAgency:GetCharacterGeneralSkillIds(characterId)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    -- 机器人兼容
    characterId = XRobotManager.GetCharacterId(characterId)
    local config = self:GetModelCharacter()[characterId]
    if not config then
        return {}
    end

    local res = config.GeneralSkillIds
    return res
end

-- 获取角色的【机制】默认解锁开关列表
function XCharacterAgency:GetCharacterIsAddGeneral(characterId)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    -- 机器人兼容
    characterId = XRobotManager.GetCharacterId(characterId)
    local config = self:GetModelCharacter()[characterId]
    if not config then
        return {}
    end

    local res = config.IsAddGeneral
    return res
end

--- 获取角色机制相关技能。不上skillGroupId，是真的skillId
---@param characterId number
---@param generalSkillId number
function XCharacterAgency:GetCharacterGeneralSkillRelatedSkillIds(characterId, generalSkillId)
    -- 普通技能
    local normalSkillIds = {}
    local skillTemplate = self:GetModelCharacterSkill()[characterId]
    for _, skillGroupId in pairs(skillTemplate.SkillGroupId) do
        local skillIds = self:GetGroupSkillIdsByGroupId(skillGroupId)
        for _, skillId in pairs(skillIds) do
            local data = self._Model:GetSkillIdGeneralSkillIdsDic()[skillId]
            if data and table.containsKey(data, "GeneralSkillId", generalSkillId) then
                table.insert(normalSkillIds, skillId)
            end
        end
    end

    -- 独域/跃升技能
    local enhanceSkillIds = {}
    local enhanceSkillTemplate = self:GetEnhanceSkillConfig(characterId)
    if not XTool.IsTableEmpty(enhanceSkillTemplate) then
        for _, enhanceSkillGroupId in pairs(enhanceSkillTemplate.SkillGroupId) do
            local groupConfig = self:GetEnhanceSkillGroupConfig(enhanceSkillGroupId)
            local skillIds = groupConfig.SkillId
            for k, enhanceSkillId in pairs(skillIds) do
                local data = self._Model:GetEnhanceSkillIdGeneralSkillIdsDic()[enhanceSkillId]
                if data and table.containsKey(data, "GeneralSkillId", generalSkillId) then
                    table.insert(enhanceSkillIds, enhanceSkillId)
                end
            end
        end
    end

    return normalSkillIds, enhanceSkillIds
end

function XCharacterAgency:RemoveTempCharactersActiveGeneralSkillIdListDic(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if not self._Model.TempWholeResetDic or not self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic then
        return
    end
    self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic[characterId] = nil
end

-- 获取当前角色激活的机制Id
function XCharacterAgency:GetCharactersActiveGeneralSkillIdList(characterId)
    if not XTool.IsNumberValid(characterId) then
        return {}
    end

    local cacheTable = self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic
    if cacheTable and cacheTable[characterId] then
        return cacheTable[characterId]
    end

    if XRobotManager.CheckIsRobotId(characterId) then
        -- 特殊npc不走角色效应
        if XTool.IsNumberValid(XRobotManager.GetRebuildNpcId(characterId)) then
            return {}
        end
        
        local res = XRobotManager.GetRobotCharactersActiveGeneralSkillIdList(characterId)

        -- 设置缓存
        if not self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic then
            self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic = {}
        end
        self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic[characterId] = res

        return res
    end

    local resGenealSkillIdDic = {}
    local char = self:GetCharacter(characterId)
    if not char then
        XLog.Warning("GetCharactersActiveGeneralSkillIdList异常 没有自机characterId", characterId)
        return resGenealSkillIdDic
    end

    -- 已学习的技能id
    local skillList = char.SkillList
    for k, v in pairs(skillList) do
        local skillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetSkillIdGeneralSkillIdsDic()[skillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end

        -- 移除老方法，使用效应机制表的映射字段来匹配skillId
        -- local generalSkillIds = self:GetNormalSkillGeneralSkillIds(skillId)
        -- for k, generalSkillId in pairs(generalSkillIds) do
        --     resGenealSkillIdDic[generalSkillId] = true
        -- end
    end

    -- 已学习的跃升/独域技能id
    local enhanceSkillList = char.EnhanceSkillList
    for k, v in pairs(enhanceSkillList) do
        local enhanceSkillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetEnhanceSkillIdGeneralSkillIdsDic()[enhanceSkillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end

        -- local generalSkillIds = self:GetEnhanceSkillGeneralSkillIds(enhanceSkillId, v.Level)
        -- for k, generalSkillId in pairs(generalSkillIds) do
        --     resGenealSkillIdDic[generalSkillId] = true
        -- end
    end

    local res = {}
    for generalSkillId, v in pairs(resGenealSkillIdDic) do
        table.insert(res, generalSkillId)
    end

    -- 设置缓存
    if not self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic then
        self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic = {}
    end
    self._Model.TempWholeResetDic.TempCharactersActiveGeneralSkillIdListDic[characterId] = res

    return res
end

---@param isActive boolean 为true时只会查找已经解锁的效应元素，为false时拿到当前角色所有效应元素
function XCharacterAgency:GetCharactersActiveGeneralElements(characterId, isActive)
    local generalSkillIds = isActive and self:GetCharactersActiveGeneralSkillIdList(characterId) or self:GetCharacterGeneralSkillIds(characterId)
    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    local templateId = isRobot and XRobotManager.GetCharacterId(characterId) or characterId
    local config = self:GetModelCharacterConfigById(templateId)
    local generalElements = {}
    if config and not XTool.IsTableEmpty(generalSkillIds) then
        for _, skillId in pairs(generalSkillIds) do
            local index = table.indexof(config.GeneralSkillIds, skillId)
            if index then
                table.insert(generalElements, config.GeneralElement[index])
            end
        end
    end
    return generalElements
end

function XCharacterAgency:GetCharacterActiveGeneralSkillIdListFromNpcFightData(npcData)
    if XTool.IsTableEmpty(npcData) then
        return {}
    end

    local resGenealSkillIdDic = {}
    local characterData = npcData.Character
    -- 已学习的技能id
    local skillList = characterData.SkillList
    for k, v in pairs(skillList) do
        local skillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetSkillIdGeneralSkillIdsDic()[skillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end
    end

    -- 已学习的跃升/独域技能id
    local enhanceSkillList = characterData.EnhanceSkillList
    for k, v in pairs(enhanceSkillList) do
        local enhanceSkillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetEnhanceSkillIdGeneralSkillIdsDic()[enhanceSkillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end
    end

    local res = {}
    for generalSkillId, v in pairs(resGenealSkillIdDic) do
        table.insert(res, generalSkillId)
    end

    return res
end

---获取角色所有元素（包括效应对应的元素）
---@param isActive boolean 为true时只会查找已经解锁的效应元素，为false时拿到当前角色所有效应元素
function XCharacterAgency:GetCharacterAllElement(characterId, isActive)
    local elementDatas = {}
    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    local templateId = isRobot and XRobotManager.GetCharacterId(characterId) or characterId
    local detailConfig = self:GetCharDetailTemplate(templateId)
    if not XTool.IsTableEmpty(detailConfig.ObtainElementList) then
        for _, v in ipairs(detailConfig.ObtainElementList) do
            table.insert(elementDatas, v)
        end
    end

    local isGetGeneralSkillElement = true
    if isActive and not self:IsOwnCharacter(characterId) and not isRobot then
        -- 未拥有该角色
        isGetGeneralSkillElement = false
    end
    if self:IsForbidGeneralSkillElement() then
        -- v2.14屏蔽功能
        isGetGeneralSkillElement = false
    end
    if isGetGeneralSkillElement then
        appendArray(elementDatas, self:GetCharactersActiveGeneralElements(characterId, isActive))
    end

    return elementDatas
end

-- v2.14屏蔽效应解锁元素显示
function XCharacterAgency:IsForbidGeneralSkillElement()
    return CS.XGame.ClientConfig:GetInt("IsShowGeneralSkillElement") == 0
end

function XCharacterAgency:IsElementActive(characterId, elementId)
    local obtainElementList = self:GetCharDetailTemplate(characterId).ObtainElementList
    if not XTool.IsTableEmpty(obtainElementList) and table.indexof(obtainElementList, elementId) then
        return true
    end
    if self:IsOwnCharacter(characterId) then
        if self:IsGeneralElementActive(characterId, elementId) then
            return true
        end
    end
    return false
end

---效应元素是否解锁
function XCharacterAgency:IsGeneralElementActive(characterId, elementId)
    if not self:IsOwnCharacter(characterId) then
        return false
    end
    local activeGeneralElements = self:GetCharactersActiveGeneralElements(characterId, true)
    return table.indexof(activeGeneralElements, elementId)
end

-- 获取其他玩家角色激活的机制Id
function XCharacterAgency:GetOtherPlayerCharactersActiveGeneralSkillIdList(char)
    if not char then
        return
    end

    local resGenealSkillIdDic = {}
    -- 已学习的技能id
    local skillList = char.SkillList
    for k, v in pairs(skillList) do
        local skillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetSkillIdGeneralSkillIdsDic()[skillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end
    end

    -- 已学习的跃升/独域技能id
    local enhanceSkillList = char.EnhanceSkillList
    for k, v in pairs(enhanceSkillList) do
        local enhanceSkillId = v.Id

        local allGeneralSkillIdBySkillId = self._Model:GetEnhanceSkillIdGeneralSkillIdsDic()[enhanceSkillId]
        if not XTool.IsTableEmpty(allGeneralSkillIdBySkillId) then
            for k, data in pairs(allGeneralSkillIdBySkillId) do
                local generalSkillId = data.GeneralSkillId
                local needLevel = data.NeedLevel
                if v.Level >= needLevel then
                    resGenealSkillIdDic[generalSkillId] = true
                end
            end
        end
    end

    local res = {}
    for generalSkillId, v in pairs(resGenealSkillIdDic) do
        table.insert(res, generalSkillId)
    end

    return res
end

-- 根据generalSkillId，返回其在detail表里配置的下标。如"1001|1002"，则1002的index为2，返回2
function XCharacterAgency:GetIndexInCharacterGeneralSkillIdsById(characterId, generalSkillId)
    characterId = XRobotManager.GetCharacterId(characterId)

    local allConfigs = self:GetCharacterGeneralSkillIds(characterId)
    local isIn, index = table.contains(allConfigs, generalSkillId)
    if not isIn then
        return
    end

    return index
end

-- 判断自机角色是否激活当前generalSkillId
function XCharacterAgency:GetGeneralSkillIsActive(characterId, generalSkillId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if not self:IsOwnCharacter(characterId) then
        return
    end

    local allActiveList = self:GetCharactersActiveGeneralSkillIdList(characterId)
    local isIn, index = table.contains(allActiveList, generalSkillId)
    if not isIn then
        return
    end

    return index
end

function XCharacterAgency:GetCharactersListByGeneralSkillId(generalSkillId)
    local key = generalSkillId.."GetCharactersListByGeneralSkillId"
    local list = self._Model.TempWholeDic[key]
    if list then
        return list
    end

    list = {}
    local charDetailConfigs = self:GetModelCharacterDetail()
    for charId, config in pairs(charDetailConfigs) do
        local generalSkillIds = self:GetCharacterGeneralSkillIds(charId)
        if table.contains(generalSkillIds, generalSkillId) then
            table.insert(list, {Id = charId})
        end
    end
    self._Model.TempWholeDic[key] = list

    return list
end

-- 根据enhanceSkillId获取角色id
function XCharacterAgency:GetCharacterIdByEnhanceSkillId(enhanceSkillId)
    local enahnceSkillGroupId = self._Model:GetEnhanceSkillIdGroupDic()[enhanceSkillId]
    if not enahnceSkillGroupId then
        XLog.Error("GetCharacterIdByEnhanceSkillId not found groupId, enhanceSkillId:", enhanceSkillId)
        return
    end

    local characterId = self._Model:GetEnhanceGroupIdCharacterIdDic()[enahnceSkillGroupId]
    return characterId
end

-- 根据enhanceSkillIdGroupId获取角色id
function XCharacterAgency:GetCharacterIdByEnhanceSkillGroupId(enahnceSkillGroupId)
    local characterId = self._Model:GetEnhanceGroupIdCharacterIdDic()[enahnceSkillGroupId]
    return characterId
end

function XCharacterAgency:GetIndexByEnhanceSkillId(enhanceSkillId)
    local characterId = self:GetCharacterIdByEnhanceSkillId(enhanceSkillId)
    local skillGroupId = self._Model:GetEnhanceSkillIdGroupDic()[enhanceSkillId]
    local skillGroupList = self:GetEnhanceSkillConfig(characterId).SkillGroupId
    local _, index = table.contains(skillGroupList, skillGroupId)

    return index
end

function XCharacterAgency:CanEnhanceSkillSwitch(enhanceSkillId)
    local enhanceSkillGroupId = self._Model:GetEnhanceSkillIdGroupDic()[enhanceSkillId]
    if not enhanceSkillGroupId then
        XLog.Error("CanEnhanceSkillSwith not found groupId, enhanceSkillId:", enhanceSkillId)
        return
    end
    return self:CanEnhanceSkillGroupSwitch(enhanceSkillGroupId)
end

function XCharacterAgency:CanEnhanceSkillGroupSwitch(enhanceSkillGroupId)
    local enhanceSkillGroupCfg = self:GetModelEnhanceSkillGroup()[enhanceSkillGroupId]
    if not enhanceSkillGroupCfg then
        XLog.Error("CanEnhanceSkillGroupSwitch not found enhanceSkillGroupCfg, enhanceSkillGroupId:", enhanceSkillGroupId)
        return
    end
    return #enhanceSkillGroupCfg.SkillId > 1
end

function XCharacterAgency:GetModelSkillIdGeneralSkillIdsDic()
    return self._Model:GetSkillIdGeneralSkillIdsDic()
end

function XCharacterAgency:GetModelEnhanceSkillIdGeneralSkillIdsDic()
    return self._Model:GetEnhanceSkillIdGeneralSkillIdsDic()
end
--endregion getModeComplex结束

-- 埋点
function XCharacterAgency:BuryingUiCharacterAction(uiName, actionType, characterId)
    local dict = self._Model.BuryingUiCharacterActionDict or {}
    dict["ui_name"] = uiName -- 当前的ui
    dict["action_type"] = actionType or 0  -- 当前的交互枚举(枚举：1进化界面入口按钮，2培养界面入口按钮，3装备推荐按钮 ........  10. 拖拽装备界面)
    dict["character_id"] = characterId or 0 -- 当前操作的角色Id
    dict["role_id"] = XPlayer.Id -- 玩家id
    CS.XRecord.Record(dict, "1000001", "UiCharacterV2P6")

    self._Model.BuryingUiCharacterActionDict = dict
end

function XCharacterAgency:RecordUiCharacterV2P6LastTag(tagName)
    self._Model.TempWholeDic.UiCharacterV2P6LastTag = tagName
end

function XCharacterAgency:GetUiCharacterV2P6LastTag() -- 目前只有涂装界面有用到
    return self._Model.TempWholeDic.UiCharacterV2P6LastTag
end

-- Notify协议相关
function XCharacterAgency:NotifyCharacterDataListV2P6(data)
    self:NotifyCharacterDataList(data)
end

return XCharacterAgency
XCharacterManagerCreator = function()

    local type = type
    local pairs = pairs

    local table = table
    local tableSort = table.sort
    local tableInsert = table.insert
    local mathMin = math.min
    local mathMax = math.max
    local stringFormat = string.format
    local CsXTextManagerGetText = CsXTextManagerGetText

    local XCharacterManager = {}

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
    -- service config end --
    local OwnCharacters = {}               -- 已拥有角色数据
    setmetatable(OwnCharacters, {
        __index = function(_, k, v)
            if XCharacterConfigs.IsCharacterCanShow(k) then
                return v
            end
        end,

        __pairs = function(t)
            return function(t, k)
                local nk, nv = next(t, k)
                if nk then
                    if XCharacterConfigs.IsCharacterCanShow(nk) then
                        return nk, nv
                    else
                        return nk, nil
                    end
                end
            end, t, nil
        end
    })

    function XCharacterManager.NewCharacter(character)
        if character == nil or character.Id == nil then
            XLog.Error("XCharacterManager.NewCharacter函数参数不能为空或者参数的Id字段不能为空")
            return
        end
        return XCharacter.New(character)
    end

    function XCharacterManager.InitCharacters(characters)
        for _, character in pairs(characters) do
            OwnCharacters[character.Id] = XCharacterManager.NewCharacter(character)
        end
    end

    function XCharacterManager.GetCharacter(id)
        return OwnCharacters[id]
    end

    function XCharacterManager.IsOwnCharacter(characterId)
        return OwnCharacters[characterId] ~= nil
    end

    local DefaultSort = function(a, b)
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end

        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end

        local priorityA = XCharacterConfigs.GetCharacterPriority(a.Id)
        local priorityB = XCharacterConfigs.GetCharacterPriority(b.Id)

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        return a.Id > b.Id
    end

    --==============================--
    --desc: 获取卡牌列表(获得)
    --@return 卡牌列表
    --==============================--
    function XCharacterManager.GetCharacterList(characterType, isUseTempSelectTag, isAscendOrder, isUseNewSort)
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
        for k, v in pairs(XCharacterConfigs.GetCharacterTemplates()) do
            if not isUseNewSort or XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(k, characterType, isUseTempSelectTag) then
                if OwnCharacters[k] then
                    if isNeedIsomer == nil then
                        tableInsert(characterList, OwnCharacters[k])
                    elseif isNeedIsomer and XCharacterConfigs.IsIsomer(k) then
                        tableInsert(characterList, OwnCharacters[k])
                    elseif isNeedIsomer == false and not XCharacterConfigs.IsIsomer(k) then
                        tableInsert(characterList, OwnCharacters[k])
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

        tableSort(characterList, function(a, b)
            local isInteamA = XDataCenter.TeamManager.CheckInTeam(a.Id)
            local isInteamB = XDataCenter.TeamManager.CheckInTeam(b.Id)

            if isInteamA ~= isInteamB then
                return isInteamA
            end

            if isUseNewSort then
                return XDataCenter.RoomCharFilterTipsManager.GetSort(a.Id, b.Id, characterType, isAscendOrder)
            end
            return DefaultSort(a, b)
        end)

        tableSort(unOwnCharList, function(a, b)
            if isUseNewSort then
                return XDataCenter.RoomCharFilterTipsManager.GetSort(a.Id, b.Id, characterType, isAscendOrder)
            end
            return DefaultSort(a, b)
        end)

        -- 合并列表
        for _, char in pairs(unOwnCharList) do
            tableInsert(characterList, char)
        end

        return characterList
    end

    function XCharacterManager.GetOwnCharacterList(characterType, isUseNewSort)
        local characterList = {}

        local isNeedIsomer
        if characterType then
            if characterType == XCharacterConfigs.CharacterType.Normal then
                isNeedIsomer = false
            elseif characterType == XCharacterConfigs.CharacterType.Isomer then
                isNeedIsomer = true
            end
        end

        for characterId, v in pairs(OwnCharacters) do
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

    function XCharacterManager.GetCharacterCountByAbility(ability)
        local count = 0
        for _, v in pairs(OwnCharacters) do
            local curAbility = XCharacterManager.GetCharacterAbility(v)
            if curAbility and curAbility >= ability then
                count = count + 1
            end
        end

        return count
    end


    --队伍预设列表排序特殊处理
    function XCharacterManager.GetSpecilOwnCharacterList()
        local characterList = {}
        for _, v in pairs(OwnCharacters) do
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

    function XCharacterManager.GetCharacterListInTeam(characterType)
        local characterList = XCharacterManager.GetOwnCharacterList(characterType)

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

    function XCharacterManager.GetCharacterIdListInTeam(characterType)
        local characterList = XCharacterManager.GetOwnCharacterList(characterType)
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

    function XCharacterManager.GetAssignCharacterListInTeam(characterType, tmpTeamIdDic)
        local characterList = XCharacterManager.GetOwnCharacterList(characterType)

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

    function XCharacterManager.GetRobotAndCharacterIdList(robotIdList, characterType)
        local characterList = XCharacterManager.GetOwnCharacterList(characterType)
        local idList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
        for _, char in pairs(characterList) do
            table.insert(idList, char.Id)
        end
        return idList
    end

    --根据robotIdList返回已拥有的角色列表
    function XCharacterManager.GetRobotCorrespondCharacterIdList(robotIdList, characterType)
        if XTool.IsNumberValid(characterType) then
            robotIdList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
        end

        local ownCharacterIdList = {}
        local charId
        for _, robotId in ipairs(robotIdList) do
            charId = XRobotManager.GetCharacterId(robotId)
            if XCharacterManager.IsOwnCharacter(charId) then
                table.insert(ownCharacterIdList, charId)
            end
        end
        return ownCharacterIdList
    end

    --根据robotIdList返回试玩和已拥有的角色列表
    function XCharacterManager.GetRobotAndCorrespondCharacterIdList(robotIdList, characterType)
        robotIdList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
        local characterList = XCharacterManager.GetRobotCorrespondCharacterIdList(robotIdList)
        local idList = XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
        for _, charId in pairs(characterList) do
            table.insert(idList, charId)
        end
        return idList
    end

    function XCharacterManager.IsUseItemEnough(itemIds, itemCounts)
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

    function XCharacterManager.AddCharacter(charData)
        local character = XCharacterManager.NewCharacter(charData)
        OwnCharacters[character.Id] = character
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

    function XCharacterManager.GetSkillPlus(character)
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

    function XCharacterManager.GetSkillPlusOther(character, assignChapterRecords)
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

    function XCharacterManager.GetFightNpcData(characterId)
        local character = characterId

        if type(characterId) == "number" then
            character = XCharacterManager.GetCharacter(characterId)
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
            CharacterSkillPlus = XCharacterManager.GetSkillPlus(character)
        }
    end

    function XCharacterManager.GetFightNpcDataOther(character, equipList, assignChapterRecords)
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
            CharacterSkillPlus = XCharacterManager.GetSkillPlusOther(character, assignChapterRecords)
        }
    end


    function XCharacterManager.GetCharacterAttribs(character)
        local npcData = XCharacterManager.GetFightNpcData(character)
        if not npcData then
            return
        end

        return XAttribManager.GetNpcAttribs(npcData)
    end

    function XCharacterManager.GetCharacterAttribsOther(character, equipList, assignChapterRecords)
        local npcData = XCharacterManager.GetFightNpcDataOther(character, equipList, assignChapterRecords)
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
    XCharacterManager.GetResonanceSkillAbility = GetResonanceSkillAbility

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

    function XCharacterManager.GetCharacterAbility(character)
        local npcData = XCharacterManager.GetFightNpcData(character)
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

        return baseAbility + skillAbility + resonanceSkillAbility + plusSkillAbility + equipAbility + partnerAbility + enhanceSkillAbility
    end

    -- partner : XPartner
    function XCharacterManager.GetCharacterAbilityOther(character, equipList, assignChapterRecords, partner)
        local npcData = XCharacterManager.GetFightNpcDataOther(character, equipList, assignChapterRecords)
        if not npcData then
            return
        end

        local attribs = XCharacterManager.GetCharacterAttribsOther(character, equipList, assignChapterRecords)
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
        return baseAbility + skillAbility + resonanceSkillAbility + plusSkillAbility + equipAbility + partnerAbility + enhanceSkillAbility
    end

    -- 根据id获得身上角色战力
    function XCharacterManager.GetCharacterAbilityById(characterId)
        local character = OwnCharacters[characterId]
        return character and XCharacterManager.GetCharacterAbility(character) or 0
    end

    function XCharacterManager.GetMaxOwnCharacterAbility()
        local maxAbility = 0

        for _, character in pairs(OwnCharacters) do
            local ability = XCharacterManager.GetCharacterAbility(character)
            maxAbility = mathMax(ability, maxAbility)
        end

        return maxAbility
    end

    function XCharacterManager.GetNpcBaseAttrib(npcId)
        local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)
        if not npcTemplate then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetNpcBaseAttrib", "npcTemplate", "Client/Fight/Npc/Npc.tab", "npcId", tostring(npcId))
            return
        end
        return XAttribManager.GetBaseAttribs(npcTemplate.AttribId)
    end

    -- 升级相关begin --
    function XCharacterManager.IsOverLevel(templateId)
        local curLevel = XPlayer.Level
        local char = XCharacterManager.GetCharacter(templateId)
        return char and char.Level >= curLevel
    end

    function XCharacterManager.IsMaxLevel(templateId)
        local char = XCharacterManager.GetCharacter(templateId)
        local maxLevel = XCharacterConfigs.GetCharMaxLevel(templateId)
        return char and char.Level >= maxLevel
    end

    function XCharacterManager.CalLevelAndExp(character, exp)
        local teamLevel = XPlayer.Level
        local id = character.Id
        local curExp = character.Exp + exp
        local curLevel = character.Level

        local maxLevel = XCharacterConfigs.GetCharMaxLevel(id)

        while curLevel do
            local nextLevelExp = XCharacterConfigs.GetNextLevelExp(id, curLevel)
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

    function XCharacterManager.GetMaxAvailableLevel(templateId)
        if not templateId then
            return
        end

        local charMaxLevel = XCharacterConfigs.GetCharMaxLevel(templateId)
        local playerMaxLevel = XPlayer.Level

        return mathMin(charMaxLevel, playerMaxLevel)
    end

    function XCharacterManager.GetMaxLevelNeedExp(character)
        local id = character.Id
        local levelUpTemplateId = XCharacterConfigs.GetCharacterTemplate(id).LevelUpTemplateId
        local levelUpTemplate = XCharacterConfigs.GetLevelUpTemplate(levelUpTemplateId)
        local maxLevel = XCharacterConfigs.GetCharMaxLevel(id)
        local totalExp = 0
        for i = character.Level, maxLevel - 1 do
            totalExp = totalExp + levelUpTemplate[i].Exp
        end

        return totalExp - character.Exp
    end
    -- 升级相关end --
    -- 品质相关begin --
    function XCharacterManager.IsMaxQuality(character)
        if not character then
            XLog.Error("XCharacterManager.IsMaxQuality函数参数character不能为空")
            return
        end

        return character.Quality >= XCharacterConfigs.GetCharMaxQuality(character.Id)
    end

    function XCharacterManager.IsMaxQualityById(characterId)
        if not characterId then
            return
        end

        local character = XCharacterManager.GetCharacter(characterId)
        return character and character.Quality >= XCharacterConfigs.GetCharMaxQuality(character.Id)
    end

    function XCharacterManager.IsCanActivateStar(character)
        if not character then
            XLog.Error("XCharacterManager.IsCanActivateStar函数参数character不能为空")
            return
        end

        if character.Quality >= XCharacterConfigs.GetCharMaxQuality(character.Id) then
            return false
        end

        if character.Star >= XCharacterConfigs.MAX_QUALITY_STAR then
            return false
        end

        return true
    end

    function XCharacterManager.IsActivateStarUseItemEnough(templateId, quality, star)
        if not templateId or not quality or not star then
            local tmpStr = "XCharacterManager.IsCharQualityStarUseItemEnough函数参数错误:, 参数templateId是"
            XLog.Error(tmpStr .. templateId .. " 参数quality是" .. quality .. " 参数star是" .. star)
            return
        end

        local template = XCharacterConfigs.GetCharacterTemplate(templateId)
        if not template then
            XLog.ErrorTableDataNotFound("XCharacterManager.IsCharQualityStarUseItemEnough",
            "template", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        if quality < 1 then
            XLog.Error("XCharacterManager.IsCharQualityStarUseItemEnough错误: 参数quality不能小于1, 参数quality是: " .. quality)
            return
        end

        if star < 1 or star > XCharacterConfigs.MAX_QUALITY_STAR then
            local tmpStr = "XCharacterManager.IsCharQualityStarUseItemEnough函数错误: 参数star不能小于1或者大于"
            XLog.Error(tmpStr .. XCharacterConfigs.MAX_QUALITY_STAR .. ", 参数star是: " .. star)
            return
        end

        local itemKey = template.ItemId
        local characterType = XCharacterConfigs.GetCharacterType(templateId)
        local itemCount = XCharacterConfigs.GetStarUseCount(characterType, quality, star)

        return XCharacterManager.IsUseItemEnough(itemKey, itemCount)
    end

    function XCharacterManager.IsCanPromoted(characterId)
        local character = XCharacterManager.GetCharacter(characterId)
        local hasCoin = XDataCenter.ItemManager.GetCoinsNum()
        local characterType = XCharacterConfigs.GetCharacterType(characterId)
        local useCoin = XCharacterConfigs.GetPromoteUseCoin(characterType, character.Quality)

        return hasCoin >= useCoin
    end

    --得到角色需要展示的 fashionId
    function XCharacterManager.GetShowFashionId(templateId, isNotSelf)
        -- 默认优先拿自己的数据
        if isNotSelf == nil then isNotSelf = false end
        -- 不属于自身数据的直接获取本地即可
        if isNotSelf then
            return XCharacterConfigs.GetCharacterTemplate(templateId).DefaultNpcFashtionId
        end
        if XCharacterManager.IsOwnCharacter(templateId) == true then
            return OwnCharacters[templateId].FashionId
        else
            return XCharacterConfigs.GetCharacterTemplate(templateId).DefaultNpcFashtionId
        end
    end

    --得到角色需要展示的时装头像信息
    function XCharacterManager.GetCharacterFashionHeadInfo(templateId, isNotSelf)
        local headFashionId, headFashionType = XCharacterManager.GetShowFashionId(templateId, isNotSelf), XFashionConfigs.HeadPortraitType.Default

        --不是自己拥有的角色，返回默认头像类型，默认涂装Id
        if isNotSelf then
            return headFashionId, headFashionType
        end

        local character = OwnCharacters[templateId]
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

    function XCharacterManager.CharacterSetHeadInfoRequest(characterId, headFashionId, headFashionType, cb)
        local req = { TemplateId = characterId, CharacterHeadInfo = {
            HeadFashionId = headFashionId or XCharacterManager.GetShowFashionId(characterId),
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

    function XCharacterManager.GetCharHalfBodyBigImage(templateId) --获得角色半身像（剧情用）
        local fashionId = XCharacterManager.GetShowFashionId(templateId)

        if fashionId == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharHalfBodyBigImage",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        return XDataCenter.FashionManager.GetFashionHalfBodyImage(fashionId)
    end

    function XCharacterManager.GetCharHalfBodyImage(templateId) --获得角色半身像（通用）
        local fashionId = XCharacterManager.GetShowFashionId(templateId)

        if fashionId == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharHalfBodyImage",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        return XDataCenter.FashionManager.GetRoleCharacterBigImage(fashionId)
    end

    function XCharacterManager.GetCharSmallHeadIcon(templateId, isNotSelf, headFashionId, headFashionType) --获得角色小头像
        local characterId = XFubenSpecialTrainConfig.GetCharacterIdByNpcId(templateId)
        if characterId then
            local stageType = XDataCenter.FubenManager.GetCurrentStageType()
            if XDataCenter.FubenSpecialTrainManager.IsStageTypeCute(stageType) then
                return XFubenSpecialTrainConfig.GetCuteModelSmallHeadIcon(characterId)
            end
            templateId = characterId
        end

        if not XTool.IsNumberValid(headFashionId)
        or not headFashionType
        then
            headFashionId, headFashionType = XCharacterManager.GetCharacterFashionHeadInfo(templateId, isNotSelf)
        end
        return XDataCenter.FashionManager.GetFashionSmallHeadIcon(headFashionId, headFashionType)
    end

    function XCharacterManager.GetCharSmallHeadIconByCharacter(character) --获得角色小头像(战斗用)
        local headInfo = character.CharacterHeadInfo or {}
        return XCharacterManager.GetCharSmallHeadIcon(character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
    end

    function XCharacterManager.GetCharBigHeadIcon(templateId, isNotSelf, headFashionId, headFashionType) --获得角色大头像
        if not XTool.IsNumberValid(headFashionId)
        or not headFashionType
        then
            headFashionId, headFashionType = XCharacterManager.GetCharacterFashionHeadInfo(templateId, isNotSelf)
        end
        return XDataCenter.FashionManager.GetFashionBigHeadIcon(headFashionId, headFashionType)
    end

    function XCharacterManager.GetCharRoundnessHeadIcon(templateId) --获得角色圆头像
        local fashionId = XCharacterManager.GetShowFashionId(templateId)

        if fashionId == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharRoundnessHeadIcon",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        return XDataCenter.FashionManager.GetFashionRoundnessHeadIcon(fashionId)
    end

    function XCharacterManager.GetCharBigRoundnessHeadIcon(templateId) --获得角色大圆头像
        local fashionId = XCharacterManager.GetShowFashionId(templateId)

        if fashionId == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharBigRoundnessHeadIcon",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        return XDataCenter.FashionManager.GetFashionBigRoundnessHeadIcon(fashionId)
    end

    function XCharacterManager.GetCharBigRoundnessNotItemHeadIcon(templateId, liberateLv) --获得角色圆头像(非物品使用)
        local fashionId = XCharacterManager.GetShowFashionId(templateId)

        if fashionId == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharBigRoundnessNotItemHeadIcon",
            "DefaultNpcFashtionId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        local isAchieveMaxLiberation = not liberateLv and XDataCenter.ExhibitionManager.IsAchieveMaxLiberation(templateId) or
        XDataCenter.ExhibitionManager.IsMaxLiberationLevel(liberateLv)
        local result = isAchieveMaxLiberation and XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId) or
        XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
        return result
    end

    function XCharacterManager.GetFightCharHeadIcon(character) --获得战斗角色头像
        local fashionId = character.FashionId
        local isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsMaxLiberationLevel(character.LiberateLv)
        if isAchieveMaxLiberation then
            return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIconLiberation(fashionId)
        else
            return XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)
        end
    end

    function XCharacterManager.GetCharUnlockFragment(templateId)
        if not templateId then
            XLog.Error("XCharacterManager.GetCharUnlockFragment函数参数错误, 参数templateId不能为空")
            return
        end

        local curCharItemId = XCharacterConfigs.GetCharacterTemplate(templateId).ItemId
        if not curCharItemId then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharUnlockFragment",
            "curCharItemId", "Share/Character/Character.tab", "templateId", tostring(templateId))
            return
        end

        local item = XDataCenter.ItemManager.GetItem(curCharItemId)

        if not item then
            return 0
        end

        return item.Count
    end

    function XCharacterManager.GetCharShowFashionSceneUrl(templateId) --获取角色需要显示时装所关联的场景路径
        if not templateId then
            XLog.Error("XCharacterManager.GetCharShowFashionSceneUrl函数参数错误, 参数templateId不能为空")
            return
        end

        local fashionId = XCharacterManager.GetShowFashionId(templateId)
        if not fashionId then
            XLog.Error("XCharacterManager.GetCharShowFashionSceneUrl函数参数错误, 获取fashionId失败")
            return
        end

        local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(fashionId)
        return sceneUrl
    end

    --v1.28-升阶拆分-获取角色所有品质升阶信息
    function XCharacterManager.GetCharQualitySkillInfo(characterId)
        local character = XCharacterManager.GetCharacter(characterId)
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
    function XCharacterManager.GetCharQualitySkillName(characterId, quality, star)
        local character = XCharacterManager.GetCharacter(characterId)
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


    -- 品质相关end --
    -- 改造相关begin --
    function XCharacterManager.IsMaxCharGrade(character)
        return character.Grade >= XCharacterConfigs.GetCharMaxGrade(character.Id)
    end

    function XCharacterManager.IsPromoteGradeUseItemEnough(templateId, grade)
        if not templateId or not grade then
            XLog.Error("XCharacterManager.IsPromoteGradeUseItemEnough参数不能为空: 参数templateId是 " .. templateId .. " 参数grade是" .. grade)
            return
        end

        local gradeConfig = XCharacterConfigs.GetGradeTemplates(templateId, grade)
        if not gradeConfig then
            XLog.ErrorTableDataNotFound("XCharacterManager.IsPromoteGradeUseItemEnough",
            "gradeConfig", "Share/Character/Grade/CharacterGrade.tab", "grade", tostring(grade))
            return
        end

        local itemKey, itemCount = gradeConfig.UseItemKey, gradeConfig.UseItemCount
        if not itemKey then
            return true
        end

        return XCharacterManager.IsUseItemEnough(itemKey, itemCount)
    end

    function XCharacterManager.CheckCanUpdateSkill(charId, subSkillId, subSkillLevel)
        local char = XCharacterManager.GetCharacter(charId)
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

        if (not XCharacterManager.IsUseItemEnough(XDataCenter.ItemManager.ItemId.SkillPoint, gradeConfig.UseSkillPoint)) then
            return false
        end

        if (not XCharacterManager.IsUseItemEnough(XDataCenter.ItemManager.ItemId.Coin, gradeConfig.UseCoin)) then
            return false
        end

        return true
    end

    --处理一次多级的请求升级是否满足条件
    function XCharacterManager.CheckCanUpdateSkillMultiLevel(charId, subSkillId, subSkillLevel, subSkillLevelUp)
        local char = XCharacterManager.GetCharacter(charId)
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

        if (not XCharacterManager.IsUseItemEnough(XDataCenter.ItemManager.ItemId.SkillPoint, useSkillPoint)) then
            return false
        end

        if (not XCharacterManager.IsUseItemEnough(XDataCenter.ItemManager.ItemId.Coin, useCoin)) then
            return false
        end

        return true
    end

    --得到人物技能共鸣等级
    function XCharacterManager.GetResonanceSkillLevel(characterId, skillId)
        if not characterId or characterId == 0 then return 0 end
        if not XCharacterManager.IsOwnCharacter(characterId) then return 0 end
        local npcData = {}
        npcData.Character = XCharacterManager.GetCharacter(characterId)
        npcData.Equips = XDataCenter.EquipManager.GetCharacterWearingEquips(characterId)
        local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
        return resonanceSkillLevelMap[skillId] or 0
    end

    --得到人物技能驻守等级
    function XCharacterManager.GetAssignSkillLevel(characterId, skillId)
        if not characterId or characterId == 0 then return 0 end
        if not XCharacterManager.IsOwnCharacter(characterId) then return 0 end
        return XDataCenter.FubenAssignManager.GetSkillLevel(characterId, skillId)
    end

    --得到人物技能总加成等级
    function XCharacterManager.GetSkillPlusLevel(characterId, skillId)
        return XCharacterManager.GetResonanceSkillLevel(characterId, skillId) + XCharacterManager.GetAssignSkillLevel(characterId, skillId)
    end

    --==============================--
    --desc: 获取队长技能描述
    --@characterId: 卡牌数据
    --@return 技能Data
    --==============================--
    function XCharacterManager.GetCaptainSkillInfo(characterId)
        local captianSkillId = XCharacterConfigs.GetCharacterCaptainSkill(characterId)
        local skillLevel = XCharacterManager.GetSkillLevel(captianSkillId)
        return XCharacterConfigs.GetCaptainSkillInfo(characterId, skillLevel)
    end

    --==============================--
    --desc: 获取队长技能描述
    --@characterId: 卡牌数据
    --@isOnlyShowIntro: 是否只显示技能描述
    --==============================--
    function XCharacterManager.GetCaptainSkillDesc(characterId, isOnlyShowIntro)
        local captianSkillInfo = XCharacterManager.GetCaptainSkillInfo(characterId)
        return (captianSkillInfo and captianSkillInfo.Level > 0 or isOnlyShowIntro) and captianSkillInfo.Intro or stringFormat("%s%s", captianSkillInfo.Intro, CsXTextManagerGetText("CaptainSkillLock"))
    end

    function XCharacterManager.GetSkillLevel(skillId)
        local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
        local character = XCharacterManager.GetCharacter(characterId)
        return character and character:GetSkillLevelBySkillId(skillId) or 0
    end

    function XCharacterManager.GetSpecialWeaponSkillDes(skillId)
        local skillLevel = XCharacterManager.GetSkillLevel(skillId)

        local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
        local addLevel = XCharacterManager.GetSkillPlusLevel(characterId, skillId)

        skillLevel = skillLevel + addLevel
        skillLevel = skillLevel == 0 and 1 or skillLevel

        return XCharacterConfigs.GetSkillGradeDesConfigWeaponSkillDes(skillId, skillLevel)
    end

    --解锁角色终阶解放技能
    function XCharacterManager.UnlockMaxLiberationSkill(characterId)
        local skillGroupId = XCharacterConfigs.GetCharMaxLiberationSkillGroupId(characterId)
        local character = OwnCharacters[characterId]
        if character then
            local skillLevel = character:GetSkillLevel(skillGroupId)
            if not skillLevel or skillLevel <= 0 then
                XCharacterManager.UnlockSubSkill(nil, characterId, nil, skillGroupId)
            end
        end
    end

    -- 技能相关end --
    -- 服务端相关begin--
    function XCharacterManager.ExchangeCharacter(templateId, cb)
        if XCharacterManager.IsOwnCharacter(templateId) then
            XUiManager.TipCode(XCode.CharacterManagerExchangeCharacterAlreadyOwn)
            return
        end

        local char = XCharacterConfigs.GetCharacterTemplate(templateId)
        if not char then
            XUiManager.TipCode(XCode.CharacterManagerGetCharacterTemplateNotFound)
            return
        end

        local itemId = char.ItemId
        local bornQulity = XCharacterConfigs.GetCharMinQuality(templateId)
        local characterType = XCharacterConfigs.GetCharacterType(templateId)
        local itemCount = XCharacterConfigs.GetComposeCount(characterType, bornQulity)

        if not XCharacterManager.IsUseItemEnough(itemId, itemCount) then
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

    function XCharacterManager.OnSyncCharacter(protoData)
        if not OwnCharacters[protoData.Id] then
            XCharacterManager.AddCharacter(protoData)

            local templateId = protoData.Id
            if XCharacterConfigs.GetCharacterNeedFirstShow(templateId) ~= 0 then
                XUiHelper.PushInFirstGetIdList(templateId, XArrangeConfigs.Types.Character)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_FIRST_GET, templateId)

            return
        end

        OwnCharacters[protoData.Id]:Sync(protoData)
    end

    function XCharacterManager.OnSyncCharacterVitality(characterId, vitality)
        local character = OwnCharacters[characterId]
        if not character then return end
        character.Vitality = vitality
    end

    function XCharacterManager.AddExp(character, itemDict, cb)
        if type(character) == "number" then
            character = OwnCharacters[character]
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

            local useStr = CS.XTextManager.GetText("CharacterExpItemsUse")
            local addStr = CS.XTextManager.GetText("ExpAdd", exp)
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, useStr, addStr, oldLevel)
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_LEVEL_UP, character.Id)

            cb()
        end)
    end

    function XCharacterManager.ActivateStar(character, cb)
        if type(character) == "number" then
            character = OwnCharacters[character]
        end

        cb = cb or function() end

        if XCharacterManager.IsMaxQuality(character) then
            XUiManager.TipCode(XCode.CharacterManagerMaxQuality)
            return
        end

        if character.Star >= XCharacterConfigs.MAX_QUALITY_STAR then
            XUiManager.TipCode(XCode.CharacterManagerActivateStarMaxStar)
            return
        end

        local star = character.Star + 1

        if not XCharacterManager.IsActivateStarUseItemEnough(character.Id, character.Quality, star) then
            XUiManager.TipText("CharacterManagerItemNotEnough")
            return
        end

        local oldAttribs = XCharacterConfigs.GetCharStarAttribs(character.Id, character.Quality, character.Star)

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
            local skillText = XCharacterManager.GetCharQualitySkillName(character.Id, character.Quality, character.Star)

            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_QUALITY_STAR_PROMOTE, character.Id)
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, CS.XTextManager.GetText("CharacterActivation"), XUiHelper.GetText("CharacterQualityTip", attrText, skillText))

            if cb then
                cb()
            end
        end)
    end

    function XCharacterManager.PromoteQuality(character, cb)
        if type(character) == "number" then
            character = OwnCharacters[character]
        end

        if XCharacterManager.IsMaxQuality(character) then
            XUiManager.TipCode(XCode.CharacterManagerMaxQuality)
            return
        end

        if character.Star < XCharacterConfigs.MAX_QUALITY_STAR then
            XUiManager.TipCode(XCode.CharacterManagerPromoteQualityStarNotEnough)
            return
        end

        local characterType = XCharacterConfigs.GetCharacterType(character.Id)
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
        XCharacterConfigs.GetPromoteUseCoin(characterType, character.Quality),
        1,
        function()
            XCharacterManager.PromoteQuality(character, cb)
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
    function XCharacterManager.PromoteGrade(character, cb)
        if type(character) == "number" then
            character = OwnCharacters[character]
        end

        if XCharacterManager.IsMaxCharGrade(character) then
            XUiManager.TipCode(XCode.CharacterManagerMaxGrade)
            return
        end

        if not XCharacterManager.IsPromoteGradeUseItemEnough(character.Id, character.Grade) then
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

    function XCharacterManager.UnlockSubSkill(skillId, characterId, cb, skillGroupId)
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

    function XCharacterManager.UpgradeSubSkillLevel(characterId, skillId, cb, countLevel)
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

    function XCharacterManager.IsSkillUsing(skillId)
        local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
        local character = XCharacterManager.GetCharacter(characterId)
        return character and character:IsSkillUsing(skillId) or false
    end

    function XCharacterManager.ReqSwitchSkill(skillId, cb)
        local req = { SkillId = skillId }

        XNetwork.Call(METHOD_NAME.SwitchSkill, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local characterId = XCharacterConfigs.GetCharacterIdBySkillId(skillId)
            local character = XCharacterManager.GetCharacter(characterId)
            character:SwithSkill(skillId)

            if cb then
                cb()
            end
        end)
    end

    -- 服务端相关end--
    function XCharacterManager.GetCharModel(templateId, quality)
        if not templateId then
            XLog.Error("XCharacterManager.GetCharModel函数参数错误: 参数templateId不能为空")
            return
        end

        if not quality then
            quality = XCharacterConfigs.GetCharMinQuality(templateId)
        end

        local npcId = XCharacterConfigs.GetCharNpcId(templateId, quality)

        if npcId == nil then
            return
        end

        local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)

        if npcTemplate == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharModel", "npcTemplate", " Client/Fight/Npc/Npc.tab", "npcId", tostring(npcId))
            return
        end

        return npcTemplate.ModelId
    end

    function XCharacterManager.GetCharResModel(resId)
        if not resId then
            XLog.Error("XCharacterManager.GetCharResModel函数参数错误: 参数resId不能为空")
            return
        end

        local npcTemplate = CS.XNpcManager.GetNpcResTemplate(resId)

        if npcTemplate == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharResModel", "npcTemplate", "Share/Fight/Npc/NpcRes.tab", "resId", tostring(resId))
            return
        end

        return npcTemplate.ModelId
    end

    --获取角色解放等级到对应的ModelId
    function XCharacterManager.GetCharLiberationLevelModelId(characterId, growUpLevel)
        if not characterId then
            XLog.Error("XCharacterManager.GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
            return
        end
        growUpLevel = growUpLevel or XCharacterConfigs.GrowUpLevel.New

        local modelId = XCharacterConfigs.GetCharLiberationLevelModelId(characterId, growUpLevel)
        if not modelId then
            local character = XDataCenter.CharacterManager.GetCharacter(characterId)
            return XCharacterManager.GetCharModel(characterId, character.Quality)
        end

        return modelId
    end

    --获取角色解放等级到对应的解放特效名称和模型挂点名
    function XCharacterManager.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
        if not characterId then
            XLog.Error("XCharacterManager.GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
            return
        end
        growUpLevel = growUpLevel or XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)

        return XCharacterConfigs.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    end

    --获取已解放角色时装到对应的解放特效名称和模型挂点名（传入growUpLevel为预览，否则为自己的角色）
    function XCharacterManager.GetCharFashionLiberationEffectRootAndPath(characterId, growUpLevel, fashionId)
        if not characterId then
            XLog.Error("XCharacterManager.GetCharLiberationLevelModel函数参数错误: 参数characterId不能为空")
            return
        end

        --自己的角色
        if not growUpLevel then
            --拥有该角色
            if not XCharacterManager.IsOwnCharacter(characterId) then
                return
            end

            growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId)
        end

        --解放等级达到满级
        local isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsMaxLiberationLevel(growUpLevel)
        if not isAchieveMaxLiberation then
            return
        end

        fashionId = fashionId or XDataCenter.FashionManager.GetFashionIdByCharId(characterId)
        return XDataCenter.FashionManager.GetFashionLiberationEffectRootAndPath(fashionId)
    end

    function XCharacterManager.GetCharResIcon(resId)
        if not resId then
            XLog.Error("XCharacterManager.GetCharResModel函数参数错误: 参数resId不能为空")
            return
        end

        local npcTemplate = CS.XNpcManager.GetNpcResTemplate(resId)

        if npcTemplate == nil then
            XLog.ErrorTableDataNotFound("XCharacterManager.GetCharResIcon", "npcTemplate", "Share/Fight/Npc/NpcRes.tab", "resId", tostring(resId))
            return
        end

        return npcTemplate.HeadImageName
    end

    --角色类型描述,根据类型字段判断职业预览类型说明
    function XCharacterManager.GetCareerIdsByCharacterType(characterType)
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
    function XCharacterManager.CanLevelUp(characterId)
        if not characterId then
            return false
        end

        if not XCharacterManager.IsOwnCharacter(characterId) then
            return false
        end

        local character = XCharacterManager.GetCharacter(characterId)
        if not character then return false end

        if XCharacterManager.IsOverLevel(characterId) or XCharacterManager.IsMaxLevel(characterId) then
            return false
        end

        local expItemsInfo = XDataCenter.ItemManager.GetCardExpItems()
        return next(expItemsInfo)
    end

    --检测是否可以提升品质
    function XCharacterManager.CanPromoteQuality(characterId)

        if not characterId then
            return false
        end

        if not XCharacterManager.IsOwnCharacter(characterId) then
            return false
        end

        local character = XCharacterManager.GetCharacter(characterId)

        if XCharacterManager.IsMaxQuality(character) then
            return false
        end

        --最大星级时可以进化到下一阶
        if character.Star == XCharacterConfigs.MAX_QUALITY_STAR then
            return XCharacterManager.IsCanPromoted(character.Id)
        end

        local star = character.Star + 1
        if not XCharacterManager.IsActivateStarUseItemEnough(character.Id, character.Quality, star) then
            return false
        end

        return true
    end

    --检测是否可以晋升
    function XCharacterManager.CanPromoteGrade(characterId)

        if not characterId then
            return false
        end

        if not XCharacterManager.IsOwnCharacter(characterId) then
            return false
        end

        local character = XCharacterManager.GetCharacter(characterId)

        if XCharacterManager.IsMaxCharGrade(character) then
            return false
        end

        if not XCharacterManager.CheckCanPromoteGradePrecondition(characterId, character.Id, character.Grade) then
            return false
        end

        if not XCharacterManager.IsPromoteGradeUseItemEnough(character.Id, character.Grade) then
            return false
        end

        return true
    end

    function XCharacterManager.CheckCanPromoteGradePrecondition(characterId, templateId, grade)
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
    function XCharacterManager.CanPromoteSkill(characterId)
        if not characterId then
            return false
        end

        local character = OwnCharacters[characterId]
        if not character then
            return false
        end

        local canUpdate = false
        local skills = XCharacterConfigs.GetCharacterSkills(characterId)
        for _, skill in pairs(skills) do
            for _, subSkill in ipairs(skill.subSkills) do
                if (XCharacterManager.CheckCanUpdateSkill(characterId, subSkill.SubSkillId, subSkill.Level)) then
                    canUpdate = true
                    break
                end
            end
        end

        return canUpdate
    end

    --判断是否能解锁
    function XCharacterManager:CanCharacterUnlock(characterId)
        if not characterId then
            return false
        end

        if XCharacterManager.IsOwnCharacter(characterId) then
            return false
        end

        local character = XCharacterConfigs.GetCharacterTemplate(characterId)

        local itemId = character.ItemId
        local bornQulity = XCharacterConfigs.GetCharMinQuality(characterId)
        local characterType = XCharacterConfigs.GetCharacterType(characterId)
        local itemCount = XCharacterConfigs.GetComposeCount(characterType, bornQulity)

        if not XCharacterManager.IsUseItemEnough(itemId, itemCount) then
            return false
        end

        return true
    end

    function XCharacterManager.NotifyCharacterDataList(data)
        local characterList = data.CharacterDataList
        if not characterList then
            return
        end

        for _, character in pairs(characterList) do
            XCharacterManager.OnSyncCharacter(character)
        end
    end

    function XCharacterManager.GetCharacterLevel(characterId)
        if XRobotManager.CheckIsRobotId(characterId) then
            return XRobotManager.GetRobotCharacterLevel(characterId)
        end
        local ownCharacter = XCharacterManager.GetCharacter(characterId)
        return ownCharacter and ownCharacter.Level or 0
    end

    function XCharacterManager.GetCharacterQuality(characterId)
        if XRobotManager.CheckIsRobotId(characterId) then
            return XRobotManager.GetRobotCharacterQuality(characterId)
        end
        local ownCharacter = XCharacterManager.GetCharacter(characterId)
        if ownCharacter then
            return ownCharacter.Quality or 0
        end
        return XCharacterConfigs.GetCharacterQualityCfg(characterId)
    end

    function XCharacterManager.GetCharacterHaveRobotAbilityById(characterId)
        if XRobotManager.CheckIsRobotId(characterId) then
            return XRobotManager.GetRobotAbility(characterId)
        end
        local ownCharacter = XCharacterManager.GetCharacter(characterId)
        return ownCharacter and ownCharacter.Ability or 0
    end
-----------------------------------------------补强技能相关--------------------------------------------- 
    function XCharacterManager.CheckCharacterShowRed(characterId)
        local character = OwnCharacters[characterId]
        if not character then
            return false
        end
        local groupDic = character:GetEnhanceSkillGroupDataDic()
        for _,group in pairs(groupDic) do
            local IsPassCondition,_ = XCharacterManager.GetEnhanceSkillIsPassCondition(group, characterId)
            if XCharacterManager.CheckEnhanceSkillIsCanUnlockOrLevelUp(group) and IsPassCondition then
                return true
            end
        end
        return false
    end
    
    function XCharacterManager.GetEnhanceSkillIsPassCondition(enhanceSkillGroup, characterId)
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
      
    function XCharacterManager.CheckEnhanceSkillIsCanUnlockOrLevelUp(enhanceSkillGroup)
        local useItemList = enhanceSkillGroup:GetCostItemList()
        for _,useItem in pairs(useItemList or {}) do
            local curCount = XDataCenter.ItemManager.GetCount(useItem.Id)
            if curCount < useItem.Count then
                return false
            end
        end
        return true and not enhanceSkillGroup:GetIsMaxLevel()
    end
      
    function XCharacterManager.UnlockEnhanceSkillRequest(skillGroupId, characterId, cb)
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
    
    function XCharacterManager.UpgradeEnhanceSkillRequest(skillGroupId, count, characterId, cb)
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

    XCharacterManager.GetSkillAbility = GetSkillAbility
    return XCharacterManager
end

XRpc.NotifyCharacterDataList = function(data)
    XDataCenter.CharacterManager.NotifyCharacterDataList(data)
end
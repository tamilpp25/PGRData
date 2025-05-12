local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
local XAwarenessChapter = require("XEntity/XAwareness/XAwarenessChapter")
local XAwarenessTeam = require("XEntity/XAwareness/XAwarenessTeam")

--- 意识公约管理器
XFubenAwarenessManagerCreator = function()
    local XFubenAwarenessManager = {}

    XFubenAwarenessManager.CAPTIAN_MEMBER_INDEX = 1 -- 队长位置
    XFubenAwarenessManager.FIRSTFIGHT_MEMBER_INDEX = 1 -- 首发位置
 
    local MEMBER_MAX_COUNT = 3 -- 队伍最大成员数

    -- 自定义数据
    local ChapterIdList = nil
    local ChapterDataDict = nil -- 章节

    local TeamDataDict = nil -- 队伍
    local LoadingData = nil
    local ChapterFirstPassTrigger = nil
    local GeneralSkillIdDict = nil
    --- 服务器下发确认的数据
    local ChapterTeamRecords = {}
    local ChapterTeamRecordsDic = {} -- ChapterTeamRecords 的重定义字典
    local FinishStageIds = {}
    local FinishStageIdDic = {}

    ------ 战斗接口用的数据
    local FinishFightCb = nil
    local CloseLoadingCb = nil
    -- local MEMBER_INDEX_BY_ORDER = {[1] = 2, [2] = 1, [3] = 3} -- 面板上显示的位置(order) = 队伍中实际中的位置(index)
    local MEMBER_ORDER_BY_INDEX = {[1] = 2, [2] = 1, [3] = 3 } -- 队伍中实际中的位置(index) = 面板上显示的位置(order)
    local ChapterIdByStageId = nil -- {[stageId] = chapterId, ...}
    local FollowGroupDict = nil -- {[前置组id] = {后置组id, ...}, ...}

    function XFubenAwarenessManager.Init()
    end

    function XFubenAwarenessManager.GetChapterFirstPassTrigger()
        if ChapterFirstPassTrigger then
            local tempData = ChapterFirstPassTrigger
            ChapterFirstPassTrigger = nil
            return tempData
        end
    end

    -- 角色是否已在占领
    function XFubenAwarenessManager.CheckCharacterInOccupy(characterId)
        local chapterData
        for _, id in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
            chapterData = XFubenAwarenessManager.GetChapterDataById(id)
            if chapterData:GetCharacterId() == characterId then
                return true, id
            end
        end
        return false
    end

    function XFubenAwarenessManager.GetChapterDataById(id)
        if not id then
            XLog.Error("XFubenAwarenessManager.GetChapterDataById函数参数id不能为空" .. tostring(id))
            return
        end
        if not ChapterDataDict then
            ChapterDataDict = {}
        end
        if not ChapterDataDict[id] then
            ChapterDataDict[id] = XAwarenessChapter.New(id)
        end
        return ChapterDataDict[id]
    end

    -- 根据意识位拿chapter
    function XFubenAwarenessManager.GetChapterDataBySiteNum(siteNum)
        local chapterId = XFubenAwarenessManager.GetChapterIdList()[siteNum]
        return XFubenAwarenessManager.GetChapterDataById(chapterId)
    end

    function XFubenAwarenessManager.GetCurrentChapterData()
        local idList = XFubenAwarenessManager.GetChapterIdList()
        for _, chapterId in ipairs(idList) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
            if not chapterData:IsPass() then
                return chapterData
            end
        end
        return XFubenAwarenessManager.GetChapterDataById(idList[#idList])
    end

    function XFubenAwarenessManager.GetChapterIdList()
        if XTool.IsTableEmpty(ChapterIdList) then
            ChapterIdList = {}
            for chapterId, v in pairs(XFubenAwarenessConfigs.GetAllConfigs(XFubenAwarenessConfigs.TableKey.AwarenessChapter)) do
                table.insert(ChapterIdList, chapterId)
            end
            table.sort(ChapterIdList, function(a, b) 
                local chapterA = XFubenAwarenessManager.GetChapterDataById(a)
                local chapterB = XFubenAwarenessManager.GetChapterDataById(b)

                return chapterA:GetCfg().Site < chapterB:GetCfg().Site 
            end)
        end
        return ChapterIdList
    end

    function XFubenAwarenessManager.GetAllChapterOccupyNum()
        local count = 0
        for _, chapterId in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
            if chapterData:IsOccupy() then
                count = count + 1
            end
        end
        return count
    end

    function XFubenAwarenessManager.GetChapterProgressTxt()
        local chapterData = XFubenAwarenessManager.GetCurrentChapterData()
        return CS.XTextManager.GetText("AssignChapterProgressTxt", chapterData:GetDesc())
    end

    function XFubenAwarenessManager.GetCharacterOccupyChapterId(characterId)
        if characterId and characterId ~= 0 then
            for _, chapterId in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
                local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
                if chapterData:GetCharacterId() == characterId then
                    return chapterId
                end
            end
        end
        return nil
    end

    -- 检查该group是否有服务器记录过队伍数据
    function XFubenAwarenessManager.CheckChapterHadRecordTeam(chapterId)
        return ChapterTeamRecordsDic[chapterId]
    end

    -- 检查该group是否有服务器记录过队伍数据
    function XFubenAwarenessManager.GetChapterTeamRecords()
        return ChapterTeamRecords
    end

    function XFubenAwarenessManager.GetFinishStageIds()
        return FinishStageIds
    end

    function XFubenAwarenessManager.CheckStageFinish(stageId)
        return FinishStageIdDic[stageId]
    end

    -- 角色是否已在队伍中
    function XFubenAwarenessManager.CheckCharacterInTeam(characterId)
        for _, teamData in pairs(TeamDataDict) do
            if teamData:GetCharacterOrder(characterId) ~= nil then
                return true
            end
        end
        return false
    end

    -- 该角色是否已有关卡进度 压制
    function XFubenAwarenessManager.CheckCharacterInMultiTeamLock(characterId, groupId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(groupId)
        local isIn, teamData, teamOrder = XFubenAwarenessManager.CheckCharacterInCurChapterTeam(characterId, groupId)

        local stageList = chapterData:GetStageId()
        local stageId = stageList[teamOrder]

        return XFubenAwarenessManager.CheckStageFinish(stageId)
    end

    -- 角色是否已在该chapter的队伍中
    function XFubenAwarenessManager.CheckCharacterInCurChapterTeam(characterId, chapterId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)

        for order, teamId in pairs(chapterData:GetTeamInfoId()) do
            local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
            if teamData:GetCharacterOrder(characterId) ~= nil then
                return true, teamData, order
            end
        end
        return false
    end

    -- 获取其他队伍的角色
    function XFubenAwarenessManager.GetOtherTeamCharacters(chapterId, srcTeamId)
        local otherTeamCharacters = {}
        for _, teamId in pairs(ChapterDataDict[chapterId]:GetTeamInfoId()) do
            if teamId ~= srcTeamId and TeamDataDict[teamId] then
                for i, member in ipairs(TeamDataDict[teamId]:GetMemberList()) do
                    local characterId = member:GetCharacterId()
                    if characterId and characterId ~= 0 then
                        table.insert(otherTeamCharacters, { teamId, i, characterId })
                    end
                end
            end
        end
        return otherTeamCharacters
    end

    -- 获取某组里 角色对应的队伍编号
    function XFubenAwarenessManager.GetCharacterTeamOderMapByGroup(chapterId)
        local teamOrderMap = {}
        local teamIdMap = {}
        for i, teamId in pairs(ChapterDataDict[chapterId]:GetTeamInfoId()) do
            local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
            for _, memberData in ipairs(teamData:GetMemberList()) do
                if memberData:HasCharacter() then
                    teamIdMap[memberData:GetCharacterId()] = teamId
                    teamOrderMap[memberData:GetCharacterId()] = i
                end
            end
        end
        return teamIdMap, teamOrderMap
    end

    function XFubenAwarenessManager.SwapMultiTeamMember(aTeam, aPos, bTeam, bPos)
        local aMemberData = aTeam:GetMemberList()[aPos]
        local bMemberData = bTeam:GetMemberList()[bPos]
        local aTeamaPosCharId = aMemberData:GetCharacterId()
        local bTeambPosCharId = bMemberData:GetCharacterId()

        if aTeamaPosCharId == bTeambPosCharId then
            bMemberData:SetCharacterId(0)
        else
            aMemberData:SetCharacterId(bTeambPosCharId)
            bMemberData:SetCharacterId(aTeamaPosCharId)
        end
    end

    function XFubenAwarenessManager.SetTeamMember(teamId, targetOrder, characterId)
        local targetTeamData = XFubenAwarenessManager.GetTeamDataById(teamId)
        targetTeamData:SetMember(targetOrder, characterId)
    end

    function XFubenAwarenessManager.GetTeamDataById(id)
        if not TeamDataDict then
            TeamDataDict = {}
        end
        if not TeamDataDict[id] then
            TeamDataDict[id] = XAwarenessTeam.New(id)
        end
        return TeamDataDict[id]
    end

    function XFubenAwarenessManager.GetTeamCharacterType(teamId)
        local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
        return teamData:GetCharacterType()
    end

    function XFubenAwarenessManager.IsCharacterInTeamById(teamId, characterId)
        local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
        return teamData:GetCharacterOrder(characterId) ~= nil
    end

    function XFubenAwarenessManager.GetChapterMemberCount(chapterId)
        local count = 0
        for _, teamId in pairs(ChapterDataDict[chapterId]:GetTeamInfoId()) do
            for _, member in ipairs(XFubenAwarenessManager.GetTeamDataById(teamId):GetMemberList()) do
                if member:HasCharacter() then
                    count = count + 1
                end
            end
        end
        return count
    end

    -- 一键上阵
    function XFubenAwarenessManager.AutoTeam(chapterId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
        for k, stageId in pairs(chapterData:GetStageId()) do
            local isFinish = XFubenAwarenessManager.CheckStageFinish(stageId)
            if isFinish then -- 有完成进度
                XUiManager.TipError(CS.XTextManager.GetText("AutoTeamLimit"))
                return
            end
        end

        local ownCharacters = XMVCA.XCharacter:GetOwnCharacterList()
        table.sort(ownCharacters, function(a, b)
            return a.Ability > b.Ability
        end)
        -- 保留当前角色
        -- local curCharacters = XFubenAwarenessManager.GetOtherTeamCharacters(chapterId, nil)
        for _, teamId in pairs(ChapterDataDict[chapterId]:GetTeamInfoId()) do
            local targetTeamData = XFubenAwarenessManager.GetTeamDataById(teamId)
            targetTeamData:ClearMemberList()
        end
        local count = 1
        local maxCount = #ownCharacters
        for _, teamId in pairs(ChapterDataDict[chapterId]:GetTeamInfoId()) do
            if count > maxCount then
                break
            end
            local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
            local needCount = teamData:GetNeedCharacter()
            for index = 1, needCount do
                local order = XFubenAwarenessManager.GetMemberOrderByIndex(index, needCount)
                local targetTeamData = XFubenAwarenessManager.GetTeamDataById(teamId)

                local stageId = teamId
                local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamId)
                local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)

                local i
                for charIndex, char in ipairs(ownCharacters) do
                    local charType = XMVCA.XCharacter:GetCharacterType(char.Id)
                    if defaultCharacterType ~= XFubenConfigs.CharacterLimitType.All and defaultCharacterType ~= charType then
                        goto CONTINUE
                    end
                    XFubenAwarenessManager.SetTeamMember(teamId, order, char.Id)
                    i = charIndex
                    break
                    :: CONTINUE ::
                end
                if i then
                    table.remove(ownCharacters, i)
                end
            end
        end
    end

    function XFubenAwarenessManager.GetTeamGeneralSkillId(teamId)
        if GeneralSkillIdDict == nil then
            GeneralSkillIdDict = XSaveTool.GetData(XFubenAwarenessManager.GetGeneralSkillCacheKey()) or {}
        end

        return GeneralSkillIdDict[teamId] or 0
    end

    function XFubenAwarenessManager.SetTeamGeneralSkillId(teamId, generalSkillId)
        if GeneralSkillIdDict == nil then
            GeneralSkillIdDict = XSaveTool.GetData(XFubenAwarenessManager.GetGeneralSkillCacheKey()) or {}
        end

        GeneralSkillIdDict[teamId] = generalSkillId
    end

    function XFubenAwarenessManager.SaveTeamGeneralSkillDict()
        if not XTool.IsTableEmpty(GeneralSkillIdDict) then
            XSaveTool.SaveData(XFubenAwarenessManager.GetGeneralSkillCacheKey(), GeneralSkillIdDict)
        end
    end

    function XFubenAwarenessManager.GetGeneralSkillCacheKey()
        return 'XFubenAwareness'..tostring(XPlayer.Id)
    end

    -- 是否满足关卡所需战力
    function XFubenAwarenessManager.IsAbilityMatch(targetStageId, charIdList)
        local chapterId = XFubenAwarenessConfigs.GetChapterIdByStageId(targetStageId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
        local isMatch = false
        local teamIdList = chapterData:GetTeamInfoId()
        for i, stageId in pairs(chapterData:GetStageId()) do
            if stageId == targetStageId then
                isMatch = true
                local teamId = teamIdList[i]
                local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
                for order = 1, teamData:GetNeedCharacter() do
                    local characterId = charIdList[order]
                    local character = XMVCA.XCharacter:GetCharacter(characterId)
                    if character.Ability < teamData:GetRequireAbility() then
                        isMatch = false
                        break
                    end
                end
                break
            end
        end
        return isMatch
    end

    function XFubenAwarenessManager.SetCloseLoadingCb(cb)
        CloseLoadingCb = cb
    end

    function XFubenAwarenessManager.SetFinishFightCb(cb)
        FinishFightCb = cb
    end

    function XFubenAwarenessManager.GetMemberOrderByIndex(index, maxCount)
        return maxCount > 1 and MEMBER_ORDER_BY_INDEX[index] or index
    end


    function XFubenAwarenessManager.CheckIsGroupLastStage(stageId)
        local chapterId = XFubenAwarenessConfigs.GetChapterIdByStageId(stageId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
        local stageIdList = chapterData:GetStageId()
        return (stageIdList[#stageIdList] == stageId)
    end

    ------ 以下是在FubenManager注册的函数
    --function XFubenAwarenessManager.InitStageInfo()
    --    local stageType = XDataCenter.FubenManager.StageType.Awareness
    --    for _, chapterId in pairs(XFubenAwarenessManager.GetChapterIdList()) do
    --        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
    --        for _, stageId in ipairs(chapterData:GetStageId()) do
    --            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --            stageInfo.IsOpen = true
    --            stageInfo.Type = stageType
    --        end
    --    end
    --end

    -- 设置进入loading界面用到的数据
    function XFubenAwarenessManager.SetEnterLoadingData(stageIndex, teamCharList, chapterData, isNextFight)
        LoadingData = {
            StageIndex = stageIndex,
            TeamCharList = teamCharList,
            ChapterData = chapterData,
            IsNextFight = isNextFight,
        }
    end

    -- 打开战斗前loading界面
    function XFubenAwarenessManager.OpenFightLoading(stageId)
        if LoadingData.IsNextFight then
            XLuaUiManager.Open("UiAssignLoading", LoadingData)
        else
            XLuaUiManager.Open("UiLoading", LoadingType.Fight)
        end
    end

    function XFubenAwarenessManager.CloseFightLoading()
        XLuaUiManager.Remove("UiAssignLoading")
        XLuaUiManager.Remove("UiLoading")
        if CloseLoadingCb then
            CloseLoadingCb()
        end
    end

    function XFubenAwarenessManager.ShowReward(winData)
        -- 同步本地战斗后的关卡数据
        -- 关卡通关数据要先刷新，再在下一关for循环检测，最后再清除
        FinishStageIdDic[winData.StageId] = true
        
        local index = nil
        local targetNextStageId = nil
        local chapterData = LoadingData.ChapterData
        local stageIdList = chapterData:GetStageId()
        for i = 1, #stageIdList, 1 do
            local stageId = stageIdList[i]
            if not XFubenAwarenessManager.CheckStageFinish(stageId) then
                index = i
                targetNextStageId = stageId
                break
            end
        end
        
        -- 如果还有未完成的关
        if targetNextStageId then
            -- 且是连续挑战
            if LoadingData.IsNextFight then
                local isNextFight = true
    
                local _, teamCharListOrg, captainPosList, firstFightPosList, generalSkillIdList = XFubenAwarenessManager.TryGetFightTeamCharList(chapterData:GetId())
                local teamCharList = teamCharListOrg[index]
    
                XFubenAwarenessManager.SetEnterLoadingData(index, teamCharList, chapterData, isNextFight)
                XDataCenter.FubenManager.EnterAwarenessFight(targetNextStageId, teamCharList, captainPosList[index], nil, nil, firstFightPosList[index], generalSkillIdList[index])
            end
        else
            -- 如果没有未完成的关了 说明已经作战完毕 结算
            -- 并清除所有已完成的关卡数据
            for k, id in pairs(stageIdList) do
                FinishStageIdDic[id] = nil
            end

            chapterData:SetFightCount(chapterData:GetFightCount() + 1)

            -- 检测设置首通提示驻守trigger
            if chapterData:GetFightCount() == 1 then
                ChapterFirstPassTrigger = chapterData:GetId()
            end
            
            XLuaUiManager.Remove("UiAwarenessDeploy")
            XLuaUiManager.Remove("UiAssignLoading")
            XLuaUiManager.Open("UiAwarenessSettleWin", winData)
        end

        -- 结算完刷新下数据
        XFubenAwarenessManager.AwarenessGetDataRequest()
    end
    ----------- 战斗接口 end-----------

    -- 某角色某技能加成
    function XFubenAwarenessManager.GetSkillLevel(characterId, skillId)
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        if not character then return 0 end

        local keys, levels = XFubenAwarenessManager.GetBuffKeysAndLevels()
        local npcTemplate = XMVCA.XCharacter:GetNpcTemplate(character.NpcId)
        local tragetCharacterType = npcTemplate.Type
        local targetSkilType = XMVCA.XCharacter:GetSkillType(skillId)
        local level = nil
        for _, key in pairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            if (characterType == tragetCharacterType or characterType == CHARACTERTYPE_ALL) and skillType == targetSkilType then
                level = levels[key]
            end
        end
        return level or 0
    end

    function XFubenAwarenessManager.GetSkillLevelByCharacterData(character, skillId, assignChapterRecords)
        local keys = {}
        local levels = {}
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = XAwarenessChapter.New(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)

            if chapterData:IsOccupy() then
                for _, key in ipairs(chapterData:GetBuffKeys()) do
                    if not levels[key] then
                        levels[key] = 1
                        table.insert(keys, key)
                    else
                        levels[key] = levels[key] + 1
                    end
                end
            end
        end
        local npcTemplate = XMVCA.XCharacter:GetNpcTemplate(character.NpcId)
        local tragetCharacterType = npcTemplate.Type
        local targetSkilType = XMVCA.XCharacter:GetSkillType(skillId)
        local level = nil
        for _, key in pairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            if (characterType == tragetCharacterType or characterType == CHARACTERTYPE_ALL) and skillType == targetSkilType then
                level = levels[key]
            end
        end
        return level or 0
    end

    -- 参数keys: {角色类型*1000+技能类型, ...}
    -- 参数levels: {[key] = level, ...}
    function XFubenAwarenessManager.GetBuffDescListByKeys(keys, levels)
        local descList = {}
        local GetCareerName = function (type)
            return XMVCA.XCharacter:GetCareerName(type)
        end
        local GetText = CS.XTextManager.GetText
        for _, key in ipairs(keys) do
            local skillType = key % SKILLTYPE_BITS
            local characterType = (key - skillType) / SKILLTYPE_BITS
            local level = levels and levels[key] or 1
            local memberTypeName = characterType == CHARACTERTYPE_ALL and "" or GetCareerName(characterType)
            local str = GetText("AssignSkillPlus", memberTypeName, XMVCA.XCharacter:GetSkillTypeName(skillType), level) -- 全体{0}成员{1}等级+{2}
            table.insert(descList, str)
        end
        return descList
    end

    function XFubenAwarenessManager.GetBuffKeysAndLevels()
        local keys = {}
        local levels = {}
        for _, id in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(id)
            if chapterData:IsOccupy() then
                for _, key in ipairs(chapterData:GetBuffKeys()) do
                    if not levels[key] then
                        levels[key] = 1
                        table.insert(keys, key)
                    else
                        levels[key] = levels[key] + 1
                    end
                end
            end
        end
        return keys, levels
    end

    function XFubenAwarenessManager.SortKeys(keys)
        table.sort(keys, function(a, b)
            local skillTypeA = a % SKILLTYPE_BITS
            local characterTypeA = (a - skillTypeA) / SKILLTYPE_BITS
            local skillTypeB = b % SKILLTYPE_BITS
            local characterTypeB = (b - skillTypeB) / SKILLTYPE_BITS
            if skillTypeA ~= skillTypeB then
                return skillTypeA < skillTypeB
            end
            return characterTypeA < characterTypeB
        end)
        return keys
    end

    function XFubenAwarenessManager.GetAllBuffList()
        local keys, levels = XFubenAwarenessManager.GetBuffKeysAndLevels()
        keys = XFubenAwarenessManager.SortKeys(keys)
        return XFubenAwarenessManager.GetBuffDescListByKeys(keys, levels)
    end

    function XFubenAwarenessManager.TryGetFightTeamCharList(chapterId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
        local teamList = {}
        local captainPosList = {}
        local firstFightPosList = {}
        local generalSkillIdList = {}
        local teamIdList = chapterData:GetTeamInfoId()
        local allTeamHasMember = (#teamIdList > 0)
        for i, teamId in ipairs(teamIdList) do
            teamList[i] = {}
            local count = 0
            local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
            captainPosList[i] = teamData:GetLeaderIndex()
            firstFightPosList[i] = teamData:GetFirstFightIndex()
            local memberList = teamData:GetMemberList()
            for _, memberData in ipairs(memberList) do
                local characterId = memberData:GetCharacterId() or 0
                teamList[i][memberData:GetIndex()] = characterId
                if characterId ~= 0 then
                    count = count + 1
                end
            end
            if count < #memberList then
                allTeamHasMember = false
            end

            local generalSkillId = teamData:GetCurGeneralSkill() or 0
            table.insert(generalSkillIdList, generalSkillId)
        end
        return allTeamHasMember, teamList, captainPosList, firstFightPosList, generalSkillIdList
    end

    function XFubenAwarenessManager.IsRedPoint()
        for _, chapterId in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
            if chapterData:CanReward() then
                return true
            end
        end
        return false
    end

    -- 是否满足关卡所需战力
    function XFubenAwarenessManager.IsStagePass(stageId)
        local chapterId = XFubenAwarenessConfigs.GetChapterIdByStageId(stageId)
        local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
        return chapterData:IsPass()
    end

    function XFubenAwarenessManager.UpdateChapterRecords(chapterRecords)
        if not chapterRecords then
            return
        end
        for _, v in pairs(chapterRecords) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)
            chapterData:SetRewarded(v.IsGetReward)
            chapterData:SetIsPassByServer(true)
        end
    end

    function XFubenAwarenessManager.RefreshAwarenessInfo(data)
        local info = data.AwarenessInfo
        if XTool.IsTableEmpty(info) then
            return
        end

        -- 章节占领角色数据
        local chapterRecords = info.ChapterRecords
        XFubenAwarenessManager.UpdateChapterRecords(chapterRecords)

        -- 关卡通关数据
        FinishStageIdDic = {}
        local chapterChallengeRecords = info.ChallengeRecords
        for _, v in pairs(chapterChallengeRecords or {}) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(v.ChapterId)
            chapterData:SetFightCount(v.Count)
            if not XTool.IsTableEmpty(v.FinishStageIds) then
                for k, id in pairs(v.FinishStageIds) do
                    -- 使用全局变量记录服务器发下来的数据
                    -- 已通关的StageId
                    FinishStageIdDic[id] = true
                end
            end
        end
        
        -- 编队记录
        ChapterTeamRecords = info.TeamRecords 
        ChapterTeamRecordsDic = {}
        for _, v in ipairs(ChapterTeamRecords or {}) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(v.ChapterId)
            local teamCount = #v.TeamInfoList
            local posCount = v.CaptainPosList and #v.CaptainPosList or 0
            local firstFightCount = v.FirstFightPosList and #v.FirstFightPosList or 0

            for i, teamId in ipairs(chapterData:GetTeamInfoId()) do
                local teamData = XFubenAwarenessManager.GetTeamDataById(teamId)
                local charaterIds = (i <= teamCount) and v.TeamInfoList[i] or nil
                local captainPos = (i <= posCount) and v.CaptainPosList[i] or XFubenAwarenessManager.CAPTIAN_MEMBER_INDEX
                local firstFightPos = (i <= firstFightCount) and v.FirstFightPosList[i] or XFubenAwarenessManager.FIRSTFIGHT_MEMBER_INDEX
                teamData:SetMemberList(charaterIds)
                teamData:SetLeaderIndex(captainPos)
                teamData:SetFirstFightIndex(firstFightPos)
                teamData:UpdateSelectGeneralSkill(XFubenAwarenessManager.GetTeamGeneralSkillId(teamId), true)
            end
            -- 队伍字典
            ChapterTeamRecordsDic[v.ChapterId] = v
        end
    end

    -----------------协议----------
    -- Login登录后端初始化数据接口
    function XFubenAwarenessManager.NotifyLoginAwarenessInfo(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        XFubenAwarenessManager.RefreshAwarenessInfo(data)
    end

    function XFubenAwarenessManager.AwarenessGetDataRequest(cb)
        XNetwork.Call("AwarenessGetDataRequest", nil, function(res)
            XFubenAwarenessManager.RefreshAwarenessInfo(res)
            if cb then
                cb()
            end
        end)
    end

    function XFubenAwarenessManager.AwarenessSetTeamRequest(ChapterId, TeamList, captainPosList, firstFightPosList, generalSkillIds, cb)
        XNetwork.Call("AwarenessSetTeamRequest", { ChapterId = ChapterId, TeamList = TeamList, CaptainPosList = captainPosList, FirstFightPosList = firstFightPosList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            --保存效应技能
            local chapterData = XFubenAwarenessManager.GetChapterDataById(ChapterId)
            for i, teamId in ipairs(chapterData:GetTeamInfoId()) do
                XFubenAwarenessManager.SetTeamGeneralSkillId(teamId, generalSkillIds[i] or 0)
            end

            XFubenAwarenessManager.SaveTeamGeneralSkillDict()
            
            if cb then
                cb()
            end
        end)
    end

    function XFubenAwarenessManager.AwarenessSetCharacterRequest(ChapterId, CharacterId, cb) 
        XNetwork.Call("AwarenessSetCharacterRequest", { ChapterId = ChapterId, CharacterId = CharacterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chapterData = XFubenAwarenessManager.GetChapterDataById(ChapterId)
            chapterData:SetCharacterId(CharacterId)

            XEventManager.DispatchEvent(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY) -- 重新计算角色战力
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END) -- 刷新驻守界面
            if cb then
                cb()
            end
        end)
    end

    function XFubenAwarenessManager.AwarenessGetRewardRequest(ChapterId, cb)
        XNetwork.Call("AwarenessGetRewardRequest", { ChapterId = ChapterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chapterData = XFubenAwarenessManager.GetChapterDataById(ChapterId)
            chapterData:SetRewarded(true)
            XUiManager.OpenUiObtain(res.RewardList or {})
            if cb then
                cb()
            end
        end)
    end

    -- 重置关卡
    function XFubenAwarenessManager.AwarenessResetStageRequest(chapterId, stageId, cb)
        XNetwork.Call("AwarenessResetStageRequest", { ChapterId = chapterId, StageId = stageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            FinishStageIdDic[stageId] = nil

            if cb then
                cb()
            end
        end)
    end

    function XFubenAwarenessManager.GetSkillPlusIdList()
        local list = {}
        for _, chapterId in ipairs(XFubenAwarenessManager.GetChapterIdList()) do
            local chapterData = XFubenAwarenessManager.GetChapterDataById(chapterId)
            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    function XFubenAwarenessManager.GetSkillPlusIdListOther(assignChapterRecords)

        local list = {}
        if assignChapterRecords == nil then
            return list
        end
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = XAwarenessChapter.New(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)

            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    -- 2选1入口的红点
    function XFubenAwarenessManager.CheckIsShowRedPoint()
        for k, chapterId in pairs(XFubenAwarenessManager.GetChapterIdList()) do
            local chapter =  XFubenAwarenessManager.GetChapterDataById(chapterId)
            if chapter:IsRed() then
                return true
            end
        end
        return false
    end

    function XFubenAwarenessManager.OpenUi(openCb)
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAwareness, true) then
            if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.FubenAwareness) then
                return
            end
            if openCb then
                XLuaUiManager.OpenWithCallback("UiAwarenessMain", openCb)
            else
                XLuaUiManager.Open("UiAwarenessMain")
            end
        end
    end
    
    XFubenAwarenessManager.Init()
    return XFubenAwarenessManager
end

XRpc.NotifyLoginAwarenessInfo = function(data)
    XDataCenter.FubenAwarenessManager.NotifyLoginAwarenessInfo(data)
end
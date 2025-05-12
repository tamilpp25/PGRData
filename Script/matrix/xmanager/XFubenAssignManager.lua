local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
--- 占领副本管理器
XFubenAssignManagerCreator = function()
    ---@class XFubenAssignManager:XExFubenSimulationChallengeManager
    local XFubenAssignManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.Assign)

    -- 协议
    local METHOD_NAME = {
        AssignGetDataRequest = "AssignGetDataRequest",
        AssignSetTeamRequest = "AssignSetTeamRequest",
        AssignSetCharacterRequest = "AssignSetCharacterRequest",
        AssignGetRewardRequest = "AssignGetRewardRequest",
        AssignResetStageRequest = "AssignResetStageRequest",
    }

    -- 常量
    XFubenAssignManager.MaxSelectConditionNum = 4
    XFubenAssignManager.SelectConditionColor = {[true] = CS.UnityEngine.Color.black, [false] = CS.UnityEngine.Color.gray }
    XFubenAssignManager.MemberColor = {
        "FF1111FF", -- red
        "4F99FFFF", -- blue
        "F9CB35FF", -- yellow
    }
    XFubenAssignManager.FomationAnimFinishDelay = 400 -- 特效显示时间
    XFubenAssignManager.FormationState = { Effect = 1, Reset = 2 }
    local CHARACTERTYPE_ALL = 0
    local SKILLTYPE_BITS = 1000
    local KeyAccountEnterAssign = "Assign"

    -- ui操作所缓存的数据
    XFubenAssignManager.SelectChapterId = nil
    XFubenAssignManager.SelectGroupId = nil
    XFubenAssignManager.SelectCharacterId = nil
    XFubenAssignManager.OccupyFirstSelectTeamId = nil
    XFubenAssignManager.OccupyFirstSelectOrder = nil
    XFubenAssignManager.OccupySecondSelectTeamId = nil
    XFubenAssignManager.OccupySecondSelectOrder = nil

    XFubenAssignManager.CAPTIAN_MEMBER_INDEX = 1 -- 队长位置
    XFubenAssignManager.FIRSTFIGHT_MEMBER_INDEX = 1 -- 首发位置
    local MEMBER_MAX_COUNT = 3 -- 队伍最大成员数

    -- 自定义数据
    local ChapterIdList = nil
    local ChapterDataDict = nil -- 章节
    local GroupDataDict = nil -- 关卡组
    ---@type XAssignTeam[]
    local TeamDataDict = nil -- 队伍
    local LoadingData = nil
    local ChapterFirstPassTrigger = nil
    local GeneralSkillDict = nil --效应选择缓存
    --- 服务器下发确认的数据
    local GroupTeamRecords = {}
    local GroupTeamRecordsDic = {} -- GroupTeamRecords 的重定义字典
    local FinishStageIds = {}
    local FinishStageIdDic = {}

    ------ 战斗接口用的数据
    local FinishFightCb = nil
    local CloseLoadingCb = nil
    -- local MEMBER_INDEX_BY_ORDER = {[1] = 2, [2] = 1, [3] = 3} -- 面板上显示的位置(order) = 队伍中实际中的位置(index)
    local MEMBER_ORDER_BY_INDEX = {[1] = 2, [2] = 1, [3] = 3 } -- 队伍中实际中的位置(index) = 面板上显示的位置(order)
    local GroupIdByStageId = nil -- {[stageId] = groupId, ...}
    local FollowGroupDict = nil -- {[前置组id] = {后置组id, ...}, ...}

    function XFubenAssignManager.Init()
    end

    function XFubenAssignManager.ClearData()
        XFubenAssignManager.SelectChapterId = nil
        XFubenAssignManager.SelectGroupId = nil
        XFubenAssignManager.SelectCharacterId = nil
        XFubenAssignManager.OccupyFirstSelectTeamId = nil
        XFubenAssignManager.OccupyFirstSelectOrder = nil
        XFubenAssignManager.OccupySecondSelectTeamId = nil
        XFubenAssignManager.OccupySecondSelectOrder = nil

        ChapterIdList = nil
        ChapterDataDict = nil -- 章节
        GroupDataDict = nil -- 关卡组
        TeamDataDict = nil -- 队伍
        FollowGroupDict = nil
    end

    function XFubenAssignManager.GetChapterFirstPassTrigger()
        if ChapterFirstPassTrigger then
            local tempData = ChapterFirstPassTrigger
            ChapterFirstPassTrigger = nil
            return tempData
        end
    end

    ----------- 章节数据 begin-----------
    local XAssignChapter = require("XEntity/XAssign/XAssignChapter")

    -- 是否当前进度章节
    function XFubenAssignManager.IsCurrentChapter(chapterId)
        local passNum = XFubenAssignManager.GetAllChapterPassNum()
        local targetIndex = 0
        for i, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            if chapterId == id then
                targetIndex = i
                break
            end
        end
        if targetIndex == 0 then
            XLog.Debug("XFubenAssignManager.IsCurrentChapter参数传入了无效的chapterId: " .. tostring(chapterId))
        end
        return (targetIndex == passNum + 1)
    end

    function XFubenAssignManager.GetAllChapterPassNum()
        local passNum = 0
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsPass() then
                passNum = passNum + 1
            end
        end
        return passNum
    end

    function XFubenAssignManager.GetAllChapterRewardedNum()
        local count = 0
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsRewarded() then
                count = count + 1
            end
        end
        return count
    end

    function XFubenAssignManager.GetAllChapterOccupyNum()
        local count = 0
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsOccupy() then
                count = count + 1
            end
        end
        return count
    end

    function XFubenAssignManager.GetCharacterOccupyChapterId(characterId)
        if characterId and characterId ~= 0 then
            for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
                local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
                if chapterData:GetCharacterId() == characterId then
                    return chapterId
                end
            end
        end
        return nil
    end

    function XFubenAssignManager.GetChapterIdList()
        if not ChapterIdList then
            ChapterIdList = {}
            for id, _ in pairs(XFubenAssignConfigs.GetChapterTemplates()) do
                table.insert(ChapterIdList, id)
            end
            table.sort(ChapterIdList, function(a, b) return a < b end)
        end
        return ChapterIdList
    end

    function XFubenAssignManager.GetUnlockChapterIdList()
        local idList = {}
        local data
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            data = XFubenAssignManager.GetChapterDataById(id)
            if data:IsUnlock() then
                table.insert(idList, id)
            end
        end
        return idList
    end

    -- 角色是否已在占领
    function XFubenAssignManager.CheckCharacterInOccupy(characterId)
        local chapterData
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            chapterData = XFubenAssignManager.GetChapterDataById(id)
            if chapterData:GetCharacterId() == characterId then
                return true
            end
        end
        return false
    end

    function XFubenAssignManager.GetChapterDataById(id)
        if not id then
            XLog.Error("XFubenAssignManager.GetChapterDataById函数参数id不能为空" .. tostring(id))
            return
        end
        if not ChapterDataDict then
            ChapterDataDict = {}
        end
        if not ChapterDataDict[id] then
            ChapterDataDict[id] = XAssignChapter.New(id)
        end
        return ChapterDataDict[id]
    end

    function XFubenAssignManager.GetCurrentChapterData()
        local idList = XFubenAssignManager.GetChapterIdList()
        for _, chapterId in ipairs(idList) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if not chapterData:IsPass() then
                return chapterData
            end
        end
        return XFubenAssignManager.GetChapterDataById(idList[#idList])
    end

    function XFubenAssignManager.GetChapterProgressTxt()
        local chapterData = XFubenAssignManager.GetCurrentChapterData()
        return CS.XTextManager.GetText("AssignChapterProgressTxt", chapterData:GetDesc())
    end
    ----------- 章节数据 end-----------
    ----------- 关卡组数据 begin-----------
    local XAssignGroup = require("XEntity/XAssign/XAssignGroup")

    function XFubenAssignManager.GetGroupDataById(id)
        if not GroupDataDict then
            GroupDataDict = {}
        end
        if not GroupDataDict[id] then
            GroupDataDict[id] = XAssignGroup.New(id)
        end
        return GroupDataDict[id]
    end
    ----------- 关卡组数据 end-----------
    -------队伍数据
    local XAssignTeam = require("XEntity/XAssign/XAssignTeam")

    -- 检查该group是否有服务器记录过队伍数据
    function XFubenAssignManager.CheckGroupHadRecordTeam(groupId)
        return GroupTeamRecordsDic[groupId]
    end

    -- 检查该group是否有服务器记录过队伍数据
    function XFubenAssignManager.GetGroupTeamRecords()
        return GroupTeamRecords
    end

    function XFubenAssignManager.GetFinishStageIds()
        return FinishStageIds
    end

    function XFubenAssignManager.CheckStageFinish(stageId)
        return FinishStageIdDic[stageId]
    end

    -- 角色是否已在队伍中
    function XFubenAssignManager.CheckCharacterInTeam(characterId)
        for _, teamData in pairs(TeamDataDict) do
            if teamData:GetCharacterOrder(characterId) ~= nil then
                return true
            end
        end
        return false
    end

    -- 该角色是否已有关卡进度 压制
    function XFubenAssignManager.CheckCharacterInMultiTeamLock(characterId, groupId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local isIn, teamData, teamOrder = XFubenAssignManager.CheckCharacterInCurGroupTeam(characterId, groupId)

        local stageList = groupData:GetStageId()
        local stageId = stageList[teamOrder]

        return XFubenAssignManager.CheckStageFinish(stageId)
    end

    -- 角色是否已在该group的队伍中
    function XFubenAssignManager.CheckCharacterInCurGroupTeam(characterId, groupId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)

        for order, teamId in pairs(groupData:GetTeamInfoId()) do
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            if teamData:GetCharacterOrder(characterId) ~= nil then
                return true, teamData, order
            end
        end
        return false
    end

    -- 获取其他队伍的角色
    function XFubenAssignManager.GetOtherTeamCharacters(groupId, srcTeamId)
        local otherTeamCharacters = {}
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
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
    function XFubenAssignManager.GetCharacterTeamOderMapByGroup(groupId)
        local teamOrderMap = {}
        local teamIdMap = {}
        for i, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            for _, memberData in ipairs(teamData:GetMemberList()) do
                if memberData:HasCharacter() then
                    teamIdMap[memberData:GetCharacterId()] = teamId
                    teamOrderMap[memberData:GetCharacterId()] = i
                end
            end
        end
        return teamIdMap, teamOrderMap
    end

    function XFubenAssignManager.SwapMultiTeamMember(aTeam, aPos, bTeam, bPos)
        local aMemberData = aTeam:GetMemberList()[aPos]
        local bMemberData = bTeam:GetMemberList()[bPos]
        local aTeamaPosCharId = aMemberData:GetCharacterId()
        local bTeambPosCharId = bMemberData:GetCharacterId()
        -- 后续维护的人：这里由于远古设计，teamList里的key不是角色真正在队伍里的pos, 要拿MemberData才行。而且这个xteam和通用的不一样，尽量不要SetMember，直接SetCharList或者拿
        if aTeamaPosCharId == bTeambPosCharId then
            bMemberData:SetCharacterId(0)
        else
            aMemberData:SetCharacterId(bTeambPosCharId)
            bMemberData:SetCharacterId(aTeamaPosCharId)
        end
    end

    function XFubenAssignManager.SetTeamMember(teamId, targetOrder, characterId)
        local targetTeamData = XFubenAssignManager.GetTeamDataById(teamId)
        -- -- 检查所有队伍并清除该characterId
        -- local order = nil
        -- for k, teamData in pairs(TeamDataDict) do
        --     order = teamData:GetCharacterOrder(characterId)
        --     if order ~= nil then
        --         teamData:SetMember(order, nil)
        --         break
        --     end
        -- end
        targetTeamData:SetMember(targetOrder, characterId)
    end

    function XFubenAssignManager.GetTeamDataById(id)
        if not TeamDataDict then
            TeamDataDict = {}
        end
        if not TeamDataDict[id] then
            TeamDataDict[id] = XAssignTeam.New(id)
        end
        return TeamDataDict[id]
    end

    function XFubenAssignManager.GetTeamCharacterType(teamId)
        local teamData = XFubenAssignManager.GetTeamDataById(teamId)
        return teamData:GetCharacterType()
    end

    function XFubenAssignManager.IsCharacterInTeamById(teamId, characterId)
        local teamData = XFubenAssignManager.GetTeamDataById(teamId)
        return teamData:GetCharacterOrder(characterId) ~= nil
    end

    function XFubenAssignManager.GetGroupMemberCount(groupId)
        local count = 0
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            for _, member in ipairs(XFubenAssignManager.GetTeamDataById(teamId):GetMemberList()) do
                if member:HasCharacter() then
                    count = count + 1
                end
            end
        end
        return count
    end

    -- 一键上阵
    function XFubenAssignManager.AutoTeam(groupId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        for k, stageId in pairs(groupData:GetStageId()) do
            local isFinish = XFubenAssignManager.CheckStageFinish(stageId)
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
        -- local curCharacters = XFubenAssignManager.GetOtherTeamCharacters(groupId, nil)
        -- 先清空，再上阵
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            local targetTeamData = XFubenAssignManager.GetTeamDataById(teamId)
            targetTeamData:ClearMemberList()
        end
        local count = 1
        local maxCount = #ownCharacters
        for _, teamId in pairs(GroupDataDict[groupId]:GetTeamInfoId()) do
            if count > maxCount then
                break
            end
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
            local needCount = teamData:GetNeedCharacter()
            for index = 1, needCount do
                local order = XFubenAssignManager.GetMemberOrderByIndex(index, needCount)
                local targetTeamData = XFubenAssignManager.GetTeamDataById(teamId)

                local stageId = teamId
                local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(teamId)
                local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)

                local i
                for charIndex, char in ipairs(ownCharacters) do
                    local charType = XMVCA.XCharacter:GetCharacterType(char.Id)
                    if defaultCharacterType ~= XFubenConfigs.CharacterLimitType.All and defaultCharacterType ~= charType then
                        goto CONTINUE
                    end
                    XFubenAssignManager.SetTeamMember(teamId, order, char.Id)
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

    -- 是否满足关卡所需战力
    function XFubenAssignManager.IsAbilityMatch(targetStageId, charIdList)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(targetStageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local isMatch = false
        local teamIdList = groupData:GetTeamInfoId()
        for i, stageId in pairs(groupData:GetStageId()) do
            if stageId == targetStageId then
                isMatch = true
                local teamId = teamIdList[i]
                local teamData = XFubenAssignManager.GetTeamDataById(teamId)
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
    
    function XFubenAssignManager.GetTeamGeneralSkillId(teamId)
        if GeneralSkillDict == nil then
            GeneralSkillDict = XSaveTool.GetData(XFubenAssignManager.GetGeneralSkillCacheKey()) or {}
        end
        
        return GeneralSkillDict[teamId] or 0
    end
    
    function XFubenAssignManager.SetTeamGeneralSkillId(teamId, generalSkillId)
        if GeneralSkillDict == nil then
            GeneralSkillDict = XSaveTool.GetData(XFubenAssignManager.GetGeneralSkillCacheKey()) or {}
        end

        GeneralSkillDict[teamId] = generalSkillId
    end
    
    function XFubenAssignManager.SaveTeamGeneralSkillDict()
        if not XTool.IsTableEmpty(GeneralSkillDict) then
            XSaveTool.SaveData(XFubenAssignManager.GetGeneralSkillCacheKey(), GeneralSkillDict)
        end
    end
    
    function XFubenAssignManager.GetGeneralSkillCacheKey()
        return 'XFubenAssign'..tostring(XPlayer.Id)
    end
    ----------- 队伍数据 end-----------
    ----------- 战斗接口 begin-----------
    function XFubenAssignManager.SetCloseLoadingCb(cb)
        CloseLoadingCb = cb
    end

    function XFubenAssignManager.SetFinishFightCb(cb)
        FinishFightCb = cb
    end

    -- function XFubenAssignManager.GetMemberIndexByOrder(order)
    --     return MEMBER_INDEX_BY_ORDER[order]
    -- end
    function XFubenAssignManager.GetMemberOrderByIndex(index, maxCount)
        return maxCount > 1 and MEMBER_ORDER_BY_INDEX[index] or index
    end

    function XFubenAssignManager.GetGroupIdByStageId(stageId)
        if not GroupIdByStageId then
            GroupIdByStageId = {}
            local GroupTemplates = XFubenAssignConfigs.GetGroupTemplates()
            local groupData
            for groupId, _ in pairs(GroupTemplates) do
                groupData = XFubenAssignManager.GetGroupDataById(groupId)
                for _, id in ipairs(groupData:GetStageId()) do
                    GroupIdByStageId[id] = groupId
                end
            end
        end
        return GroupIdByStageId[stageId]
    end

    function XFubenAssignManager.CheckIsGroupLastStage(stageId)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(stageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local stageIdList = groupData:GetStageId()
        return (stageIdList[#stageIdList] == stageId)
    end

    ------ 以下是在FubenManager注册的函数
    --function XFubenAssignManager.InitStageInfo()
    --    local stageType = XDataCenter.FubenManager.StageType.Assign
    --    local chapterData
    --    local groupData
    --    for _, chapterid in pairs(XFubenAssignManager.GetChapterIdList()) do
    --        chapterData = XFubenAssignManager.GetChapterDataById(chapterid)
    --        for _, groupId in pairs(chapterData:GetGroupId()) do
    --            groupData = XFubenAssignManager.GetGroupDataById(groupId)
    --
    --            local isUnlock = groupData:IsUnlock()
    --            for _, stageId in ipairs(groupData:GetStageId()) do
    --                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --                --stageInfo.IsOpen = true
    --                stageInfo.Type = stageType
    --                stageInfo.Unlock = isUnlock
    --                stageInfo.ChapterId = chapterid
    --            end
    --
    --            local baseStageInfo = XDataCenter.FubenManager.GetStageInfo(groupData:GetBaseStageId())
    --            --baseStageInfo.IsOpen = true
    --            baseStageInfo.Type = stageType
    --            baseStageInfo.Unlock = isUnlock
    --            baseStageInfo.ChapterId = chapterid
    --        end
    --    end
    --end
    
    function XFubenAssignManager.CheckUnlockByStageId(stageId)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(stageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        if not groupData then
            XLog.Error("[XFubenAssignManager] 重写unlock可能存在错误, 取不到对应的groupData")
            return false
        end
        local isUnlock = groupData:IsUnlock()
        return isUnlock
    end

    function XFubenAssignManager.FinishFight(settle)
        
        local groupId = XFubenAssignManager.GetGroupIdByStageId(settle.StageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        if not groupData:GetIsPerfect() then
            if settle.IsWin then
                groupData:SetGroupRebootCountAdd(CS.XFight.Instance.FightReboot.RebootCount)
            else
                groupData:ResetGroupRebootCount()
            end
        end

        XDataCenter.FubenManager.FinishFight(settle)

        if FinishFightCb then
            FinishFightCb(settle.IsWin)
        end
    end

    -- 设置进入loading界面用到的数据
    function XFubenAssignManager.SetEnterLoadingData(stageIndex, teamCharList, groupData, chapterData, isNextFight)
        LoadingData = {
            StageIndex = stageIndex,
            TeamCharList = teamCharList,
            GroupData = groupData,
            ChapterData = chapterData,
            IsNextFight = isNextFight,
        }
    end

    -- 打开战斗前loading界面
    function XFubenAssignManager.OpenFightLoading(stageId)
        if LoadingData.IsNextFight then
            XLuaUiManager.Open("UiAssignLoading", LoadingData)
        else
            XLuaUiManager.Open("UiLoading", LoadingType.Fight)
        end
    end

    function XFubenAssignManager.CloseFightLoading()
        XLuaUiManager.Remove("UiAssignLoading")
        XLuaUiManager.Remove("UiLoading")
        if CloseLoadingCb then
            CloseLoadingCb()
        end
    end

    function XFubenAssignManager.ShowReward(winData)
        -- 同步本地战斗后的关卡数据
        -- 关卡通关数据要先刷新，再在下一关for循环检测，最后再清除
        FinishStageIdDic[winData.StageId] = true
 
        -- if XFubenAssignManager.CheckIsGroupLastFinishStage(winData.StageId) then
        --     -- 本地挑战次数自增
        --     -- local groupId = XFubenAssignManager.GetGroupIdByStageId(winData.StageId)
        --     -- local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        --     -- groupData:SetFightCount(groupData:GetFightCount() + 1)
        --     if not groupData:GetIsPerfect() then
        --         -- if groupData:GetGroupRebootCount() <= 0 then
        --         --     groupData:SetIsPerfect(true)
        --         -- end
        --         groupData:ResetGroupRebootCount()
        --     end
        --     XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点
        --     XLuaUiManager.Remove("UiAssignLoading")
        --     XLuaUiManager.Open("UiAssignPostWarCount", winData)
        -- end
        
        local index = nil
        local targetNextStageId = nil
        local groupData = LoadingData.GroupData
        local chapterData = LoadingData.ChapterData
        local stageIdList =  groupData:GetStageId()
        for i = 1, #stageIdList, 1 do
            local stageId = stageIdList[i]
            if not XFubenAssignManager.CheckStageFinish(stageId) then
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
    
                local _, teamCharListOrg, captainPosList, firstFightPosList, generalSkillIdList = XFubenAssignManager.TryGetFightTeamCharList(groupData:GetId())
                local teamCharList = teamCharListOrg[index]
    
                XFubenAssignManager.SetEnterLoadingData(index, teamCharList, groupData, chapterData, isNextFight)
                XDataCenter.FubenManager.EnterAssignFight(targetNextStageId, teamCharList, captainPosList[index], nil, nil, firstFightPosList[index], generalSkillIdList[index])
            else
                local curIndex = 1
                for i = 1, #stageIdList, 1 do
                    local stageId = stageIdList[i]
                    if stageId == winData.StageId then
                        curIndex = i
                    end
                end
                XLuaUiManager.Open("UiAssignPostWarCount", winData, curIndex)
            end
        else
            -- 如果没有未完成的关了 说明group已经作战完毕 结算
            groupData:SetFightCount(groupData:GetFightCount() + 1)
            if not groupData:GetIsPerfect() then
                if groupData:GetGroupRebootCount() <= 0 then
                    groupData:SetIsPerfect(true)
                end
                groupData:ResetGroupRebootCount()
            end

            -- 并清除所有已完成的关卡数据
            for k, id in pairs(stageIdList) do
                FinishStageIdDic[id] = nil
            end

            -- 检测设置首通提示驻守trigger
            if groupData:GetFightCount() == 1 and groupData:IsLastGroup() then
                ChapterFirstPassTrigger = chapterData:GetId()
                XLuaUiManager.Remove("UiPanelAssignStage")
            end

            XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点
            XLuaUiManager.Remove("UiAssignLoading")
            XLuaUiManager.Remove("UiAssignDeploy")
            XLuaUiManager.Open("UiAssignPostWarCount", winData)
        end
    end
    ----------- 战斗接口 end-----------

    -- 某角色某技能加成
    function XFubenAssignManager.GetSkillLevel(characterId, skillId)
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        if not character then return 0 end

        local keys, levels = XFubenAssignManager.GetBuffKeysAndLevels()
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

    function XFubenAssignManager.GetSkillLevelByCharacterData(character, skillId, assignChapterRecords)
        local keys = {}
        local levels = {}
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = XAssignChapter.New(v.ChapterId)
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
    function XFubenAssignManager.GetBuffDescListByKeys(keys, levels)
        local descList = {}
        local GetCareerName = function (type) return XMVCA.XCharacter:GetCareerName(type) end
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

    function XFubenAssignManager.GetBuffKeysAndLevels()
        local keys = {}
        local levels = {}
        for _, id in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(id)
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

    function XFubenAssignManager.SortKeys(keys)
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

    function XFubenAssignManager.GetAllBuffList()
        local keys, levels = XFubenAssignManager.GetBuffKeysAndLevels()
        keys = XFubenAssignManager.SortKeys(keys)
        return XFubenAssignManager.GetBuffDescListByKeys(keys, levels)
    end

    function XFubenAssignManager.TryGetFightTeamCharList(groupId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        local teamList = {}
        local captainPosList = {}
        local firstFightPosList = {}
        local generalSkillIdList = {}
        local teamIdList = groupData:GetTeamInfoId()
        local allTeamHasMember = (#teamIdList > 0)
        for i, teamId in ipairs(teamIdList) do
            teamList[i] = {}
            local count = 0
            ---@type XTeam
            local teamData = XFubenAssignManager.GetTeamDataById(teamId)
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

    -- 刷新后面关卡的解锁信息
    function XFubenAssignManager.UnlockFollowGroupStage(preGroupId)
        local followGroupIdList = XFubenAssignManager.GetFollowGroupIdList(preGroupId)
        if not followGroupIdList then
            -- XLog.Debug(" 没有后置关卡id列表：" .. tostring(preGroupId))
            return
        end
        for _, followGroupId in ipairs(followGroupIdList) do
            local followGroupData = XFubenAssignManager.GetGroupDataById(followGroupId)
            followGroupData:SyncStageInfo()
        end
    end

    -- 获得后置关卡组
    function XFubenAssignManager.GetFollowGroupIdList(preGroupId)
        if not FollowGroupDict then
            XFubenAssignManager.InitFollowGroupDict()
        end
        local ids = FollowGroupDict[preGroupId]
        -- if not ids then
        -- XLog.Debug("前置关卡id无效：" .. tostring(preGroupId))
        -- end
        return ids
    end

    -- 初始化关卡组后置数据
    function XFubenAssignManager.InitFollowGroupDict()
        if not FollowGroupDict then
            FollowGroupDict = {}
            local GroupTemplates = XFubenAssignConfigs.GetGroupTemplates()
            local groupData
            for groupId, _ in pairs(GroupTemplates) do
                groupData = XFubenAssignManager.GetGroupDataById(groupId)
                local preGroupId = groupData:GetPreGroupId()
                if not FollowGroupDict[preGroupId] then
                    FollowGroupDict[preGroupId] = {}
                end
                table.insert(FollowGroupDict[preGroupId], groupId)
            end
        end
    end

    -- Login登录后端初始化数据接口
    function XFubenAssignManager.InitServerData(chapterRecords)
        XFubenAssignManager.UpdateChapterRecords(chapterRecords)
        XFubenAssignManager.InitFollowGroupDict()

        -- 有数据代表已经通关
        local chapterData
        for _, v in pairs(chapterRecords) do
            chapterData = XFubenAssignManager.GetChapterDataById(v.ChapterId)
            chapterData:SetIsPassByServer(true)
        end
        XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点
    end

    function XFubenAssignManager.UpdateChapterRecords(chapterRecords)
        if not chapterRecords then
            return
        end
        for _, v in pairs(chapterRecords) do
            local chapterData = XFubenAssignManager.GetChapterDataById(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)
            chapterData:SetRewarded(v.IsGetReward)
        end
    end

    -- 奖励红点
    function XFubenAssignManager.IsRewardRedPoint()
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:CanReward() then
                return true
            end
        end
        return false
    end

    function XFubenAssignManager.GetCharacterListInTeam(inTeamIdMap, charType)
        local ownCharacters = XMVCA.XCharacter:GetOwnCharacterList(charType)
        -- 排序 未编队>已编队  等级＞品质＞优先级
        local weights = {} -- 编队[1位] + 等级[3位] + 品质[1位] + 优先级[5位]
        for _, character in ipairs(ownCharacters) do
            local teamOrder = inTeamIdMap[character.Id]
            local stateOrder = teamOrder and (9 - teamOrder) or 9
            local priority = XMVCA.XCharacter:GetCharacterPriority(character.Id)
            local weightOrder = stateOrder * 1000000000
            local weightLevel = character.Level * 1000000
            local weightQuality = character.Quality * 100000
            local weightPriority = priority
            weights[character.Id] = weightOrder + weightLevel + weightQuality + weightPriority
        end
        table.sort(ownCharacters, function(a, b)
            return weights[a.Id] > weights[b.Id]
        end)
        return ownCharacters
    end

    -- 是否满足关卡所需战力
    function XFubenAssignManager.IsStagePass(stageId)
        local groupId = XFubenAssignManager.GetGroupIdByStageId(stageId)
        local groupData = XFubenAssignManager.GetGroupDataById(groupId)
        return groupData:IsPass()
    end

    function XFubenAssignManager.GetAccountEnterKey()
        return KeyAccountEnterAssign .. XPlayer.Id
    end

    -----------------协议----------
    function XFubenAssignManager.AssignGetDataRequest(cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignGetDataRequest, nil, function(res)
            local info = res.AssignInfo
            local chapterRecords = info.ChapterRecords -- 章节占领角色
            XFubenAssignManager.UpdateChapterRecords(chapterRecords)
            FinishStageIdDic = {}
            local groupRecords = info.GroupRecords -- 关卡组挑战次数
            for _, v in ipairs(groupRecords) do
                local groupData = XFubenAssignManager.GetGroupDataById(v.GroupId)
                groupData:SetFightCount(v.Count)
                groupData:SetIsPerfect(v.IsPerfect)
                if not XTool.IsTableEmpty(v.FinishStageIds) then
                    FinishStageIds = appendArray(FinishStageIds, v.FinishStageIds)
                    for k, id in pairs(v.FinishStageIds) do
                        -- 使用全局变量记录服务器发下来的数据
                        -- 已通关的StageId
                        FinishStageIdDic[id] = true
                    end
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENET_ASSIGN_CAN_REWARD) -- 刷新红点

            GroupTeamRecords = info.GroupTeamRecords -- 编队记录
            GroupTeamRecordsDic = {}
            for _, v in ipairs(GroupTeamRecords or {}) do
                local groupData = XFubenAssignManager.GetGroupDataById(v.GroupId)
                local teamCount = #v.TeamInfoList
                local posCount = v.CaptainPosList and #v.CaptainPosList or 0
                local firstFightCount = v.FirstFightPosList and #v.FirstFightPosList or 0

                for i, teamId in ipairs(groupData:GetTeamInfoId()) do
                    ---@type XTeam
                    local teamData = XFubenAssignManager.GetTeamDataById(teamId)
                    local charaterIds = (i <= teamCount) and v.TeamInfoList[i] or nil
                    local captainPos = (i <= posCount) and v.CaptainPosList[i] or XFubenAssignManager.CAPTIAN_MEMBER_INDEX
                    local firstFightPos = (i <= firstFightCount) and v.FirstFightPosList[i] or XFubenAssignManager.FIRSTFIGHT_MEMBER_INDEX
                    teamData:SetMemberList(charaterIds)
                    teamData:SetLeaderIndex(captainPos)
                    teamData:SetFirstFightIndex(firstFightPos)
                    teamData:UpdateSelectGeneralSkill(XFubenAssignManager.GetTeamGeneralSkillId(teamId), true)
                end
                -- 队伍字典
                GroupTeamRecordsDic[v.GroupId] = v
            end

            if cb then
                cb()
            end
        end)
    end

    function XFubenAssignManager.AssignSetTeamRequest(GroupId, TeamList, captainPosList, firstFightPosList, generalSkillIds, cb)
        XNetwork.Call(METHOD_NAME.AssignSetTeamRequest, { GroupId = GroupId, TeamList = TeamList, CaptainPosList = captainPosList, FirstFightPosList = firstFightPosList }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            --保存效应技能
            local groupData = XFubenAssignManager.GetGroupDataById(GroupId)
            for i, teamId in ipairs(groupData:GetTeamInfoId()) do
                XFubenAssignManager.SetTeamGeneralSkillId(teamId, generalSkillIds[i] or 0)
            end
            
            XFubenAssignManager.SaveTeamGeneralSkillDict()
            -- 设完队伍强制刷新下
            XFubenAssignManager.AssignGetDataRequest(cb)
        end)
    end

    function XFubenAssignManager.AssignSetCharacterRequest(ChapterId, CharacterId, cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignSetCharacterRequest, { ChapterId = ChapterId, CharacterId = CharacterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local chapterData = XFubenAssignManager.GetChapterDataById(ChapterId)
            chapterData:SetCharacterId(CharacterId)

            XEventManager.DispatchEvent(XEventId.EVENT_REFRESH_CHRACTER_ABLIITY) -- 重新计算角色战力
            XEventManager.DispatchEvent(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END) -- 刷新驻守界面
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END) -- 刷新驻守界面
            if cb then
                cb()
            end
        end)
    end
    function XFubenAssignManager.AssignGetRewardRequest(ChapterId, cb)
        -- if cb then cb() return end -- for testing
        XNetwork.Call(METHOD_NAME.AssignGetRewardRequest, { ChapterId = ChapterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chapterData = XFubenAssignManager.GetChapterDataById(ChapterId)
            chapterData:SetRewarded(true)
            XUiManager.OpenUiObtain(res.RewardList or {})
            if cb then
                cb()
            end
        end)
    end

    -- 重置关卡
    function XFubenAssignManager.AssignResetStageRequest(groupId, stageId, cb)
        XNetwork.Call(METHOD_NAME.AssignResetStageRequest, { GroupId = groupId, StageId = stageId }, function(res)
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

    function XFubenAssignManager.GetSkillPlusIdList()
        local list = {}
        for _, chapterId in ipairs(XFubenAssignManager.GetChapterIdList()) do
            local chapterData = XFubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    function XFubenAssignManager.GetSkillPlusIdListOther(assignChapterRecords)
        local list = {}
        if assignChapterRecords == nil then
            return list
        end
        for _, v in ipairs(assignChapterRecords) do
            local chapterData = XAssignChapter.New(v.ChapterId)
            chapterData:SetCharacterId(v.CharacterId)

            if chapterData:IsOccupy() then
                table.insert(list, chapterData:GetSkillPlusId())
            end
        end
        return list
    end

    -- 二选1 入口红点
    function XFubenAssignManager.CheckIsShowRedPoint()
        if XFubenAssignManager.IsRewardRedPoint() then
            return true
        end

        for k, chapterId in pairs(XFubenAssignManager.GetChapterIdList()) do
            local chapter =  XFubenAssignManager.GetChapterDataById(chapterId)
            if chapter:IsRed() then
                return true
            end
        end

        return false
    end
    ------------------副本入口扩展 start-------------------------
    
    -- 获取进度提示
    function XFubenAssignManager:ExGetProgressTip() 
        local str = ""
        -- if not self:ExGetIsLocked() then
        --     str = XFubenAssignManager.GetChapterProgressTxt()
        -- end
        local curr = XFubenAssignManager.GetAllChapterOccupyNum()
        local total = #XFubenAssignManager.GetChapterIdList()
        local textKeyName = "AssignOccupyProgress"
        if curr >= total then
            curr = XDataCenter.FubenAwarenessManager.GetAllChapterOccupyNum()
            total = #XDataCenter.FubenAwarenessManager.GetChapterIdList()
            textKeyName = "AwarenessCoverOccupyProgress"
        end
        str = CS.XTextManager.GetText(textKeyName, curr, total)
        return str
    end

    function XFubenAssignManager:ExCheckIsShowRedPoint()
        return XFubenAssignManager.CheckIsShowRedPoint() or XDataCenter.FubenAwarenessManager.CheckIsShowRedPoint()
    end

    function XFubenAssignManager.OpenUi(stageId)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAssign) then
            return
        end

        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Assign) then
            return
        end

        XLuaUiManager.Open("UiPanelAssignMain", stageId)
    end

    function XFubenAssignManager:ExOpenMainUi()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenAssign) then
            return
        end

        --分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Assign) then
            return
        end
        
        XLuaUiManager.Open("UiAssignAwarenessSelect")
    end
    
    ------------------副本入口扩展 end-------------------------
    -------------------------------
    XFubenAssignManager.Init()
    return XFubenAssignManager
end
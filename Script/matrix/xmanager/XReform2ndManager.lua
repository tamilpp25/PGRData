XReform2ndManagerCreator = function()
    local IPairs = ipairs
    local Pairs = pairs
    ---@class XReform2ndManager
    local XReform2ndManager = {}

    local XTeam = require("XEntity/XTeam/XTeam")
    local TeamDic = {}
    --local ChapterList = {}
    --local ChapterLength = 0    
    -- 是否已经发起进入请求，用来避免重复请求
    --local _IsEnterRequest = false

    local _KeyStage = nil
    local _KeySelect = nil
    local _KeyRedPoint = nil

    --local RequestProto = {
    --    RequestSave = "ReformEnemyRequest",
    --    EnterRequest = "FubenReformEnterRequest",
    --}

    --local XReform2ndData = require("XEntity/XReform2/XReform2ndData")
    --local XReform2ndChapter = require("XEntity/XReform2/XReform2ndChapter")
    ---@type XReform2ndData
    --local _Data = XReform2ndData.New()

    --function XReform2ndManager.InitWithServerData(data)
    --    _Data:SetData(data.ReformFubenDb)
    --end

    --function XReform2ndManager.GetHelpKey()
    --    return _Data:GetHelpKey1(), _Data:GetHelpKey2()
    --end

    --function XReform2ndManager.GetAvailableChapters()
    --    local result = {}
    --    if not XReform2ndManager.GetIsOpen() then
    --        return result
    --    end
    --    table.insert(result, {
    --        Id = _Data:GetActivityId(),
    --        Type = XDataCenter.FubenManager.ChapterType.Reform,
    --        Name = _Data:GetName(),
    --        Icon = _Data:GetIcon(),
    --    })
    --    return result
    --end

    --function XReform2ndManager.GetCurrentChapterNumber()
    --    return ChapterLength
    --end

    --function XReform2ndManager.GetChapterNumber()
    --    return #XReform2ndManager.GetChapterConfigs()
    --end

    ---@return XReform2ndChapter
    --function XReform2ndManager.GetChapterByIndex(index)
    --    local configs = XReform2ndManager.GetChapterConfigs()
    --    local i = 1
    --
    --    for id, _ in Pairs(configs) do
    --        if i == index then
    --            return XReform2ndManager.GetChapter(id)
    --        end
    --        
    --        i = i + 1
    --    end
    --    
    --    return nil
    --end

    ---@return XReform2ndChapter
    --function XReform2ndManager.GetChapter(chapterId)
    --    local chapter = ChapterList[chapterId]
    --
    --    if not chapter then
    --        chapter = XReform2ndChapter.New(chapterId)
    --        ChapterList[chapterId] = chapter
    --        ChapterLength = ChapterLength + 1
    --    end
    --    
    --    return chapter
    --end    

    ---@return XReform2ndStage
    --function XReform2ndManager.GetStage(stageId)
    --    return _Data:GetStage(stageId)
    --end

    ---@return XReform2ndStage[]
    --function XReform2ndManager.GetStageDic()
    --    return _Data:GetStageDic()
    --end

    --function XReform2ndManager.GetChapterConfigs()
    --    return XReform2ndConfigs.GetChapterConfig()
    --end

    --function XReform2ndManager.EnterRequest(callback)
    --    -- 避免重复请求
    --    if _IsEnterRequest then
    --        if callback then
    --            callback()
    --        end
    --        return
    --    end
    --    XNetwork.Call(RequestProto.EnterRequest, nil, function(res)
    --        if res.Code ~= XCode.Success then
    --            XUiManager.TipCode(res.Code)
    --            return
    --        end
    --        XReform2ndManager.InitWithServerData(res)
    --        _IsEnterRequest = true
    --        if callback then
    --            callback()
    --        end
    --    end)
    --end

    ---@param mobGroup XReform2ndMobGroup
    --function XReform2ndManager.RequestSave(mobGroup, callback)
    --    local mobArray = {}
    --    local stage = mobGroup:GetStage()
    --
    --    local groupId = mobGroup:GetGroupId()
    --    local amount = mobGroup:GetMobAmount()
    --    local enemyType = XReformConfigs.EnemyGroupType.NormanEnemy
    --    for i = 1, amount do
    --        local mob = mobGroup:GetMob(i)
    --        if mob then
    --            local sourceId = mobGroup:GetSourceId(i)
    --            local data = {}
    --            mobArray[#mobArray + 1] = data
    --            data.EnemyType = enemyType
    --            data.EnemyGroupId = groupId
    --            data.SourceId = sourceId
    --            data.TargetId = mob:GetId()
    --
    --            local affixData = {}
    --            local affixList = mob:GetAffixList()
    --            for j = 1, #affixList do
    --                local affix = affixList[j]
    --                affixData[#affixData + 1] = affix:GetId()
    --            end
    --            data.AffixSourceId = affixData
    --        end
    --    end
    --
    --    local stageId = stage:GetId()
    --    local difficultyIndex = stage:GetDifficultyIndex()
    --
    --    XNetwork.Call(RequestProto.RequestSave, {
    --        ReplaceIds = mobArray,
    --        EnemyGroupId = groupId,
    --        EnemyType = enemyType,
    --        StageId = stageId,
    --        DiffIndex = difficultyIndex,
    --    }, function(res)
    --        if res.Code ~= XCode.Success then
    --            XUiManager.TipCode(res.Code)
    --            return
    --        end
    --        if callback then
    --            callback()
    --        end
    --    end)
    --end

    function XReform2ndManager.GetTeam(stageId)
        local team = TeamDic[stageId]

        if not team then
            team = XTeam.New(XReform2ndManager.GetStageTeamKey(stageId))
            TeamDic[stageId] = team
        end

        return team
    end

    local function GetActivityId()
        return XMVCA.XReform:GetActivityId()
    end

    function XReform2ndManager.GetStageTeamKey(stageId)
        if not _KeyStage then
            _KeyStage = "Reform2_Stage_" .. GetActivityId() .. XPlayer.Id
        end
        return _KeyStage .. stageId
    end

    function XReform2ndManager.GetStageSelectKey()
        if not _KeySelect then
            _KeySelect = "Reform2_StageSelect_" .. GetActivityId() .. XPlayer.Id
        end

        return _KeySelect
    end

    function XReform2ndManager.GetChapterRedPointKey(chapterId)
        if not _KeyRedPoint then
            _KeyRedPoint = "Reform2_ChapterRedPoint_" .. GetActivityId() .. XPlayer.Id
        end

        return _KeyRedPoint .. chapterId
    end

    function XReform2ndManager.GetChapterRedPointFromLocal(chapterId, isHard)
        local difficulty = isHard and "Hard" or "Easy"
        local chapterRedPoint = XSaveTool.GetData(XReform2ndManager.GetChapterRedPointKey(chapterId) .. difficulty)
        return not chapterRedPoint
    end

    function XReform2ndManager.SetChapterRedPointToLocal(chapterId, isHard)
        local difficulty = isHard and "Hard" or "Easy"
        XSaveTool.SaveData(XReform2ndManager.GetChapterRedPointKey(chapterId) .. difficulty, true)
    end

    --function XReform2ndManager.GetRecommendRobotIdsByStageId(stageId)
    --    local groupId = XReform2ndConfigs.GetStageRecommendCharacterGroupIdById(stageId)
    --    local robotSourceIds = XReform2ndConfigs.GetMemberGroupSubIdsById(groupId)
    --    local robotIdList = {}
    --    local length = 0
    --
    --    for i = 1, #robotSourceIds do
    --        local robotId = XReform2ndConfigs.GetMemberSourceRobotIdById(robotSourceIds[i])
    --
    --        robotIdList[length + 1] = robotId
    --        length = length + 1
    --    end
    --
    --    return robotIdList
    --end

    --function XReform2ndManager.GetOwnCharacterListByStageId(stageId, characterType)
    --    local ownCharacterList = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    --    local robotList = XReform2ndManager.GetRecommendRobotIdsByStageId(stageId)
    --    local length = #ownCharacterList
    --
    --    for i = 1, #robotList do
    --        local robot = XRobotManager.GetRobotById(robotList[i])
    --        local viewModel = robot:GetCharacterViewModel()
    --        
    --        if viewModel:GetCharacterType() == characterType then
    --            ownCharacterList[length + 1] = robot
    --            length = length + 1
    --        end
    --    end
    --
    --    return ownCharacterList
    --end

    --function XReform2ndManager.SortEntitiesInStage(entities, stageId)
    --    local recommendList = XReform2ndManager.GetStageCharacterListByStageId(stageId)
    --
    --    table.sort(entities, function(entityA, entityB)
    --        local isARobot = XRobotManager.CheckIsRobotId(entityA:GetId())
    --        local isBRobot = XRobotManager.CheckIsRobotId(entityB:GetId())
    --
    --        if isARobot and isBRobot then
    --            return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
    --        elseif isARobot and not isBRobot then
    --            for i = 1, #recommendList do
    --                if recommendList[i] == entityB:GetId() then
    --                    return false
    --                end
    --            end
    --
    --            return true
    --        elseif (not isARobot) and isBRobot then
    --            for i = 1, #recommendList do
    --                if recommendList[i] == entityA:GetId() then
    --                    return true
    --                end
    --            end
    --
    --            return false
    --        else
    --            local isARecommend = false
    --            local isBRecommend = false
    --
    --            for i = 1, #recommendList do
    --                if recommendList[i] == entityA:GetId() then
    --                    isARecommend = true
    --                end
    --                if recommendList[i] == entityB:GetId() then
    --                    isBRecommend = true
    --                end
    --            end
    --
    --            if isARecommend and isBRecommend then
    --                return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
    --            elseif isARecommend and not isBRecommend then
    --                return true
    --            elseif (not isARecommend) and isBRecommend then
    --                return false
    --            else
    --                return entityA:GetCharacterViewModel():GetAbility() > entityB:GetCharacterViewModel():GetAbility()
    --            end
    --        end
    --    end)
    --
    --    return entities
    --end

    --function XReform2ndManager.GetRecommendDescByStageIdAndEntityId(stageId, entityId)
    --    if XRobotManager.CheckIsRobotId(entityId) then
    --        local robotIdList = XReform2ndManager.GetRecommendRobotIdsByStageId(stageId)
    --
    --        for i = 1, #robotIdList do
    --            if robotIdList[i] == entityId then
    --                local groupId = XReform2ndConfigs.GetStageRecommendCharacterGroupIdById(stageId)
    --
    --                return true, XReform2ndConfigs.GetMemberGroupRecommendDescById(groupId)
    --            end
    --        end
    --
    --        return false, nil
    --    else
    --        local characterIdList = XReform2ndManager.GetStageCharacterListByStageId(stageId)
    --
    --        for i = 1, #characterIdList do
    --            if characterIdList[i] == entityId then
    --                local groupId = XReform2ndConfigs.GetStageRecommendCharacterGroupIdById(stageId)
    --
    --                return true, XReform2ndConfigs.GetMemberGroupRecommendDescById(groupId)
    --            end
    --        end
    --
    --        return false, nil
    --    end
    --end

    --region 活动时间接口
    --function XReform2ndManager.GetIsOpen()
    --    local openTimeId = _Data:GetOpenTimeId()
    --    return XFunctionManager.CheckInTimeByTimeId(openTimeId)
    --end

    --function XReform2ndManager.GetActivityTime()
    --    local endTime = XFunctionManager.GetEndTimeByTimeId(_Data:GetOpenTimeId())
    --    local leftTime = endTime - XTime.GetServerNowTimestamp()
    --
    --    if leftTime < 0 then
    --        leftTime = 0
    --    end
    --
    --    return XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    --end

    --function XReform2ndManager.GetActivityEndTime()
    --    return XFunctionManager.GetEndTimeByTimeId(_Data:GetOpenTimeId())
    --end

    --function XReform2ndManager.HandleActivityEndTime()
    --    XLuaUiManager.RunMain()
    --    XUiManager.TipError(CS.XTextManager.GetText("ReformAtivityTimeEnd"))
    --end

    --function XReform2ndManager.GetActivityStartTime()
    --    return XFunctionManager.GetStartTimeByTimeId(_Data:GetOpenTimeId())
    --end
    --endregion

    --region 关卡进度相关
    --function XReform2ndManager.GetCurrentProgress()
    --    local stageDic = XReform2ndManager.GetStageDic()
    --    local progress = 0
    --
    --    for _, stage in Pairs(stageDic) do
    --        if stage:GetIsPassed() then
    --            progress = progress + 1
    --        end
    --    end
    --    
    --    return progress
    --end

    --function XReform2ndManager.GetMaxProgress()
    --    local chapterConfig = XReform2ndConfigs.GetChapterConfig()
    --    local progress = 0
    --
    --    for _, config in Pairs(chapterConfig) do
    --        progress = progress + #config.ChapterStageId
    --    end
    --    
    --    return progress
    --end
    --endregion

    function XReform2ndManager.RequestFinishTask(id, cb)
        XDataCenter.TaskManager.FinishTask(id, cb)
    end

    --function XReform2ndManager.GetStageCharacterListByStageId(stageId)
    --    return XReform2ndConfigs.GetStageRecommendCharacterIds(stageId)
    --end

    --region副本战斗接口
    function XReform2ndManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local rootStageId = XMVCA.XReform:GetRootStageId(stage.StageId)
        local team = XReform2ndManager.GetTeam(rootStageId)
        local robotIds = { 0, 0, 0 }
        local cardIds = { 0, 0, 0 }

        for i, sourceId in IPairs(team:GetEntityIds()) do
            if sourceId > 0 then
                if XRobotManager.CheckIsRobotId(sourceId) then
                    robotIds[i] = sourceId
                else
                    cardIds[i] = sourceId
                end
            end
        end

        local preFight = {
            StageId = stage.StageId,
            IsHasAssist = false,
            ChallengeCount = 1,
            RobotIds = robotIds,
            CardIds = cardIds,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos()
        }

        -- 效应
        if team.GetCurGeneralSkill then
            preFight.GeneralSkill = team:GetCurGeneralSkill()
        end

        return preFight
    end
    --endregion

    local _WinStageId = false
    local _IsFirstUnlockedHard = false
    local _PreChapterIndex = 1
    local _PreStageIndex = 1

    function XReform2ndManager.ShowReward(winData)
        local settleData = winData.SettleData
        local stageId = winData.StageId
        winData.StageId = XMVCA.XReform:GetRootStageId(stageId)
        if XMain.IsEditorDebug and stageId ~= winData.StageId then
            XLog.Error("[XReform2ndManager] 替换stageId", stageId)
        end
        local reformFightResult = settleData.ReformFightResult
        if reformFightResult then
            local pressure = winData.SettleData.ReformFightResult.Score
            local stage = XMVCA.XReform:GetStage(winData.StageId)
            local starNumber = XMVCA.XReform:GetStarByPressure(pressure, winData.StageId)
            local extraStar = reformFightResult.ExtraStar or 0

            if starNumber > stage:GetStarHistory(false) then
                stage:SetStarHistory(starNumber)
            end

            if not stage:IsExtraStar() then
                stage:SetExtraStar(extraStar > 0)
            end

            stage:SetIsPassed(true)

            --_IsFirstUnlockedHard = isUnlockDiff ~= XMVCA.XReform:GetIsUnlockedDifficulty(stage)
            _WinStageId = winData.StageId
        end

        XLuaUiManager.Remove("UiReformList")
        XLuaUiManager.Open("UiReformCombatSettleWin", winData, _IsFirstUnlockedHard)
    end

    function XReform2ndManager.IsUnlockHardModeStageId()
        local isFirstUnlock = _IsFirstUnlockedHard
        local winStageId = _WinStageId

        _WinStageId = false
        _IsFirstUnlockedHard = false

        return isFirstUnlock, winStageId, _PreChapterIndex, _PreStageIndex
    end

    function XReform2ndManager.SetPreIndex(chapterIndex, stageIndex)
        _PreChapterIndex = chapterIndex
        _PreStageIndex = stageIndex
    end

    --function XReform2ndManager.GetStarByPressure(pressure, stageId)
    --    return XReform2ndConfigs.GetStarByPressure(pressure, stageId)
    --end

    function XReform2ndManager:ExOverrideBaseMethod()
        return {
            ExGetProgressTip = function()
                return XUiHelper.GetText("ActivityBossSingleProcess", XMVCA.XReform:GetCurrentProgress(), XMVCA.XReform:GetMaxProgress())
            end
        }
    end

    return XReform2ndManager
end

--XRpc.NotifyReformFubenActivity = function(data)
--    XDataCenter.Reform2ndManager.InitWithServerData(data)
--end

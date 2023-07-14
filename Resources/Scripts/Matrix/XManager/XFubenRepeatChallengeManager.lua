XFubenRepeatChallengeManagerCreator = function()
    local pairs = pairs
    local tableInsert = table.insert
    local stringGsub = string.gsub

    local CurActivityId = XFubenRepeatChallengeConfigs.GetDefaultActivityId()
    local SelectDifficult = false --记录上次是否选中挑战难度
    local ChapterIdToPassedStageIdDic = {}  --章节Id-通关进度Dic
    local GotRewardIdCheckDic = {} -- 已领取奖励Id记录
    local NewChapterTipInfo = {} -- 新章节开启提示
    local StageIdToChapterId = {}
    local AddLevelTip -- 权限等级增加提示
    -- 活动等级信息
    local LevelInfo = {
        Level = 0,
        Exp = 0,
        DayExp = 0,
    }

    local XFubenRepeatChallengeManager = {}

    XFubenRepeatChallengeManager.ExCostItemId = CS.XGame.ClientConfig:GetInt("FubenRepeatChallengeExCostItemId")   --复刷关门票Id(展示用)
    XFubenRepeatChallengeManager.DifficultType = {
        Normal = 1,
        Difficult = 2,
    }

    function XFubenRepeatChallengeManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, XFubenRepeatChallengeManager.RefreshStagePassed)
    end

    function XFubenRepeatChallengeManager.InitStageInfo()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()

        for _, chapterId in pairs(config.NormalChapter) do
            local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
            for _, stageId in pairs(chapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.RepeatChallenge
                StageIdToChapterId[stageId] = chapterId
            end
        end

        for _, chapterId in pairs(config.HiddenChapter) do
            local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
            for _, stageId in pairs(chapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.RepeatChallenge
                StageIdToChapterId[stageId] = chapterId
            end
        end
    end
    
    function XFubenRepeatChallengeManager.GetChapterIdByStageId(stageId)
        return StageIdToChapterId[stageId]
    end

    function XFubenRepeatChallengeManager.ResetNewChapterTipInfo()
        NewChapterTipInfo = {}
    end

    function XFubenRepeatChallengeManager.GetNewChapterTipInfo()
        return NewChapterTipInfo
    end

    function XFubenRepeatChallengeManager.UpdateChapterGotRewardIds(rewardIds)
        GotRewardIdCheckDic = {}
        if not rewardIds then return end
        for _, rewardId in pairs(rewardIds) do
            GotRewardIdCheckDic[rewardId] = true
        end
    end

    function XFubenRepeatChallengeManager.UpdateChapterIdToPassedStageIdDic(chapterInfos)
        ChapterIdToPassedStageIdDic = {}

        if not chapterInfos then return end
        for _, chapterInfo in pairs(chapterInfos) do
            ChapterIdToPassedStageIdDic[chapterInfo.Id] = chapterInfo.FinishStages
        end

        XFubenRepeatChallengeManager.RefreshStagePassed()
    end

    local function RefreshStagePassedByChapterIds(chapterIds)
        for _, chapterId in pairs(chapterIds) do
            local passedStageIds = ChapterIdToPassedStageIdDic[chapterId]
            local schedule = passedStageIds and #passedStageIds or 0
            local chapterCfg = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
            for index, stageId in pairs(chapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if index <= schedule then
                    stageInfo.Passed = true
                else
                    stageInfo.Passed = false
                end

                if index <= schedule + 1 then
                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true
                else
                    stageInfo.IsOpen = false
                end
            end
        end
    end

    function XFubenRepeatChallengeManager.RefreshStagePassed()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        RefreshStagePassedByChapterIds(config.NormalChapter)
        RefreshStagePassedByChapterIds(config.HiddenChapter)
    end

    function XFubenRepeatChallengeManager.PassStage(stageId)
        local chapterId = XFubenRepeatChallengeConfigs.GetChapterIdByStageId(stageId)
        local chapterStagePassedInfo = ChapterIdToPassedStageIdDic[chapterId] or {}
        for _, existStageId in pairs(chapterStagePassedInfo) do
            if existStageId == stageId then
                return
            end
        end

        tableInsert(chapterStagePassedInfo, stageId)
        ChapterIdToPassedStageIdDic[chapterId] = chapterStagePassedInfo
        XFubenRepeatChallengeManager.RefreshStagePassed()
    end

    function XFubenRepeatChallengeManager.GetActivitySections()
        local sections = {}

        if XFubenRepeatChallengeManager.IsOpen() then
            local curId = XFubenRepeatChallengeManager.GetCurChapterId(XFubenRepeatChallengeManager.DifficultType.Normal)
            if not curId then
                XLog.Error("XFubenRepeatChallengeManager.GetActivitySections Error: 复刷关时间配置错误, 活动开启中但没有可用作战章节时间, 配置路径：" .. XFubenRepeatChallengeConfigs.GetChapterCfgPath())
                return sections
            end

            local section = {
                Id = curId,
                Type = XDataCenter.FubenManager.ChapterType.RepeatChallenge,
            }
            tableInsert(sections, section)
        end

        return sections
    end

    function XFubenRepeatChallengeManager.GetChapterId(difficultType, index)
        local chapterIds = XFubenRepeatChallengeManager.GetChapterIds(difficultType)
        return chapterIds[index]
    end

    function XFubenRepeatChallengeManager.GetChapterNum(difficultType)
        local chapterIds = XDataCenter.FubenRepeatChallengeManager.GetChapterIds(difficultType)
        return chapterIds and #chapterIds or 0
    end

    function XFubenRepeatChallengeManager.GetAllChapterIds()
        local allChapterIds = {}
        for _, difficultType in pairs(XFubenRepeatChallengeManager.DifficultType) do
            local chapterIds = XFubenRepeatChallengeManager.GetChapterIds(difficultType)
            for _, chapterId in pairs(chapterIds) do
                if chapterId ~= 0 then
                    tableInsert(allChapterIds, chapterId)
                end
            end
        end
        return allChapterIds
    end

    function XFubenRepeatChallengeManager.GetChapterIds(difficultType)
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return difficultType == XFubenRepeatChallengeManager.DifficultType.Difficult and config.HiddenChapter or config.NormalChapter
    end

    function XFubenRepeatChallengeManager.GetCurChapterIndex(difficultType)
        local curChapterIndex

        local chapterIds = XFubenRepeatChallengeManager.GetChapterIds(difficultType)
        if XFubenRepeatChallengeManager.IsStatusEqualFightEnd() then
            curChapterIndex = #chapterIds
        else
            for index, chapterId in ipairs(chapterIds) do
                curChapterIndex = XFubenRepeatChallengeManager.IsChapterUnlock(chapterId) and index or curChapterIndex
            end
        end

        return curChapterIndex
    end

    function XFubenRepeatChallengeManager.GetCurChapterId(difficultType)
        local curChapterIndex = XFubenRepeatChallengeManager.GetCurChapterIndex(difficultType)
        local chapterIds = XFubenRepeatChallengeManager.GetChapterIds(difficultType)
        return chapterIds[curChapterIndex]
    end

    function XFubenRepeatChallengeManager.GetChapterFinishCount(chapterId)
        local chapterPassedInfo = ChapterIdToPassedStageIdDic[chapterId]
        return chapterPassedInfo and #chapterPassedInfo or 0
    end

    function XFubenRepeatChallengeManager.GetActivityBeginTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetStartTimeByTimeId(config.ActivityTimeId)
    end

    function XFubenRepeatChallengeManager.GetActivityChallengeBeginTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetStartTimeByTimeId(config.ChallengeTimeId)
    end

    function XFubenRepeatChallengeManager.GetFightEndTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetEndTimeByTimeId(config.FightTimeId)
    end

    function XFubenRepeatChallengeManager.GetActivityEndTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetEndTimeByTimeId(config.ActivityTimeId)
    end

    function XFubenRepeatChallengeManager.GetActDescription()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return stringGsub(config.ActDescription, "\\n", "\n")
    end

    function XFubenRepeatChallengeManager.GetSelectDifficult()
        return SelectDifficult
    end

    function XFubenRepeatChallengeManager.SelectDifficult(selectDifficult)
        SelectDifficult = selectDifficult
    end

    function XFubenRepeatChallengeManager.GetLevel()
        return LevelInfo.Level
    end

    function XFubenRepeatChallengeManager.GetNextShowLevel()
        for i = LevelInfo.Level + 1, XFubenRepeatChallengeConfigs.GetMaxLevel() do
            local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(i)
            if levelConfig.NeedShow then return i end
        end
    end

    function XFubenRepeatChallengeManager.GetOriginExp()
        return LevelInfo.Exp
    end

    function XFubenRepeatChallengeManager.GetExp()
        local totalExp = LevelInfo.Exp
        local level = XFubenRepeatChallengeManager.GetLevel()
        for lv = 1, level - 1 do
            local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(lv)
            totalExp = totalExp - levelConfig.UpExp
        end
        return totalExp
    end

    function XFubenRepeatChallengeManager.GetDayExp()
        return LevelInfo.DayExp
    end

    function XFubenRepeatChallengeManager.GetSelectDifficult()
        return SelectDifficult
    end

    function XFubenRepeatChallengeManager.GetActivityConfig()
        return XFubenRepeatChallengeConfigs.GetActivityConfig(CurActivityId)
    end

    function XFubenRepeatChallengeManager.GetChapterRewardId(chapterId)
        local rewardConfig = XFubenRepeatChallengeConfigs.GetChapterRewardConfig(chapterId)
        return rewardConfig.RewardId
    end

    function XFubenRepeatChallengeManager.GetChapterBeginTime(chapterId)
        local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        return XFunctionManager.GetStartTimeByTimeId(chapterConfig.TimeId)
    end

    function XFubenRepeatChallengeManager.GetChapterEndTime(chapterId)
        local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        return XFunctionManager.GetEndTimeByTimeId(chapterConfig.TimeId)
    end

    function XFubenRepeatChallengeManager.GetBuffDes(buffId)
        local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
        return fightEventCfg and fightEventCfg.Description
    end

    function XFubenRepeatChallengeManager.IsLevelReach(checkLevel)
        local level = XFubenRepeatChallengeManager.GetLevel()
        return level >= checkLevel
    end

    function XFubenRepeatChallengeManager.IsBeforeChapterTime(chapterId)
        local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFunctionManager.GetStartTimeByTimeId(chapterConfig.TimeId)
        return now < beginTime
    end

    function XFubenRepeatChallengeManager.IsChapterUnlock(chapterId)
        local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFunctionManager.GetStartTimeByTimeId(chapterConfig.TimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(chapterConfig.TimeId)
        return beginTime <= now and now < endTime
    end

    function XFubenRepeatChallengeManager.IsStageFinished(stageId)
        return XFubenRepeatChallengeManager.IsChapterFinished(StageIdToChapterId[stageId])
    end

    function XFubenRepeatChallengeManager.IsChapterFinished(chapterId)
        local chapterConfig = XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(chapterConfig.TimeId)
        return now > endTime
    end

    function XFubenRepeatChallengeManager.IsStatusEqualFightEnd()
        local now = XTime.GetServerNowTimestamp()
        local fightEndTime = XFubenRepeatChallengeManager.GetFightEndTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return fightEndTime <= now and now < endTime
    end

    function XFubenRepeatChallengeManager.IsStatusEqualChallengeBegin()
        local now = XTime.GetServerNowTimestamp()
        local challengeBeginTime = XFubenRepeatChallengeManager.GetActivityChallengeBeginTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return challengeBeginTime <= now and now < endTime
    end

    function XFubenRepeatChallengeManager.IsOpen()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XFubenRepeatChallengeManager.GetActivityBeginTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XFubenRepeatChallengeManager.IsDifficultModeOpen()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        local conditionId = config.HideChapterConditionId
        if conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end
        return true
    end

    function XFubenRepeatChallengeManager.CheckPreFight(stage, challengeCount)
        if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
            XUiManager.TipText("ActivityRepeatChallengeOver")
            return false
        end

        if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
            XUiManager.TipText("ActivityRepeatChallengeOver")
            return false
        end

        local itemId, itemNum = XDataCenter.FubenManager.GetStageExCost(stage.StageId)
        if XDataCenter.ItemManager.GetCount(itemId) < itemNum * challengeCount then
            XUiManager.TipText("ActivityRepeatChallengeCostNotEnough")
            return false
        end

        return true
    end

    function XFubenRepeatChallengeManager.CheckChapterRewardCanGetReal(chapterId)
        if not XFubenRepeatChallengeManager.IsOpen() then return false end
        if XFubenRepeatChallengeManager.IsBeforeChapterTime(chapterId) then return false end

        local canGet = XFubenRepeatChallengeManager.CheckChapterRewardCanGet(chapterId)
        local hasGot = XFubenRepeatChallengeManager.CheckChapterRewardGot(chapterId)
        return canGet and not hasGot
    end

    function XFubenRepeatChallengeManager.CheckChapterRewardGot(chapterId)
        return GotRewardIdCheckDic[chapterId]
    end

    function XFubenRepeatChallengeManager.CheckChapterRewardCanGet(chapterId)
        local rewardConfig = XFubenRepeatChallengeConfigs.GetChapterRewardConfig(chapterId)
        local conditionId = rewardConfig.Condition
        if conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end
    end

    function XFubenRepeatChallengeManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityRepeatChallengeOver")
        XLuaUiManager.RunMain()
    end

    function XFubenRepeatChallengeManager.ShowReward(winData)
        if not winData then return end
        XFubenRepeatChallengeManager.PassStage(winData.StageId)
        XLuaUiManager.Open("UiRepeatChallengeSettleWin", winData, AddLevelTip)
    end

    function XFubenRepeatChallengeManager.NotifyRepeatChallengeData(data)
        CurActivityId = data.Id
        LevelInfo = data.ExpInfo
        XFubenRepeatChallengeManager.UpdateChapterGotRewardIds(data.RewardIds)
        XFubenRepeatChallengeManager.UpdateChapterIdToPassedStageIdDic(data.RcChapters)
    end

    function XFubenRepeatChallengeManager.UpdateLevelInfo(data)
        local oldExp = XFubenRepeatChallengeManager.GetOriginExp()
        local oldCurNormalChapterIndex = XFubenRepeatChallengeManager.GetCurChapterIndex(XFubenRepeatChallengeManager.DifficultType.Normal)
        local oldCurDifficultChapterIndex = XFubenRepeatChallengeManager.GetCurChapterIndex(XFubenRepeatChallengeManager.DifficultType.Difficult)
        LevelInfo = data.ExpInfo
        local newExp = XFubenRepeatChallengeManager.GetOriginExp()
        local newCurNormalChapterIndex = XFubenRepeatChallengeManager.GetCurChapterIndex(XFubenRepeatChallengeManager.DifficultType.Normal)
        local newCurDifficultChapterIndex = XFubenRepeatChallengeManager.GetCurChapterIndex(XFubenRepeatChallengeManager.DifficultType.Difficult)

        if oldCurNormalChapterIndex ~= newCurNormalChapterIndex then
            NewChapterTipInfo.OldIndex = oldCurNormalChapterIndex
            NewChapterTipInfo.NewIndex = newCurNormalChapterIndex
        elseif oldCurDifficultChapterIndex ~= newCurDifficultChapterIndex then
            NewChapterTipInfo.OldIndex = oldCurDifficultChapterIndex
            NewChapterTipInfo.NewIndex = newCurDifficultChapterIndex
        end

        local addExp = newExp - oldExp
        if addExp > 0 then
            AddLevelTip = addExp
        end
    end

    function XFubenRepeatChallengeManager.ClearAddLevelTip()
        AddLevelTip = nil
    end

    function XFubenRepeatChallengeManager.RequesetGetReward(chapterId, cb)
        if not chapterId or chapterId == 0 then return end
        XNetwork.Call("RepeatChallengeRewardRequest", { Id = chapterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            GotRewardIdCheckDic[chapterId] = true

            if cb then cb(res.RewardGoodsList) end
        end)
    end

    XFubenRepeatChallengeManager.Init()
    return XFubenRepeatChallengeManager
end

XRpc.NotifyRepeatChallengeData = function(data)
    XDataCenter.FubenRepeatChallengeManager.NotifyRepeatChallengeData(data)
end

XRpc.NotifyRcExpChange = function(data)
    XDataCenter.FubenRepeatChallengeManager.UpdateLevelInfo(data)
end
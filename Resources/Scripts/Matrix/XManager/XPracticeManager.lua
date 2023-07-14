XPracticeManagerCreator = function()
    local XPracticeManager = {}
    local PracticeChapterInfos = {}
    local PracticeStageInfo = {}

    function XPracticeManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, XPracticeManager.RefreshStagePassed)
    end

    function XPracticeManager.InitStageInfo()
        local allPracticeChapters = XPracticeConfigs.GetPracticeChapters()
        for _, chapter in pairs(allPracticeChapters) do
            for _, stageId in pairs(chapter.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.Practice
                end
            end
        end
        XPracticeManager.RefreshStagePassed()
    end

    function XPracticeManager.ShowReward(winData)
        if not winData then return end
        XPracticeManager.RefreshStagePassedBySettleDatas(winData.SettleData)

        XLuaUiManager.Open("UiSettleWin", winData)
    end

    function XPracticeManager.CheckPracticeStageOpen(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        if not stageInfo.Unlock then return false, CS.XTextManager.GetText("FubenNotUnlock") end

        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            return false, CS.XTextManager.GetText("TeamLevelToOpen", stageCfg.RequireLevel)
        end

        local actInfo = XPracticeConfigs.GetPracticeActivityInfo(stageId)
        local condition = {}
        if XPracticeManager.CheckStageInActivity(stageId) then
            condition = actInfo.ActivityCondition
        elseif actInfo then
            condition = actInfo.OpenCondition
        end

        for _, conditionId in pairs(condition or {}) do
            local ret, desc = XConditionManager.CheckCondition(conditionId)
            if not ret then
                return false, desc
            end
        end
        return true
    end

    function XPracticeManager.GetSortedChapterStage(chapterId)
        local stageIds = XPracticeConfigs.GetPracticeChapterById(chapterId).StageId
        local sortedNodes = {}
        for _, stageId in pairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local isOpen = XPracticeManager.CheckPracticeStageOpen(stageId)
            local inActivity = XPracticeManager.CheckStageInActivity(stageId)
            local weight
            if stageInfo.Passed then
                -- 已通关
                weight = 3
            elseif isOpen then
                -- 可打未通过
                weight = 1
            else
                -- 未解锁
                weight = 2
            end
            table.insert(sortedNodes, {
                StageId = stageId,
                InActivity = inActivity,
                Weight = weight
            })
        end
        table.sort(sortedNodes, function(nodeA, nodeB)
            if nodeA.InActivity ~= nodeB.InActivity then
                return nodeA.InActivity and not nodeB.InActivity
            end
            if nodeA.Weight == nodeB.Weight then
                return nodeA.StageId < nodeB.StageId
            else
                return nodeA.Weight < nodeB.Weight
            end
        end)
        return sortedNodes
    end

    -- 已解锁
    function XPracticeManager.CheckPracticeStageIsUnlock(stageId)
        return PracticeStageInfo[stageId] or false
    end

    -- 进度是否完成
    --function XPracticeManager.IsPracticeStageFinish(chapterId, stageId)
    --    local practiceDatas = PracticeChapterInfos[chapterId]
    --    if not practiceDatas then return false end
    --    for _, finishStageId in pairs(practiceDatas) do
    --        if finishStageId == stageId then
    --            return true
    --        end
    --    end
    --    return false
    --end

    -- 是否处于活动期间
    function XPracticeManager.CheckStageInActivity(stageId)
        local actInfo = XPracticeConfigs.GetPracticeActivityInfo(stageId)
        if actInfo and actInfo.ActivityTimeId and
                XFunctionManager.CheckInTimeByTimeId(actInfo.ActivityTimeId) then
            return true
        else
            return false
        end
    end

    function XPracticeManager.RefreshStagePassedBySettleDatas(settleData)
        if not settleData then return end

        local allPracticeChapters = XPracticeConfigs.GetPracticeChapters()
        local chapterId = 0
        for id, chapter in pairs(allPracticeChapters) do
            for _, stageId in pairs(chapter.StageId) do
                if stageId == settleData.StageId then
                    chapterId = id
                    break
                end
            end
            if chapterId ~= 0 then
                if not PracticeChapterInfos[chapterId] then
                    PracticeChapterInfos[chapterId] = {}
                end
                PracticeChapterInfos[chapterId][settleData.StageId] = true
                PracticeStageInfo[settleData.StageId] = true
                XPracticeManager.RefreshStagePassed()
                XEventManager.DispatchEvent(XEventId.EVENT_PRACTICE_ON_DATA_REFRESH)
                break
            end
        end
    end

    function XPracticeManager.RefreshStagePassed()
        local allPracticeChapters = XPracticeConfigs.GetPracticeChapters()
        for _, chapter in pairs(allPracticeChapters) do
            for _, stageId in pairs(chapter.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                    stageInfo.Passed = PracticeStageInfo[stageId] or false

                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                    end
                    for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                        if prestageId > 0 then
                            if not PracticeStageInfo[prestageId] then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end

                end
            end
        end
    end


    -- 同步数据
    function XPracticeManager.OnAsyncPracticeData(chapterInfos)
        if not chapterInfos then return end
        for _, v in pairs(chapterInfos) do
            if not PracticeChapterInfos[v.Id] then
                PracticeChapterInfos[v.Id] = {}
            end
            for _, stageId in pairs(v.FinishStages or {}) do
                PracticeChapterInfos[v.Id][stageId] = true
                PracticeStageInfo[stageId] = true
            end
        end

        XPracticeManager.RefreshStagePassed()
    end

    XPracticeManager.Init()
    return XPracticeManager
end

XRpc.NotifyPracticeData = function(response)
    if not response then return end
    XDataCenter.PracticeManager.OnAsyncPracticeData(response.ChapterInfos)
end

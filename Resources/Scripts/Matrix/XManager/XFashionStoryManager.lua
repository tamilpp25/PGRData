XFashionStoryManagerCreator = function()
    local XFashionStoryManager = {}
    local PassedStage = {}

    
    -------------------------------------------------------副本相关------------------------------------------------------

    function XFashionStoryManager.InitStageInfo()
        local allFashionStoryId = XFashionStoryConfigs.GetAllFashionStoryId()
        for _, chapterId in pairs(allFashionStoryId) do
            local stageIdList = XFashionStoryConfigs.GetAllStageId(chapterId)
            for i, stageId in ipairs(stageIdList) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.FashionStory
                stageInfo.OrderId = i
            end
        end
        XFashionStoryManager.RefreshStageInfo()
    end

    function XFashionStoryManager.ShowReward(winData)
        if not winData then
            return
        end
        XFashionStoryManager.RefreshStagePassedBySettleData(winData.SettleData)

        XLuaUiManager.Open("UiSettleWin", winData)
    end
    --------------------------------------------------------------------------------------------------------------------

    
    ---
    --- 获取'id'系列涂装剧情活动的开始时间戳与结束时间戳
    ---@return number 开始时间戳|结束时间戳
    function XFashionStoryManager.GetActivityTime(id)
        local timeId = XFashionStoryConfigs.GetActivityTimeId(id)
        return XFunctionManager.GetTimeByTimeId(timeId)
    end

    ---
    --- 获取系列涂装剧情活动
    function XFashionStoryManager.GetActivityChapters(noNeedInTime)
        local chapter = {}
        local allFashionStoryId = XFashionStoryConfigs.GetAllFashionStoryId()
        for _, id in pairs(allFashionStoryId) do
            if noNeedInTime or XFashionStoryManager.IsActivityInTime(id)  then
                table.insert(chapter, {
                    Id = id,
                    Type = XDataCenter.FubenManager.ChapterType.FashionStory,
                    Name = XFashionStoryConfigs.GetName(id),
                    Icon = XFashionStoryConfigs.GetActivityBannerIcon(id)
                })
            end
        end
        return chapter
    end

    ---
    --- 获取'id'活动中处于开放时间的试玩关
    function XFashionStoryManager.GetActiveTrialStage(id)
        local result = {}
        local trialStageList = XFashionStoryConfigs.GetTrialStagesList(id)
        if trialStageList then
            for _, trialStage in ipairs(trialStageList) do
                if XFashionStoryManager.IsTrialStageInTime(trialStage) then
                    table.insert(result, trialStage)
                end
            end
        end
        return result
    end

    ---
    --- 获取活动的类型
    function XFashionStoryManager.GetType(id)
        local chapterStageList = XFashionStoryConfigs.GetChapterStagesList(id)
        local trialStageList = XFashionStoryConfigs.GetTrialStagesList(id)
        if XTool.IsTableEmpty(chapterStageList) then
            return XFashionStoryConfigs.Type.OnlyTrial
        elseif XTool.IsTableEmpty(trialStageList) then
            return XFashionStoryConfigs.Type.OnlyChapter
        else
            return XFashionStoryConfigs.Type.Both
        end
    end

    ---
    --- 获取活动章节关的关卡进度
    function XFashionStoryManager.GetChapterProgress(id)
        local stageIdList = XFashionStoryConfigs.GetChapterStagesList(id)
        local passNum = 0
        local totalNum = #stageIdList

        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Passed then
                passNum = passNum + 1
            end
        end
        return passNum, totalNum
    end

    ---
    --- 获取活动的剩余时间戳
    function XFashionStoryManager.GetLeftTimeStamp(id)
        local _, endTime = XFashionStoryManager.GetActivityTime(id)
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
    end

    ---
    --- 获取试玩关关卡剩余时间戳
    function XFashionStoryManager.GetTrialStageLeftTimeStamp(stageId)
        local timeId = XFashionStoryConfigs.GetStageTimeId(stageId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
    end

    ---
    --- 获取剧情关入口的剩余时间戳
    function XFashionStoryManager.GetStoryTimeStamp(id)
        local timeId = XFashionStoryConfigs.GetStoryTimeId(id)
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
    end

    ---
    --- 判断试玩关关卡是否处于开放时间，无时间配置默认不开放
    function XFashionStoryManager.IsTrialStageInTime(stageId)
        local stageTimeId = XFashionStoryConfigs.GetStageTimeId(stageId)
        return XFunctionManager.CheckInTimeByTimeId(stageTimeId, false)
    end

    ---
    --- 打开活动主界面
    function XFashionStoryManager.OpenFashionStoryMain(activityId)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FashionStory) then
            return
        end
        if XFashionStoryManager.IsActivityInTime(activityId) then
            XLuaUiManager.Open("UiFubenFashionStory", activityId)
        else
            XUiManager.TipMsg(CSXTextManagerGetText("FashionStoryActivityEnd"))
        end
    end

    ---
    --- 'activityId'是否处于开启时间
    function XFashionStoryManager.IsActivityInTime(activityId)
        local timeId = XFashionStoryConfigs.GetActivityTimeId(activityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId, false)
    end

    ---
    --- 剧情模式入口是否处于开启时间
    function XFashionStoryManager.IsStoryInTime(activityId)
        local timeId = XFashionStoryConfigs.GetStoryTimeId(activityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId, false)
    end

    ---
    --- 刷新关卡通关信息
    function XFashionStoryManager.RefreshStagePassedBySettleData(settleData)
        if not settleData then
            return
        end
        PassedStage[settleData.StageId] = true
        XFashionStoryManager.RefreshStageInfo()
    end

    ---
    --- 刷新StageInfo数据
    function XFashionStoryManager.RefreshStageInfo()
        local allFashionStoryId = XFashionStoryConfigs.GetAllFashionStoryId()
        for _, chapterId in pairs(allFashionStoryId) do
            local allStageId = XFashionStoryConfigs.GetAllStageId(chapterId)
            for _, stageId in pairs(allStageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                    stageInfo.Passed = PassedStage[stageId] or false
                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true
                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                    end
                    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not PassedStage[preStageId] then
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


    ----------------------------------------------同步服务器推送数据--------------------------------------------------------

    ---
    --- 同步关卡通关数据
    function XFashionStoryManager.SyncStageData(stageData)
        if not stageData then
            return
        end
        for _, stageId in pairs(stageData or {}) do
            PassedStage[stageId] = true
        end
        XFashionStoryManager.RefreshStageInfo(stageData)
    end
    --------------------------------------------------------------------------------------------------------------------
    
    
    return XFashionStoryManager
end

XRpc.NotifyFashionStoryData = function(data)
    XDataCenter.FashionStoryManager.SyncStageData(data.FinishStageList)
end
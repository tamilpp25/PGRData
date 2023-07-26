local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")

XFashionStoryManagerCreator = function()
    local XFashionStoryManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.FashionStory, "FashionStoryManager")
    local PassedStage = {}
    local currentActivityId=nil
    local StageGroupMap={} --Key:StageId Value: SingleLineId
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
        XFashionStoryManager.InitStageGroupMap()
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
        local currentId=XFashionStoryManager.GetCurrentActivityId()
        --判断活动类型
        table.insert(chapter, {
                Id = currentId,
                Type = XDataCenter.FubenManager.ChapterType.FashionStory,
            })

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
        --2.6新表兼容旧逻辑
        local stageCount=0
        local trialCount=0
        
        local singleLineId=XFashionStoryConfigs.GetFirstSingleLine(id)
        if singleLineId then
            stageCount=XFashionStoryConfigs.GetSingleLineStagesCount(singleLineId)
        end
        trialCount=XFashionStoryConfigs.GetFashionStoryTrialStageCount(id)
        if stageCount==0 then
            return XFashionStoryConfigs.Type.OnlyTrial
        elseif trialCount==0 then
            return XFashionStoryConfigs.Type.OnlyChapter
        else
            return XFashionStoryConfigs.Type.Both
        end
    end

    ---
    --- 获取活动章节关的关卡进度

    function XFashionStoryManager.GetChapterProgress(id)
        if XFashionStoryConfigs.GetPrefabType(id)==XFashionStoryConfigs.PrefabType.Old then
            --旧版
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
        else
            --新版
            local singleLineIds=XFashionStoryConfigs.GetSingleLines(id)
            local groupPass=0
            for i, singleLineId in ipairs(singleLineIds) do
                local stages=XFashionStoryConfigs.GetSingleLineStages(singleLineId)
                local passNum=XFashionStoryManager.GetGroupStagesPassCount(stages)
                if passNum>=#stages then
                    groupPass=groupPass+1
                end
            end
            return groupPass,#singleLineIds
        end
        
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
        currentActivityId=activityId
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FashionStory) then
            return
        end
        if XFashionStoryManager.IsActivityInTime(activityId) then
            if XFashionStoryManager.CheckIsGroupTypeActivity(activityId) then
                XLuaUiManager.Open("UiFubenFashionStoryNew")
            else
                XLuaUiManager.Open("UiFubenFashionStory", activityId,nil,XFashionStoryConfigs.GetFirstSingleLine(activityId))
            end
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
        --2.6兼容旧版逻辑
        local singleLineId=XFashionStoryConfigs.GetFirstSingleLine(activityId)
        local timeId = XFashionStoryConfigs.GetSingleLineTimeId(singleLineId)
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

    ----------------------------------------------限时活动接口------------------------------------------------------------

    function XFashionStoryManager:ExGetProgressTip()
        local activeChapter = XFashionStoryManager.GetActivityChapters()
        -- 默认取第一个活动的Id
        -- 如果有多个活动同时开启，这里需要处理
        local curActivity = activeChapter[1].Id
        local passNum, totalNum = XFashionStoryManager.GetChapterProgress(curActivity)
        return XUiHelper.GetText("FashionStoryProcess", passNum, totalNum)
    end

    --------------------------------------------------------------------------------------------------------------------

    
    --region 2.6 关卡分组的新逻辑
    
    --初始化关卡-关卡组映射
    function XFashionStoryManager.InitStageGroupMap()
        if not XTool.IsTableEmpty(StageGroupMap) then return end
        --获取所有组
        local allSingleLines=XFashionStoryConfigs.GetSingleLines(XFashionStoryManager.GetCurrentActivityId())
        for i, singleLineId in ipairs(allSingleLines) do
            local ChapterStages=XFashionStoryConfigs.GetSingleLineStages(singleLineId)
            --遍历每个组的关卡
            for j,stage in ipairs(ChapterStages) do
                StageGroupMap[stage]=singleLineId
            end
        end
    end
    
    --确定当前活动是否是分组类型（不是则是原类型）
    function XFashionStoryManager.CheckIsGroupTypeActivity(activityId)
        local type=XFashionStoryConfigs.GetPrefabType(activityId)
        return type==XFashionStoryConfigs.PrefabType.Group
    end
    
    --获取当期活动的Id
    function XFashionStoryManager.GetCurrentActivityId()
        if currentActivityId then
            return currentActivityId
        else
            return CS.XGame.Config:GetInt("FashionStoryCurrentActivityId")
        end
    end
    
    --获取传入的关卡组中完成的关卡的数量
    function XFashionStoryManager.GetGroupStagesPassCount(stages)
        local count=0
        for i, stage in ipairs(stages) do
            if XDataCenter.FubenManager.CheckStageIsPass(stage) then
                count=count+1
            end
        end
        return count
    end
    
    --判断当前关卡组是否在解锁时间内
    function XFashionStoryManager.CheckSingleLineIsInTime(singleLineId)
        local storyTimeId=XFashionStoryConfigs.GetSingleLineTimeId(singleLineId)
        return XFunctionManager.CheckInTimeByTimeId(storyTimeId,false)
    end
    
    --判断指定关卡组是否可以解锁：关卡组本身解锁&第一关解锁
    function XFashionStoryManager.CheckGroupIsCanOpen(singleLineId)
        local lockReason=nil
        local firstStageOpen=false
        local firstStageUnOpenReason=nil
        
        local firstStageId=XFashionStoryConfigs.GetSingleLineFirstStage(singleLineId)
        if firstStageId then
            firstStageOpen,firstStageUnOpenReason=XFashionStoryManager.CheckFashionStoryStageIsOpen(firstStageId)
        end
        
        local selfIsInTime=XFashionStoryManager.CheckSingleLineIsInTime(singleLineId)
        

        if not selfIsInTime then
            lockReason=XFashionStoryConfigs.GroupUnOpenReason.OutOfTime
        elseif firstStageOpen==false then
            if firstStageUnOpenReason==XFashionStoryConfigs.TrialStageUnOpenReason.OutOfTime then
                lockReason=XFashionStoryConfigs.GroupUnOpenReason.OutOfTime
            elseif firstStageUnOpenReason==XFashionStoryConfigs.TrialStageUnOpenReason.PreStageUnPass then
                lockReason=XFashionStoryConfigs.GroupUnOpenReason.PreGroupUnPass
            end
        end
        
        return selfIsInTime and firstStageOpen,lockReason
    end
    
    --获取当期活动的所有任务
    function XFashionStoryManager.GetCurrentAllTask(activityId)
        local taskLimitId=XFashionStoryConfigs.GetTaskLimitId(activityId)
        local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
        local taskList= { }
        for _, taskId in ipairs(taskCfg.TaskId) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData then
                table.insert(taskList,taskData)
            end
        end
        
        return taskList
    end
    
    --获取当期活动的所有试玩关
    function XFashionStoryManager.GetCurrentAllTrialStageData()
        local idList=XFashionStoryConfigs.GetFashionStoryTrialStages(XFashionStoryManager.GetCurrentActivityId())
        
    end
   
   --判断指定试玩关是否解锁
    function XFashionStoryManager.CheckFashionStoryStageIsOpen(trialId)
        local timeId=XFashionStoryConfigs.GetStageTimeId(trialId)
        if timeId==0 or XFunctionManager.CheckInTimeByTimeId(timeId,false) then
            local preStage=XFashionStoryConfigs.GetPreStageId(trialId)
            if preStage==0 or XDataCenter.FubenManager.CheckStageIsPass(preStage) then
                return true
            else
                return false,XFashionStoryConfigs.TrialStageUnOpenReason.PreStageUnPass
            end
        else
            return false,XFashionStoryConfigs.TrialStageUnOpenReason.OutOfTime
        end
    end
    
    --检查指定关卡组是否已查看过
    function XFashionStoryManager.CheckGroupHadAccess(singleLineId)
        local fullKey=XFashionStoryConfigs.GetGroupNewFullKey(singleLineId)
        if XSaveTool.GetData(fullKey) then
            return true
        else
            return false
        end
    end
    
    function XFashionStoryManager.MarkGroupAsHadAccess(singleLineId)
        local fullKey=XFashionStoryConfigs.GetGroupNewFullKey(singleLineId)
        if not XSaveTool.GetData(fullKey) then
            XSaveTool.SaveData(fullKey,true)
        end
    end
    
    --检查是否存在关卡组未查看过
    function XFashionStoryManager.CheckIfAnyGroupUnAccess()
        local singleLines=XFashionStoryConfigs.GetSingleLines(XFashionStoryManager.GetCurrentActivityId())
        if not XTool.IsTableEmpty(singleLines) then
            for i, singleLine in ipairs(singleLines) do
                --解锁&未查看过
                if XDataCenter.FashionStoryManager.CheckGroupIsCanOpen(singleLine) and not XFashionStoryManager.CheckGroupHadAccess(singleLine) then
                    return true
                end
            end
        end
        return false
    end
    
    function XFashionStoryManager.GetPreSingleLineId(singleLineId)
        --获取第一个关卡
        local firstStage=XFashionStoryConfigs.GetSingleLineFirstStage(singleLineId)
        --获取该关卡的前置关卡
        local preStage=XFashionStoryConfigs.GetPreStageId(firstStage)

        if preStage then
            --读取组Id
            return StageGroupMap[preStage]
        end
    end
    
    function XFashionStoryManager.EnterPaintingGroupPanel(singleLineId,isOpen,lockReason,callback)
        if singleLineId then
            if isOpen then
                if callback then
                    callback()
                else
                    XLuaUiManager.Open("UiFubenFashionPaintingNew",singleLineId)
                    XDataCenter.FashionStoryManager.MarkGroupAsHadAccess(singleLineId)
                end
            else
                if lockReason==XFashionStoryConfigs.GroupUnOpenReason.OutOfTime then
                    XUiManager.TipText("FashionStoryGroupOutTime")
                elseif lockReason==XFashionStoryConfigs.GroupUnOpenReason.PreGroupUnPass then
                    local preGroupId=XDataCenter.FashionStoryManager.GetPreSingleLineId(singleLineId)
                    if preGroupId then
                        XUiManager.TipText("FashionStoryGroupPassTip",nil,nil,XFashionStoryConfigs.GetSingleLineName(preGroupId))
                    end
                end
            end
        end
    end
    --endregion
    
    return XFashionStoryManager
end

XRpc.NotifyFashionStoryData = function(data)
    XDataCenter.FashionStoryManager.SyncStageData(data.FinishStageList)
end
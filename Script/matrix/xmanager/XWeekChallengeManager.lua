XWeekChallengeManagerCreator = function()
    ---@class XWeekChallengeManager
    local XWeekChallengeManager = {}
    local BaseInfo = require("XEntity/XWeekChallenge/XWeekChallengeInfo").New()

    XWeekChallengeManager.IsOpen = function()
        local FunctionId = XFunctionManager.FunctionName.WeekChallenge
        if not XFunctionManager.JudgeCanOpen(FunctionId) then
            return false
        end
        local timelimitID = XWeekChallengeConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
        return XFunctionManager.CheckInTimeByTimeId(timelimitID)
    end

    XWeekChallengeManager.GetWeekIndex = function()
        local taskGroupIdArray = XWeekChallengeConfigs.GetTaskGroupIdArray(BaseInfo:GetActivityId())
        local weekIndex = 1
        for i = 1, #taskGroupIdArray do
            if XWeekChallengeManager.GetWeekState(i) == XWeekChallengeConfigs.WeekState.Opened then
                weekIndex = i
            end
        end
        return weekIndex
    end

    XWeekChallengeManager.GetWeekAmount = function()
        return XWeekChallengeConfigs.GetWeekAmount(BaseInfo:GetActivityId())
    end

    XWeekChallengeManager.GetTaskIdArray = function(weekIndex)
        return XWeekChallengeConfigs.GetTaskIdGroup(BaseInfo:GetActivityId(), weekIndex)
    end

    function XWeekChallengeManager.IsThisWeekAllTaskFinished(weekIndex)
        local taskIdList = XWeekChallengeManager.GetTaskIdArray(weekIndex)
        local taskDataList = {}
        for i = 1, #taskIdList do
            local taskId = taskIdList[i]
            if not XWeekChallengeManager.IsTaskFinished(taskId) then
                return false
            end
        end
        return true
    end

    XWeekChallengeManager.GetTaskDataArraySorted = function(weekIndex)
        local taskIdList = XWeekChallengeManager.GetTaskIdArray(weekIndex)
        local taskDataList = {}
        for i = 1, #taskIdList do
            local taskId = taskIdList[i]
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData then
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    -- 将 已完成未提交的任务 伪装成 已提交的任务
                    taskData = XTool.Clone(taskData)
                    taskData.State = XDataCenter.TaskManager.TaskState.Finish
                end
                taskDataList[#taskDataList + 1] = taskData
            end
        end
        table.sort(
            taskDataList,
            function(a, b)
                local priority1 = XWeekChallengeManager.IsTaskFinished(a.Id) and 0 or 1
                local priority2 = XWeekChallengeManager.IsTaskFinished(b.Id) and 0 or 1
                if priority1 == priority2 then
                    priority1 = XTaskConfig.GetPriority(a.Id)
                    priority2 = XTaskConfig.GetPriority(b.Id)
                end
                if priority1 == priority2 then
                    priority1 = a.Id
                    priority2 = b.Id
                end
                return priority1 > priority2
            end
        )
        return taskDataList
    end

    XWeekChallengeManager.GetWeekState = function(weekIndex)
        local timelimitID = XWeekChallengeConfigs.GetWeekTimeLimitId(BaseInfo:GetActivityId(), weekIndex)
        if timelimitID and XFunctionManager.CheckInTimeByTimeId(timelimitID) then
            return XWeekChallengeConfigs.WeekState.Opened
        end
        return XWeekChallengeConfigs.WeekState.Lock
    end

    XWeekChallengeManager.TipWeekLock = function(weekIndex)
        local timelimitID = XWeekChallengeConfigs.GetWeekTimeLimitId(BaseInfo:GetActivityId(), weekIndex)
        local startTime = XFunctionManager.GetStartTimeByTimeId(timelimitID)
        XUiManager.TipError(XTime.TimestampToGameDateTimeString(startTime, XUiHelper.GetText("WeekChallengeLock")))
    end

    XWeekChallengeManager.GetActivityRemainSeconds = function()
        local timelimitID = XWeekChallengeConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
        local endTime = XFunctionManager.GetEndTimeByTimeId(timelimitID)
        local currentTime = XTime.GetServerNowTimestamp()
        local remainSeconds = math.max(0, endTime - currentTime)
        return remainSeconds
    end

    XWeekChallengeManager.GetNumberOfCompletedTasks = function()
        local weekAmount = XWeekChallengeConfigs.GetWeekAmount(BaseInfo:GetActivityId())
        local number = 0
        for weekIndex = 1, weekAmount do
            if XWeekChallengeManager.GetWeekState(weekIndex) == XWeekChallengeConfigs.WeekState.Opened then
                local taskIdList = XWeekChallengeConfigs.GetTaskIdGroup(BaseInfo:GetActivityId(), weekIndex)
                for i = 1, #taskIdList do
                    local taskId = taskIdList[i]
                    if XWeekChallengeManager.IsTaskFinished(taskId) then
                        number = number + 1
                    end
                end
            end
        end
        return number
    end

    -- 认为 完成未提交的任务 = 完成的任务
    XWeekChallengeManager.IsTaskFinished = function(taskId)
        return XDataCenter.TaskManager.CheckTaskFinished(taskId) or XDataCenter.TaskManager.CheckTaskAchieved(taskId)
    end

    XWeekChallengeManager.GetNumberOfTasks = function()
        local weekAmount = XWeekChallengeConfigs.GetWeekAmount(BaseInfo:GetActivityId())
        local number = 0
        for weekIndex = 1, weekAmount do
            local taskIdList = XWeekChallengeConfigs.GetTaskIdGroup(BaseInfo:GetActivityId(), weekIndex)
            number = number + #taskIdList
        end
        return number
    end

    -- 进度条对应的任务数量
    XWeekChallengeManager.GetArrayTaskCount = function()
        return XWeekChallengeConfigs.GetArrayTaskCount(BaseInfo:GetActivityId())
    end

    -- 进度条对应的reward
    XWeekChallengeManager.GetArrayReward = function()
        return XWeekChallengeConfigs.GetArrayReward(BaseInfo:GetActivityId())
    end

    XWeekChallengeManager.GetRewardAmount = function()
        return #XWeekChallengeManager.GetArrayReward()
    end

    -- 奖品已领取
    XWeekChallengeManager.IsRewardReceived = function(taskCount)
        return BaseInfo:IsRewardReceived(taskCount)
    end

    XWeekChallengeManager.GetActivityCfg = function()
        return XWeekChallengeConfigs.GetActivityCfg(BaseInfo:GetActivityId())
    end

    XWeekChallengeManager.IsRewardCanReceived = function(taskCount)
        local finishTaskCount = XWeekChallengeManager.GetNumberOfCompletedTasks()
        return finishTaskCount >= taskCount and not XWeekChallengeManager.IsRewardReceived(taskCount)
    end

    local _WeekIndex = false
    XWeekChallengeManager.SetLastSelectedWeek = function(weekIndex)
        _WeekIndex = weekIndex
    end

    XWeekChallengeManager.GetLastSelectedWeek = function()
        return _WeekIndex
    end

    XWeekChallengeManager.GetWeekOfTaskUnfinished = function()
        for weekIndex = 1, XWeekChallengeManager.GetWeekAmount() do
            local taskIdList = XWeekChallengeManager.GetTaskIdArray(weekIndex)
            for i = 1, #taskIdList do
                local taskId = taskIdList[i]
                if
                    not XWeekChallengeManager.IsTaskFinished(taskId) and
                        XWeekChallengeManager.GetWeekState(weekIndex) == XWeekChallengeConfigs.WeekState.Opened
                 then
                    return weekIndex
                end
            end
        end
        return false
    end

    function XWeekChallengeManager.IsAnyRewardCanReceived()
        local arrayTaskCount = XWeekChallengeManager.GetArrayTaskCount()
        for i = 1, #arrayTaskCount do
            local taskCount = arrayTaskCount[i]
            if XWeekChallengeManager.IsRewardCanReceived(taskCount) then
                return true
            end
        end
        return false
    end

    -- 所有奖品已领取
    function XWeekChallengeManager.IsAllRewardReceived()
        local arrayTaskCount = XWeekChallengeManager.GetArrayTaskCount()
        for i = 1, #arrayTaskCount do
            local taskCount = arrayTaskCount[i]
            if not XWeekChallengeManager.IsRewardReceived(taskCount) then
                return false
            end
        end
        return true
    end

    function XWeekChallengeManager.OnAutoWindowOpen()
        -- 在任务完成时不跳转
        if XWeekChallengeManager.IsAllRewardReceived() then
            return
        end
        -- 自动弹窗 会被返回主界面重复触发
        if XLuaUiManager.IsUiShow("UiSignBanner") then
            return
        end
        if XWeekChallengeManager.IsOpen() then
            XLuaUiManager.Open("UiSignBanner", XWeekChallengeConfigs.SignId)
        end
    end
    
    function XWeekChallengeManager.JumpToPanel()
        if XWeekChallengeManager.IsOpen() then
            XLuaUiManager.Open("UiSignBanner", XWeekChallengeConfigs.SignId)
        end
    end

    --region request
    -- 领取奖品
    XWeekChallengeManager.RequestReceiveReward = function(taskCount)
        if XWeekChallengeManager.IsRewardReceived(taskCount) then
            return false
        end
        if not XWeekChallengeManager.IsRewardCanReceived(taskCount) then
            return false
        end
        XNetwork.CallWithAutoHandleErrorCode(
            "WeekChallengeProgressRewardRequest",
            {
                Progress = taskCount
            },
            function(res)
                if res.Code ~= XCode.Success then
                    return
                end
                BaseInfo:SetRewardReceived(taskCount)
                XUiManager.OpenUiObtain(res.ProgressRewardList)
                XEventManager.DispatchEvent(XEventId.EVENT_WEEK_CHALLENGE_UPDATE_REWARD)
                XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            end
        )
        return true
    end
    --endregion request

    --region notify
    XWeekChallengeManager.NotifyWeekChallengeData = function(data)
        BaseInfo:UpdateData(data)
    end
    --endregion notify

    return XWeekChallengeManager
end

--region Notify
XRpc.NotifyWeekChallengeData = function(data)
    XDataCenter.WeekChallengeManager.NotifyWeekChallengeData(data)
end
--endregion

local NewbieTaskCondition = {
    -- 每日首进
    [XNewbieEventType.FIRST_ENTER] = function()
        return not XDataCenter.NewbieTaskManager.CheckIsDailyFirstEnter()
    end,

    -- 非每日首进
    [XNewbieEventType.NOT_FIRST_ENTER] = function()
        return XDataCenter.NewbieTaskManager.CheckIsDailyFirstEnter()
    end,

    -- 有未领取的奖励
    [XNewbieEventType.REWARD] = function()
        if XDataCenter.NewbieTaskManager.CheckTaskHaveAchieved() or XDataCenter.NewbieTaskManager.CheckProgressRewardHaveAchieved() then
            return true
        end
        return false
    end,
}
-- 新手任务（二期）管理类
XNewbieTaskManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local pairs = pairs

    local XNewbieTaskManager = {}

    local RequestProto = {
        GetNewbieRewardRequest = "GetNewbieRewardRequest", -- 请求新手任务奖励
        GetNewbieHonorRewardRequest = "GetNewbieHonorRewardRequest", -- 请求新手荣耀奖励
    }
    -- 当前解锁阶段
    local UnlockPeriod = 1
    local NewbieRecordProgress = {}
    local NewbieHonorReward = false

    --播放器数据
    local PlayerData = nil

    function XNewbieTaskManager.GetNewbieTaskAnimPlayerData()
        if not PlayerData then
            PlayerData = {}
            PlayerData.PlayerList = {} --播放列表
            PlayerData.PlayingElement = nil --播放对象
            PlayerData.PlayedList = {} --播放过的列表
            PlayerData.LastPlayTime = -1 --上次播放时间
        end

        return PlayerData
    end

    function XNewbieTaskManager.ResetPlayerData()
        if PlayerData then
            PlayerData.PlayerList = {} --播放列表
            PlayerData.PlayingElement = nil --播放对象
            PlayerData.PlayedList = {} --播放过的列表
            PlayerData.LastPlayTime = -1 --上次播放时间
        end
    end

    -- 获取互动的事件
    function XNewbieTaskManager.GetPlayElements()
        local elements = XNewbieTaskConfigs.GetPassiveAnimConfig()
        if not elements or #elements <= 0 then
            return {}
        end

        local all = {}

        for _, tab in pairs(elements) do
            local condition = NewbieTaskCondition[tab.ConditionId]

            if condition and condition(tab.ConditionParam) then
                local element = {}
                element.Id = tab.Id
                element.StartTime = -1 --开始播放的时间
                element.EndTime = -1 --结束时间
                element.Duration = tab.Duration  --播放持续时间
                element.CoolTime = tab.CoolTime --冷却时间
                element.Priority = tab.Priority -- 优先级
                element.Config = tab

                tableInsert(all, element)
            end
        end
        table.sort(all, function(a, b)
            return a.Priority < b.Priority
        end)

        return all
    end

    -- 通过点击次数获取事件
    function XNewbieTaskManager.GetPlayElementsByClick(clickTimes)
        local configs = XNewbieTaskConfigs.GetAnimConfigByFeedback(XNewbieEventType.CLICK, clickTimes)
        local element = XNewbieTaskManager.WeightRandomSelect(configs)
        return element
    end

    --权重随机算法
    function XNewbieTaskManager.WeightRandomSelect(elements)
        if not elements or #elements <= 0 then
            return
        end

        if #elements == 1 then
            return elements[1]
        end

        return XTool.WeightRandomSelect(elements)
    end

    -- 获取进度奖励
    function XNewbieTaskManager.GetNewbieReward(progress, cb)
        local req = { Progress = progress }

        XNetwork.Call(RequestProto.GetNewbieRewardRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XNewbieTaskManager.UpdateNewbieRecordProgress(progress)

            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    -- 获取荣誉奖励
    function XNewbieTaskManager.GetNewbieHonorReward(cb)
        XNetwork.Call(RequestProto.GetNewbieHonorRewardRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            NewbieHonorReward = true

            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    -- 打开新手任务二期UI
    function XNewbieTaskManager.OpenMainUi()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewbieTask) then
            return
        end
        XLuaUiManager.Open("UiNewbieTaskMain")
    end

    -- 当前新手任务二期是否开启
    function XNewbieTaskManager.GetIsOpen()
        -- 功能是否开启
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewbieTask, false, true) then
            return false
        end
        -- 奖励是否全部领取了。全部领取了返回false,否则为True
        local isAllReceive = XNewbieTaskManager.CheckTaskAllFinish() and XNewbieTaskManager.CheckProgressRewardAllReceive() and NewbieHonorReward
        return not isAllReceive
    end

    -- 返回荣誉奖励领取状态
    function XNewbieTaskManager.CheckNewbieHonorReward()
        return NewbieHonorReward
    end

    -- 检测活动入口红点
    function XNewbieTaskManager.CheckActivityEntryRedPoint()
        -- 是否有待领取的任务奖励
        if XNewbieTaskManager.CheckTaskHaveAchieved() then
            return true
        end
        -- 是否有待领取的进度奖励
        if XNewbieTaskManager.CheckProgressRewardHaveAchieved() then
            return true
        end
        -- 是否有待领取的荣誉奖励（任务奖励和进度奖励都完成了才会有荣誉奖励)
        if XNewbieTaskManager.CheckTaskAllFinish() and XNewbieTaskManager.CheckProgressRewardAllReceive() and not NewbieHonorReward then
            return true
        end
        -- 是否有新解锁的任务
        if XNewbieTaskManager.CheckHaveNewRegisterDay() then
            return true
        end
        return false
    end

    -- 检测解锁天数红点
    function XNewbieTaskManager.CheckRegisterDayRedPoint(day)
        -- 是否有待领取的任务奖励
        if XNewbieTaskManager.CheckTaskAchievedByDay(day) then
            return true
        end
        -- 是否是新解锁的任务
        if not XNewbieTaskManager.GetRegisterDayBtnClick(day) then
            return true
        end
        return false
    end

    -- 检测任务奖励是否有已完成未领取的奖励
    function XNewbieTaskManager.CheckTaskHaveAchieved()
        local groupConfig = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        for _, config in pairs(groupConfig) do
            if XNewbieTaskManager.CheckUnlockPeriod(config.RegisterDay) and XNewbieTaskManager.CheckTaskAchievedByDay(config.RegisterDay) then
                return true
            end
        end
        return false
    end

    -- 检测进度奖励是否有已完成未领取的奖励（不包含荣誉奖励）
    function XNewbieTaskManager.CheckProgressRewardHaveAchieved()
        local progressNumber = XNewbieTaskManager.GetCurrentTaskProgress()
        local newbieActiveness = XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
        for _, activeness in pairs(newbieActiveness.Activeness) do
            if progressNumber >= activeness and not XNewbieTaskManager.CheckProgressRewardReceive(activeness) then
                return true
            end
        end
        return false
    end

    -- 检测任务是否全部完成
    function XNewbieTaskManager.CheckTaskAllFinish()
        local groupConfig = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        for _, config in pairs(groupConfig) do
            if not XNewbieTaskManager.CheckTaskFinishByDay(config.RegisterDay) then
                return false
            end
        end
        return true
    end

    -- 检测进度奖励是否全部已领取（不包含荣誉奖励）
    function XNewbieTaskManager.CheckProgressRewardAllReceive()
        local newbieActiveness = XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
        for _, activeness in pairs(newbieActiveness.Activeness) do
            if not XNewbieTaskManager.CheckProgressRewardReceive(activeness) then
                return false
            end
        end
        return true
    end

    -- 检测是否是新解锁的任务
    function XNewbieTaskManager.CheckHaveNewRegisterDay()
        local groupConfig = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        for _, config in pairs(groupConfig) do
            if XNewbieTaskManager.CheckUnlockPeriod(config.RegisterDay)
                    and not XNewbieTaskManager.GetRegisterDayBtnClick(config.RegisterDay)
                    and not XNewbieTaskManager.CheckTaskFinishByDay(config.RegisterDay)
            then
                return true
            end
        end
        return false
    end

    --region 保存到本地

    function XNewbieTaskManager.SaveRegisterDayBtnClick(day)
        local key = XNewbieTaskManager.GetBtnClickKey(day)
        local isClick = XSaveTool.GetData(key)
        if isClick then
            return false
        end
        XSaveTool.SaveData(key, true)
        return true
    end

    function XNewbieTaskManager.GetRegisterDayBtnClick(day)
        local key = XNewbieTaskManager.GetBtnClickKey(day)
        local isClick = XSaveTool.GetData(key) or false
        return isClick
    end

    function XNewbieTaskManager.GetBtnClickKey(day)
        if XPlayer.Id and day then
            return string.format("%s_%s_%s", "NewbieTaskRegisterDayBtnClick", tostring(XPlayer.Id), tostring(day))
        end
    end

    -- 检测是否是每日首进 非每日首进返回true,否则返回false
    function XNewbieTaskManager.CheckIsDailyFirstEnter()
        local key = XNewbieTaskManager.GetDailyFirstEnterKey()
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end

    function XNewbieTaskManager.SaveDailyFirstEnter()
        if XNewbieTaskManager.CheckIsDailyFirstEnter() then
            return
        end
        local key = XNewbieTaskManager.GetDailyFirstEnterKey()
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end

    function XNewbieTaskManager.GetDailyFirstEnterKey()
        if XPlayer.Id then
            return string.format("%s_%s", "NewbieTaskDailyFirstEnterTime", tostring(XPlayer.Id))
        end
    end
    --endregion

    -- 检测第几天是否解锁
    -- 解锁返回true，否则返回false
    function XNewbieTaskManager.CheckUnlockPeriod(day)
        if not XTool.IsNumberValid(UnlockPeriod) then
            return false
        end

        return day <= UnlockPeriod
    end

    -- 检测第day天的任务是否都已完成
    function XNewbieTaskManager.CheckTaskFinishByDay(day)
        local taskIds = XNewbieTaskConfigs.GetNewbieTaskIdByDay(day)

        for _, taskId in pairs(taskIds) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData and taskData.State ~= XDataCenter.TaskManager.TaskState.Finish and taskData.State ~= XDataCenter.TaskManager.TaskState.Invalid then
                return false
            end
        end
        return true
    end

    -- 检测第day天的任务是否有待领取的
    function XNewbieTaskManager.CheckTaskAchievedByDay(day)
        local taskIds = XNewbieTaskConfigs.GetNewbieTaskIdByDay(day)

        for _, taskId in pairs(taskIds) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end

    -- 获取任务天数
    function XNewbieTaskManager.GetNewbieTaskRegisterDay()
        local groupConfig = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        local registerDay = {}

        for _, config in pairs(groupConfig) do
            tableInsert(registerDay, config.RegisterDay)
        end

        tableSort(registerDay, function(a, b)
            return a < b
        end)

        return registerDay
    end

    -- 获取第几天的任务
    function XNewbieTaskManager.GetTaskDataList(day)
        local taskIds = XNewbieTaskConfigs.GetNewbieTaskIdByDay(day)

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        local finish = XDataCenter.TaskManager.TaskState.Finish

        tableSort(taskIds, function(a, b)
            local taskDataA = XDataCenter.TaskManager.GetTaskDataById(a)
            local taskDataB = XDataCenter.TaskManager.GetTaskDataById(b)
            if taskDataA.State ~= taskDataB.State then
                if taskDataA.State == achieved then
                    return true
                end
                if taskDataB.State == achieved then
                    return false
                end
                if taskDataA.State == finish then
                    return false
                end
                if taskDataB.State == finish then
                    return true
                end
            end

            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b)
            if templatesTaskA.Priority ~= templatesTaskB.Priority then
                return templatesTaskA.Priority > templatesTaskB.Priority
            else
                return a > b
            end
        end)

        return taskIds
    end

    -- 获取完成的任务进度数
    function XNewbieTaskManager.GetCurrentTaskProgress()
        local number = 0

        local taskGroup = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        for _, config in pairs(taskGroup) do
            local taskIds = config.TaskId
            for _, taskId in pairs(taskIds) do
                if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                    number = number + 1
                end
            end
        end

        return number
    end

    -- 检测进度奖励是否已领取
    function XNewbieTaskManager.CheckProgressRewardReceive(activeness)
        for _, v in pairs(NewbieRecordProgress or {}) do
            if v == activeness then
                return true
            end
        end
        return false
    end

    -- 检查是否包含指定奖励的任务未结束（包含未完成状态和已完成状态）(包含普通任务和进度任务，不包含荣誉任务)
    function XNewbieTaskManager.CheckHasTaskCanFinishByAssignItemId(itemId)
        -- 普通任务
        local groupConfig = XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
        for _, config in pairs(groupConfig) do
            if XNewbieTaskManager.CheckUnlockPeriod(config.RegisterDay) then
                local taskIds = XNewbieTaskConfigs.GetNewbieTaskIdByDay(config.RegisterDay)
                for _, taskId in pairs(taskIds) do
                    if XDataCenter.TaskManager.CheckTaskActive(taskId) or XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        local rewardId = XTaskConfig.GetTaskRewardId(taskId)
                        local rewardGoods = XRewardManager.GetRewardList(rewardId)
                        if not XTool.IsTableEmpty(rewardGoods) then
                            for _, rewardGood in ipairs(rewardGoods) do
                                if rewardGood.TemplateId == itemId then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 进度任务
        local newbieActiveness = XTaskConfig.GetNewbieTaskTwoActivenessTemplate()
        for index, activeness in pairs(newbieActiveness.Activeness) do
            if not XNewbieTaskManager.CheckProgressRewardReceive(activeness) then
                local rewardId = newbieActiveness.RewardId[index]
                if XTool.IsNumberValid(rewardId) then
                local rewardGoods = XRewardManager.GetRewardList(rewardId)
                    if not XTool.IsTableEmpty(rewardGoods) then
                        for _, rewardGood in ipairs(rewardGoods) do
                            if rewardGood.TemplateId == itemId then
                                return true
                            end
                        end
                    end
                end
            end
        end
        
        return false
    end

    -- 更新奖励进度领取记录
    function XNewbieTaskManager.UpdateNewbieRecordProgress(activeness)
        for _, v in pairs(NewbieRecordProgress or {}) do
            if v == activeness then
                return
            end
        end
        NewbieRecordProgress[#NewbieRecordProgress + 1] = activeness
    end

    -- 更新解锁阶段
    function XNewbieTaskManager.UpdateUnlockPeriod(data)
        if XTool.IsNumberValid(data.UnlockPeriod) then
            UnlockPeriod = data.UnlockPeriod
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED)
            XEventManager.DispatchEvent(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED)
        end
    end

    function XNewbieTaskManager.InitTaskData(data)
        -- 新手荣誉任务解锁阶段（新手任务二期）
        if XTool.IsNumberValid(data.NewbieUnlockPeriod) then
            UnlockPeriod = data.NewbieUnlockPeriod
        end
        -- 新手荣誉任务奖励进度领取记录（新手任务二期）
        NewbieRecordProgress = data.NewbieRecvProgress
        -- 是否领取新手荣耀奖励（新手任务二期）
        NewbieHonorReward = data.NewbieHonorReward
    end

    function XNewbieTaskManager.Init()
    end

    XNewbieTaskManager.Init()
    return XNewbieTaskManager
end

XRpc.NotifyNewbieTaskPeriod = function(data)
    XDataCenter.NewbieTaskManager.UpdateUnlockPeriod(data)
end
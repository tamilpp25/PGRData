XRegressionManagerCreator = function()
    local XRegressionManager = {}

    local METHOD_NAME = {
        GetScheduleRewardRequest = "GetScheduleRewardRequest",
        CreateInviteCodeRequest = "CreateInviteCodeRequest",
        GetInviteMsgRequest = "GetInviteMsgRequest",
        GetInviteRewardRequest = "GetInviteRewardRequest",
        UseInviteCodeRequest = "UseInviteCodeRequest",
    }

    -->>>回归任务活动数据相关
    local TaskData
    local TaskScheduleItemId
    local TaskScheduleRewardHaveGetDic = {}
    local TaskScheduleRewardCanGetDic = {}
    local TaskScheduleRewardSumRedPointCount = 0    --进度奖励总红点
    --<<<回归任务活动数据相关
    -->>>回归活动剧情数据
    local NeedAutoPlayStory
    local NeedToPlayStoryActivityId
    --<<<回归活动剧情数据
    -->>> 发送邀请活动数据相关
    -- ps:在客户端邀请/被邀请活动界面与回归活动（任务等）界面是分开的，但是邀请活动的数据存储在此模块
    local InvitationActivityData
    local InvitationActivitiesStartTime
    local InvitationActivitiesEndTime
    local LastRequestInvitationMsgTime = 0
    local RequestInvitationMsgInternalTime = CS.XGame.ClientConfig:GetInt("RegressionRequestInvitationMsgInternalTime")   --请求间隔限制
    local InvitationCode
    local AcceptMyInvitationCount = 0
    local SendInvitationRewardCanGetDic = {}
    local SendInvitationRewardHaveGetDic = {}
    local SendInvitationRedPointCount = 0
    --<<< 发送邀请活动数据相关
    -->>> 接受邀请活动数据相关
    local LastRequestUseInvitationCodeTime = 0
    local RequestUseInvitationCodeInternalTime = CS.XGame.ClientConfig:GetInt("RegressionRequestUseInvitationCodeInternalTime")   --请求间隔限制
    --<<< 接受邀请活动数据相关
    local IsSendInvitationActivityNeedRead
    local IsAcceptInvitationActivityNeedRead

    local UpdateTaskSchedule = function(activityId, itemId, schedule)
        local itemManager = XDataCenter.ItemManager
        schedule = schedule or itemManager.GetCount(itemId)
        local groupId = XRegressionConfigs.GetTaskScheduleGroupId(activityId)
        local scheduleRewardList = XRegressionConfigs.GetTaskScheduleRewardList(groupId)
        local scheduleId
        for _, scheduleReward in ipairs(scheduleRewardList) do
            scheduleId = scheduleReward.Id
            if not TaskScheduleRewardHaveGetDic[scheduleId] and not TaskScheduleRewardCanGetDic[scheduleId] then
                if schedule >= scheduleReward.Schedule then
                    TaskScheduleRewardCanGetDic[scheduleId] = true
                    TaskScheduleRewardSumRedPointCount = TaskScheduleRewardSumRedPointCount + 1
                end
            end
        end
    end

    local GetUseCodeList = function()
        return InvitationActivityData and InvitationActivityData.UseCodeList
    end

    local GetLocalSavedKey = function(key, activityId, startTimeStamp)
        return string.format("%s%d%d%d", key, XPlayer.Id, activityId, startTimeStamp)
    end

    function XRegressionManager.Init()
        local activityTemplates = XRegressionConfigs.GetActivityTemplates()
        for _, template in pairs(activityTemplates) do
            if template.Type == XRegressionConfigs.ActivityType.Task then
                XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. template.ScheduleItemId, XRegressionManager.OnEventItemCountChange)
            end
        end
    end

    function XRegressionManager.IsRegressionActivityOpen(type)
        local isOpen = false
        if type == XRegressionConfigs.ActivityType.Task then
            isOpen = TaskData ~= nil
        end
        return isOpen
    end

    -- 是否有一个回归活动开启
    function XRegressionManager.IsHaveOneRegressionActivityOpen()
        return XRegressionManager.IsRegressionActivityOpen(XRegressionConfigs.ActivityType.Task)
    end

    function XRegressionManager.GetTaskActivityId()
        return TaskData and TaskData.Id
    end

    function XRegressionManager.GetTaskStartTime()
        return TaskData and TaskData.BeginTime
    end

    function XRegressionManager.GetTaskEndTime()
        return TaskData and TaskData.EndTime
    end

    function XRegressionManager.GetTaskScheduleItemId()
        return TaskScheduleItemId
    end

    function XRegressionManager.IsTaskHaveRedPointByType(type)
        return XDataCenter.TaskManager.GetRegressionTaskTypeToRedPointCount(type) > 0
    end

    function XRegressionManager.IsTaskHaveRedPoint()
        local count = XDataCenter.TaskManager.GetRegressionTaskRedPointCount() + TaskScheduleRewardSumRedPointCount
        return count > 0
    end

    function XRegressionManager.IsTaskScheduleRewardHaveGet(id)
        return TaskScheduleRewardHaveGetDic[id] == true
    end

    function XRegressionManager.IsTaskScheduleRewardCanGet(id)
        return TaskScheduleRewardCanGetDic[id] == true
    end

    -- 目前根据回归任务的期数来判断是否需要打脸
    function XRegressionManager.CheckNeedAutoWindow()
        local isNeed = false
        if XRegressionManager.IsRegressionActivityOpen(XRegressionConfigs.ActivityType.Task) then
            local localSavedKey = GetLocalSavedKey(XRegressionConfigs.AutoWindowKey, TaskData.Id, TaskData.BeginTime)
            if not XSaveTool.GetData(localSavedKey) then
                isNeed = true
                XSaveTool.SaveData(localSavedKey, true)
            end
        end

        return isNeed
    end

    function XRegressionManager.SetPlayStoryInfo()
        NeedAutoPlayStory = false
        if XRegressionManager.IsRegressionActivityOpen(XRegressionConfigs.ActivityType.Task) then
            local storyId = XRegressionConfigs.GetActivityStoryId(TaskData.Id)
            if storyId then
                NeedToPlayStoryActivityId = TaskData.Id
                local localSavedKey = GetLocalSavedKey(XRegressionConfigs.AutoStoryKey, TaskData.Id, TaskData.BeginTime)
                if not XSaveTool.GetData(localSavedKey) then
                    NeedAutoPlayStory = true
                end
            end
        end
    end

    function XRegressionManager.HandlePlayStory(checkIsFirst)
        if not NeedToPlayStoryActivityId then return end
        local storyId = XRegressionConfigs.GetActivityStoryId(NeedToPlayStoryActivityId)
        if not storyId then return end
        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(NeedToPlayStoryActivityId)
        local activityType = activityTemplate.Type
        if not XRegressionManager.IsRegressionActivityOpen(activityType) then return end
        if checkIsFirst then
            if NeedAutoPlayStory then
                XDataCenter.MovieManager.PlayMovie(storyId)
                if activityType == XRegressionConfigs.ActivityType.Task then
                    local localSavedKey = GetLocalSavedKey(XRegressionConfigs.AutoStoryKey, TaskData.Id, TaskData.BeginTime)
                    XSaveTool.SaveData(localSavedKey, true)
                end
                NeedAutoPlayStory = false
            end
        else
            XDataCenter.MovieManager.PlayMovie(storyId)
        end
    end

    function XRegressionManager.IsShowActivityViewStoryBtn()
        return NeedToPlayStoryActivityId ~= nil
    end

    function XRegressionManager.IsInvitationActivityInTime()
        local nowTime = XTime.GetServerNowTimestamp()
        if InvitationActivitiesStartTime and InvitationActivitiesEndTime then
            if InvitationActivitiesStartTime < nowTime and nowTime < InvitationActivitiesEndTime then
                return true
            end
        end
        return false
    end

    -- 获取邀请活动中的子类是否开启的
    function XRegressionManager.IsActivityOpenInUiActivityBase(type)
        if not InvitationActivityData then return false end
        if not XRegressionManager.IsInvitationActivityInTime() then return false end
        local invitationStatus = InvitationActivityData.InviteType
        if invitationStatus == XRegressionConfigs.InvitationStatus.Both then return true end

        if type == XActivityConfigs.ActivityType.SendInvitation and invitationStatus == XRegressionConfigs.InvitationStatus.SendInvitation then
            return true
        elseif type == XActivityConfigs.ActivityType.AcceptInvitation and invitationStatus == XRegressionConfigs.InvitationStatus.AcceptInvitation then
            return true
        end
        return false
    end

    function XRegressionManager.IsSendInvitationRewardCanGet(id)
        return SendInvitationRewardCanGetDic[id] == true
    end

    function XRegressionManager.IsSendInvitationRewardHaveGet(id)
        return SendInvitationRewardHaveGetDic[id] == true
    end

    function XRegressionManager.GetInvitationActivityId()
        return InvitationActivityData and InvitationActivityData.Id
    end

    function XRegressionManager.GetInvitationStatus()
        return InvitationActivityData and InvitationActivityData.InviteType
    end

    function XRegressionManager.GetAcceptMyInvitationCount()
        return AcceptMyInvitationCount
    end

    function XRegressionManager.GetInvitationCode()
        return InvitationCode
    end

    function XRegressionManager.IsSendInvitationHaveRedPoint()
        return IsSendInvitationActivityNeedRead or SendInvitationRedPointCount > 0
    end

    function XRegressionManager.IsAcceptInvitationHaveRedPoint()
        return IsAcceptInvitationActivityNeedRead == true
    end

    function XRegressionManager.IsUseInvitationCodeRewardHaveGet(index)
        local useCodeList = GetUseCodeList()
        if useCodeList then
            return index <= #useCodeList
        end
        return false
    end

    function XRegressionManager.IsInvitationCodeHaveUse(code)
        local useCodeList = GetUseCodeList()
        if useCodeList then
            for _, v in ipairs(useCodeList) do
                if code == v then
                    return true
                end
            end
        end
        return false
    end

    function XRegressionManager.InitInvitationReadStatus()
        if not InvitationActivityData then return end
        local activityId = InvitationActivityData.Id

        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
        if not activityTemplate then return end

        local startTime = XRegressionConfigs.GetActivityTime(activityId)
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime)

        --获取本地邀请他人活动是否已读
        local localSavedKey = GetLocalSavedKey(XRegressionConfigs.SendInvitationReadKey, XPlayer.Id, activityId, startTimeStr)
        if IsSendInvitationActivityNeedRead == nil then
            if XSaveTool.GetData(localSavedKey) then
                IsSendInvitationActivityNeedRead = false
            else
                IsSendInvitationActivityNeedRead = true
            end
        end

        --获取本地接受邀请活动是否已读
        localSavedKey = GetLocalSavedKey(XRegressionConfigs.AcceptInvitationReadKey, XPlayer.Id, activityId, startTimeStr)
        if IsAcceptInvitationActivityNeedRead == nil then
            if XSaveTool.GetData(localSavedKey) then
                IsAcceptInvitationActivityNeedRead = false
            else
                IsAcceptInvitationActivityNeedRead = true
            end
        end
    end

    function XRegressionManager.HandleReadSendInvitationActivity()
        if not InvitationActivityData then return end
        if not IsSendInvitationActivityNeedRead then return end
        local activityId = InvitationActivityData.Id

        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
        if not activityTemplate then return end

        local startTime = XRegressionConfigs.GetActivityTime(activityId)
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime)
        local localSavedKey = GetLocalSavedKey(XRegressionConfigs.SendInvitationReadKey, XPlayer.Id, activityId, startTimeStr)

        XSaveTool.SaveData(localSavedKey, true)
        IsSendInvitationActivityNeedRead = false
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
    end

    function XRegressionManager.HandleReadAcceptInvitationActivity()
        if not InvitationActivityData then return end
        if not IsAcceptInvitationActivityNeedRead then return end
        local activityId = InvitationActivityData.Id
        local activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(activityId)
        if not activityTemplate then return end

        local startTime = XRegressionConfigs.GetActivityTime(activityId)
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime)

        local localSavedKey = GetLocalSavedKey(XRegressionConfigs.AcceptInvitationReadKey, XPlayer.Id, activityId, startTimeStr)
        XSaveTool.SaveData(localSavedKey, true)
        IsAcceptInvitationActivityNeedRead = false
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
    end

    --服务端数据处理相关------------------------>>>
    function XRegressionManager.InitTaskData(data)
        if not data then return end
        TaskData = data
        if data.ScheduleRewards then
            for _, scheduleId in ipairs(data.ScheduleRewards) do
                TaskScheduleRewardHaveGetDic[scheduleId] = true
            end
            data.ScheduleRewards = nil
        end

        TaskScheduleItemId = XRegressionConfigs.GetScheduleItemIdByActivityId(TaskData.Id)
        UpdateTaskSchedule(TaskData.Id, TaskScheduleItemId)
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE)
    end

    function XRegressionManager.InitInvitationActivityData(data)
        if not data then return end
        InvitationActivityData = data

        if data.InviteRewards then
            for _, id in ipairs(data.InviteRewards) do
                if SendInvitationRewardCanGetDic[id] then
                    SendInvitationRewardCanGetDic[id] = nil
                    SendInvitationRedPointCount = SendInvitationRedPointCount - 1
                end
                if not SendInvitationRewardHaveGetDic[id] then
                    SendInvitationRewardHaveGetDic[id] = true
                end
            end
        end

        InvitationActivityData.InviteRewards = nil
        InvitationActivitiesStartTime, InvitationActivitiesEndTime = XRegressionConfigs.GetActivityTime(data.Id)

        --在活动开启时初始化已读信息
        XRegressionManager.InitInvitationReadStatus()
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
    end

    function XRegressionManager.InitSendInvitationInfo()
        InvitationCode = ""
        AcceptMyInvitationCount = 0
    end

    function XRegressionManager.UpdateLastRequestInvitationMsgTime()
        LastRequestInvitationMsgTime = XTime.GetServerNowTimestamp()
    end

    function XRegressionManager.UpdateSendInvitationInfo(invitationInfo)
        InvitationCode = invitationInfo.InviteCode

        local isNeedEvent = false
        if InvitationActivityData and AcceptMyInvitationCount ~= invitationInfo.InviteCount then
            AcceptMyInvitationCount = invitationInfo.InviteCount
            local invitationTemplateId = XRegressionConfigs.GetInvitationTemplateId(InvitationActivityData.Id)
            local invitationTemplate = XRegressionConfigs.GetInvitationTemplate(invitationTemplateId)
            local needCount
            for _, id in ipairs(invitationTemplate.InviteRewardId) do
                if not SendInvitationRewardCanGetDic[id] and not SendInvitationRewardHaveGetDic[id] then
                    needCount = XRegressionConfigs.GetSendInvitationRewardNeedCount(id)
                    if AcceptMyInvitationCount >= needCount then
                        SendInvitationRewardCanGetDic[id] = true
                        SendInvitationRedPointCount = SendInvitationRedPointCount + 1
                        isNeedEvent = true
                    end
                end
            end
        end

        if isNeedEvent then
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_SEND_INVITATION_INFO_UPDATE)
        end
        return isNeedEvent
    end

    function XRegressionManager.RequestGetRegressionScheduleReward(id, callback)
        XNetwork.Call(METHOD_NAME.GetScheduleRewardRequest, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            TaskScheduleRewardCanGetDic[id] = false
            TaskScheduleRewardHaveGetDic[id] = true
            TaskScheduleRewardSumRedPointCount = TaskScheduleRewardSumRedPointCount - 1

            XUiManager.OpenUiObtain(res.RewardList)
            if callback then
                callback()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_REWARD_GET)
        end)
    end

    function XRegressionManager.RequestCreateInviteCode(callback)
        LastRequestInvitationMsgTime = XTime.GetServerNowTimestamp()
        XNetwork.Call(METHOD_NAME.CreateInviteCodeRequest, nil, function(res)
            LastRequestInvitationMsgTime = XTime.GetServerNowTimestamp() --收到服务端的消息再次刷新上次请求时间
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local isNeedUpdate = XRegressionManager.UpdateSendInvitationInfo(res.Info)
            if not isNeedUpdate and callback then
                callback()
            end
        end)
    end

    function XRegressionManager.RequestGetInviteMsg(callback)
        LastRequestInvitationMsgTime = XTime.GetServerNowTimestamp()
        XNetwork.Call(METHOD_NAME.GetInviteMsgRequest, nil, function(res)
            LastRequestInvitationMsgTime = XTime.GetServerNowTimestamp() --收到服务端的消息再次刷新上次请求时间
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local isNeedUpdate = XRegressionManager.UpdateSendInvitationInfo(res.Info)
            if not isNeedUpdate and callback then
                callback()
            end
        end)
    end

    --邀请码为nil或者邀请好友活动没开启时不进行处理，主界面和活动界面共用此api，主界面不能创建邀请码，进入活动才可以
    function XRegressionManager.HandleGetInvitationCodeInfoRequest(isCanRequestCreateCode, callback)
        if not InvitationCode then return end
        -- 请求前检查活动是否开启
        if not XRegressionManager.IsActivityOpenInUiActivityBase(XActivityConfigs.ActivityType.SendInvitation) then
            if callback then
                callback()
            end
            return
        end

        --为主界面请求时，不进行创建邀请码的判断（登陆时如果有邀请资格但从未生成邀请码，则会为空字符串）
        if InvitationCode == "" then
            if isCanRequestCreateCode then
                XRegressionManager.RequestCreateInviteCode(callback)
            end
            return
        end
        if XTime.GetServerNowTimestamp() - LastRequestInvitationMsgTime > RequestInvitationMsgInternalTime then
            XRegressionManager.RequestGetInviteMsg(callback)
            return
        end

        if callback then
            callback()
        end
    end

    function XRegressionManager.RequestGetInviteReward(id, callback)
        XNetwork.Call(METHOD_NAME.GetInviteRewardRequest, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SendInvitationRewardCanGetDic[id] = nil
            SendInvitationRewardHaveGetDic[id] = true
            SendInvitationRedPointCount = SendInvitationRedPointCount - 1
            XUiManager.OpenUiObtain(res.RewardList)
            if callback then
                callback()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_SEND_INVITATION_INFO_UPDATE)
        end)
    end

    function XRegressionManager.RequestUseInvitationCode(code, callback)
        LastRequestUseInvitationCodeTime = XTime.GetServerNowTimestamp()
        XNetwork.Call(METHOD_NAME.UseInviteCodeRequest, { InviteCode = code }, function(res)
            LastRequestUseInvitationCodeTime = XTime.GetServerNowTimestamp()    --收到服务端的消息再次刷新上次请求时间
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local useCodeList = GetUseCodeList()
            if useCodeList then
                table.insert(useCodeList, code)
            end
            XUiManager.OpenUiObtain(res.RewardList)
            if callback then
                callback()
            end
        end)
    end

    function XRegressionManager.HandleUseInvitationCodeRequest(code, callback)
        if XTime.GetServerNowTimestamp() - LastRequestUseInvitationCodeTime > RequestUseInvitationCodeInternalTime then
            XRegressionManager.RequestUseInvitationCode(code, callback)
        else
            XUiManager.TipError(CS.XTextManager.GetText("RegressionAcceptInvitationUseCodeFrequently"))
        end
    end

    function XRegressionManager.CloseActivity(idList)
        local type
        local activityTemplate
        for _, id in ipairs(idList) do
            activityTemplate = XRegressionConfigs.GetActivityTemplateByActivityId(id)
            type = activityTemplate.Type
            if type == XRegressionConfigs.ActivityType.Task then
                TaskData = nil
                TaskScheduleItemId = nil
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE)
    end

    function XRegressionManager.OnEventItemCountChange(itemId, count)
        if not TaskData or not TaskScheduleItemId or itemId ~= TaskScheduleItemId then return end
        UpdateTaskSchedule(TaskData.Id, itemId, count)
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE)
    end
    --服务端数据处理相关-----------------------------------------<<<
    XRegressionManager.Init()
    return XRegressionManager
end

XRpc.NotifyRegressionActivityData = function(data)
    XDataCenter.RegressionManager.InitTaskData(data.TaskData)
    XDataCenter.RegressionManager.SetPlayStoryInfo()
    XDataCenter.RegressionManager.InitInvitationActivityData(data.InviteData)
end

XRpc.NotifyRegressionActivityClose = function(data)
    XDataCenter.RegressionManager.CloseActivity(data.CloseIds)
end

-- 登陆时如果有邀请资格但从未生成邀请码，则邀请码为空字符串，邀请人数为0；如果已经生成过，登陆时会发非空字符串的邀请码；
-- 请求CreateInviteCodeRequest与GetInviteMsgRequest协议时也会从这里更新邀请码和邀请人数的信息
XRpc.NotifyInviteCodeData = function(data)
    XDataCenter.RegressionManager.UpdateLastRequestInvitationMsgTime()
    XDataCenter.RegressionManager.UpdateSendInvitationInfo(data.Info)
end

XRpc.NotifyRegressInviteData = function(data)
    XDataCenter.RegressionManager.InitInvitationActivityData(data.InviteData)
    XDataCenter.RegressionManager.InitSendInvitationInfo()      -- 等级上升时服务端不推送NotifyInviteCodeData，得客户端初始化数据
end
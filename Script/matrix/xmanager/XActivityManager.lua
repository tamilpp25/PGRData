XActivityManagerCreator = function()
    local pairs = pairs
    local ipairs = ipairs
    local tostring = tostring
    local tonumber = tonumber
    local tableSort = table.sort
    local tableInsert = table.insert
    local stringSplit = string.Split
    local ParseToTimestamp = XTime.ParseToTimestamp
    local CSUnityEnginePlayerPrefs = CS.UnityEngine.PlayerPrefs
    local CSXTextManagerGetText = CS.XTextManager.GetText

    local SortedActivityGroupInfos = {}
    local HaveReadActivityIds = {}
    local SavedTimeDataDic = {}

    local METHOD_NAME = {
        LinkTaskFinished = "DoClientTaskEventRequest"
    }

    local XActivityManager = {}
    function XActivityManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, XActivityManager.ReadCookie)
        XEventManager.AddEventListener(XEventId.EVENT_REGRESSION_TASK_SCHEDULE_UPDATE, XActivityManager.ReadCookie)
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, XActivityManager.ReadTime)
        -- XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, XActivityManager.OnTaskDataChanged)
        XActivityManager.InitSortedActivityGroupInfos()
    end

    --构建活动组-活动配置索引表并分别根据SortId排序
    function XActivityManager.InitSortedActivityGroupInfos()
        local sortFunc = function(l, r)
            return l.SortId < r.SortId
        end

        local activityGroupTemplates = XActivityConfigs.GetActivityGroupTemplates()
        for groupId, template in pairs(activityGroupTemplates) do
            SortedActivityGroupInfos[groupId] = {
                SortId = template.SortId,
                ActivityGroupCfg = template,
                ActivityCfgs = {}
            }
        end

        local activityTemplates = XActivityConfigs.GetActivityTemplates()
        for _, template in pairs(activityTemplates) do
            local groupId = template.GroupId
            local activityGroupCfg = SortedActivityGroupInfos[groupId]
            if not activityGroupCfg then
                XLog.ErrorTableDataNotFound("XActivityManager.InitSortedActivityGroupInfos",
                "activityGroupCfg", "Client/Activity/ActivityGroup.tab", "GroupId", tostring(groupId))
                return
            end
            local activityCfgs = activityGroupCfg.ActivityCfgs
            tableInsert(activityCfgs, template)
        end

        for _, activityGroupInfo in pairs(SortedActivityGroupInfos) do
            tableSort(activityGroupInfo.ActivityCfgs, sortFunc)
        end

        tableSort(SortedActivityGroupInfos, sortFunc)
    end

    function XActivityManager.PuzzleActIdToActId(subId)
        local activityTemplates = XActivityConfigs.GetActivityTemplates()
        for _, activityCfg in pairs(activityTemplates) do
            if activityCfg.ActivityType == XActivityConfigs.ActivityType.JigsawPuzzle and activityCfg.Params[1] == subId then
                return activityCfg.Id
            end
        end
        return
    end

    function XActivityManager.IsActivityOpen(activityId)
        if not activityId then return false end
        local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
        if not activityCfg then return false end

        if activityCfg.ConditionId ~= 0 then
            local result, _ = XConditionManager.CheckCondition(activityCfg.ConditionId)
            if not result then
                return false
            end
        end

        local now = XTime.GetServerNowTimestamp()
        local activityType = activityCfg.ActivityType
        if activityType == XActivityConfigs.ActivityType.Task then
            local taskGroupId = activityCfg.Params[1]
            return XTaskConfig.IsTimeLimitTaskInTime(taskGroupId)
        elseif activityType == XActivityConfigs.ActivityType.SendInvitation or activityType == XActivityConfigs.ActivityType.AcceptInvitation then
            if XDataCenter.RegressionManager.IsActivityOpenInUiActivityBase(activityType) then
                local regressionId = activityCfg.Params[1]
                if XDataCenter.RegressionManager.GetInvitationActivityId() == regressionId then
                    return true
                end
            end
            return false
        elseif activityType == XActivityConfigs.ActivityType.Link then
            local openTime = XDataCenter.TaskManager.GetLinkTimeTaskOpenTime(activityCfg.Params[2])
            if not openTime then
                return false
            end
            local timeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(activityCfg.Params[2])
            local durationTime = timeLimitCfg.Duration
            local tempTime = openTime + durationTime
            local endTime = tempTime
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime > openTime and nowTime < endTime then
                return true
            end
            return false
        end

        return XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId)
    end

    function XActivityManager.GetActivityGroupInfos()
        local groupInfos = {}

        for _, activityGroupInfo in ipairs(SortedActivityGroupInfos) do
            local groupInfo = {}

            for _, activityCfg in ipairs(activityGroupInfo.ActivityCfgs) do
                if XActivityManager.IsActivityOpen(activityCfg.Id) then
                    groupInfo.ActivityGroupCfg = groupInfo.ActivityGroupCfg or activityGroupInfo.ActivityGroupCfg
                    groupInfo.ActivityCfgs = groupInfo.ActivityCfgs or {}
                    tableInsert(groupInfo.ActivityCfgs, activityCfg)
                end
            end

            if next(groupInfo) then
                tableInsert(groupInfos, groupInfo)
            end
        end

        return groupInfos
    end

    function XActivityManager.GetActivityTaskData(activityId)
        local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
        if activityCfg.ActivityType ~= XActivityConfigs.ActivityType.Task and activityCfg.ActivityType ~= XActivityConfigs.ActivityType.ConsumeReward then
            return {}
        end

        local taskGroupId = activityCfg.Params[1]
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    end

    function XActivityManager.CheckRedPoint()
        local activityTemplates = XActivityConfigs.GetActivityTemplates()
        for activityId in pairs(activityTemplates) do
            if XActivityManager.CheckRedPointByActivityId(activityId) then
                return true
            end
        end
        return false
    end

    function XActivityManager.CheckRedPointByActivityId(activityId)
        if not XActivityManager.IsActivityOpen(activityId) then
            return false
        end

        --任务类型特殊加入已完成小红点逻辑
        local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
        if activityCfg.ActivityType == XActivityConfigs.ActivityType.Task or activityCfg.ActivityType == XActivityConfigs.ActivityType.ConsumeReward then -- 累计消费活动使用task类型红点判断
            local achieved = XDataCenter.TaskManager.TaskState.Achieved
            local taskDatas = XActivityManager.GetActivityTaskData(activityId)
            for _, taskData in pairs(taskDatas) do
                if taskData.State == achieved then
                    return true
                end
            end
            if activityCfg.Params[2] and activityCfg.Params[2] ~= 0 then -- 存在可跳转的任务面板
                return XActivityManager.CheckTaskSkipRedPoint(activityCfg.Params[2])
            end
            -- 拼图活动有自己的红点判断
        elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.JigsawPuzzle then
            -- Params[1] 为拼图活动ID
            local id = XActivityConfigs.GetActivityTemplate(activityId).Params[1]
            return XDataCenter.PuzzleActivityManager.IsHaveRedPointById(id)
            --发送邀请活动有自己的红点判断
        elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.SendInvitation then
            return XDataCenter.RegressionManager.IsSendInvitationHaveRedPoint()
            --接受邀请活动有自己的红点判断
        elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.AcceptInvitation then
            return XDataCenter.RegressionManager.IsAcceptInvitationHaveRedPoint()
        elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Link then
            --取得链接公告对应的链接内容
            local linkCfg = XActivityConfigs.GetActivityLinkCfg(activityCfg.Params[1])
            --如果已经领取过了，那么就不会再显示红点了
            local TaskData = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(activityCfg.Params[2])
            if not TaskData or not TaskData[1] then
                return false
            end
            if TaskData[1].State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
            if XDataCenter.TaskManager.IsTaskFinished(TaskData[1].Id) then
                return false
            end
            if linkCfg.RedPointType == 1 then
                return not HaveReadActivityIds[activityId]
            end
            if linkCfg.RedPointType == 2 then
                if SavedTimeDataDic[activityId] == 0 then
                    return true
                end

                local currentTime = XTime.GetSeverTodayFreshTime()
                return currentTime ~= SavedTimeDataDic[activityId]
            end
        -- 跳转活动需要特殊红点显示时
        elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Skip then 
            local redPointCondition = XActivityBriefConfigs.GetRedPointConditionsBySkipId(activityCfg.Params[1])
            if redPointCondition then
                for _, red in pairs(redPointCondition) do
                    if XRedPointConditions[red]:Check() then
                        return true
                    end
                end
            end
        end
        --当活动类型（ActivityType）为Shop或Skip时，红点通过本地记录来判断是否显示
        return not HaveReadActivityIds[activityId]
    end

    function XActivityManager.GetCookieKeyStr()
        return string.format("%s%s", tostring(XPlayer.Id), "_ActivityReadInfoCookieKey")
    end

    function XActivityManager.GetTodayTimeKeyStr()
        return string.format("%s%s", tostring(XPlayer.Id), "_TodayFrieTime")
    end

    function XActivityManager.ReadCookie()
        if not CSUnityEnginePlayerPrefs.HasKey(XActivityManager.GetCookieKeyStr()) then
            return
        end

        local dataStr = CSUnityEnginePlayerPrefs.GetString(XActivityManager.GetCookieKeyStr())
        local msgTab = stringSplit(dataStr, '\t')
        if not msgTab or #msgTab <= 0 then
            return
        end

        for _, activityIdStr in ipairs(msgTab) do
            local activityId = tonumber(activityIdStr)
            if activityId then
                local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
                if XActivityManager.IsActivityOpen(activityId) or (activityCfg and activityCfg.ActivityType == XActivityConfigs.ActivityType.Link) then
                    HaveReadActivityIds[activityId] = true
                else
                    HaveReadActivityIds[activityId] = nil
                end
            end
        end
    end

    --读取注册表保存的内容
    function XActivityManager.ReadTime()
        if not CSUnityEnginePlayerPrefs.HasKey(XActivityManager.GetTodayTimeKeyStr()) then
            return
        end
        
        local dataStr = CSUnityEnginePlayerPrefs.GetString(XActivityManager.GetTodayTimeKeyStr())
        local msgTab = stringSplit(dataStr, '\t')
        if not msgTab or #msgTab <= 0 then
            return
        end
        
        for _, timeStr in ipairs(msgTab) do
            local timeCfg = stringSplit(timeStr, '|')
            local activityId = tonumber(timeCfg[1])
            local time = tonumber(timeCfg[2])
            if activityId then
                SavedTimeDataDic[activityId] = time
            end
        end
    end

    function XActivityManager.OnTaskDataChanged()
        if XLuaUiManager.IsUiShow("UiDialog") then
            return
        end

        if not XLuaUiManager.IsUiShow("UiShop") and not XLuaUiManager.IsUiShow("UiPurchase") then
            return
        end

        if XDataCenter.TaskManager.CheckConsumeTaskHaveReward() then
            XUiManager.DialogTip(CSXTextManagerGetText("ActivityConsumeRewardDialogTipTitle"), CSXTextManagerGetText("ActivityConsumeRewardDialogTipContent"), XUiManager.DialogType.OnlySure)
        end
    end

    function XActivityManager.SaveInGameNoticeReadList(activityId)
        if not XActivityManager.IsActivityOpen(activityId) then return end
        HaveReadActivityIds[activityId] = true

        local saveContent = ""
        for id in pairs(HaveReadActivityIds) do
            saveContent = saveContent .. id .. '\t'
        end

        CSUnityEnginePlayerPrefs.SetString(XActivityManager.GetCookieKeyStr(), saveContent)
        CSUnityEnginePlayerPrefs.Save()

        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
    end

    function XActivityManager.CheckTaskSkipRedPoint(skipType)
        if not XFunctionManager.IsCanSkip(skipType) then
            return false
        end

        if skipType == XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_Qu
        or skipType == XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_LuNa
        or skipType == XActivityConfigs.TaskPanelSkipType.CanZhangHeMing_SP
        then
            return XRedPointConditionFuBenDragPuzzleGameRed.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.ChrismasTree_Dress then
            return XRedPointConditionChristmasTree.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.Couplet_Game then
            return XRedPointConditionCoupletGameRed.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.InvertCard_Game then
            return XRedPointConditionInvertCardGameRed.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.LivWarmPop_Game then
            return XRedPointConditionLivWarmActivity.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.DiceGame then
            return XRedPointConditionDiceGameRed.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.BodyCombineGame then
            return XRedPointBodyCombineGameMain.Check()
        elseif skipType == XActivityConfigs.TaskPanelSkipType.InvertCardGame2 then
            return XRedPointConditionInvertCardGameRed.Check()
        end
    end
    
    --链接类型的公告红点需要特殊处理 存在两种类型1.只显示一次的类型  2.每天都显示一次的类型
    function XActivityManager.HandleLinkActivityRedPoint(activityId)
        if not XActivityManager.IsActivityOpen(activityId) then
            return
        end
        
        local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
        local linkCfg = XActivityConfigs.GetActivityLinkCfg(activityCfg.Params[1])
        --只显示一次的类型，按照以前的方式处理
        if linkCfg.RedPointType == 1 then
            HaveReadActivityIds[activityId] = true
            local saveContent = ""
            for id in pairs(HaveReadActivityIds) do
                saveContent = saveContent .. id .. '\t'
            end

            CSUnityEnginePlayerPrefs.SetString(XActivityManager.GetCookieKeyStr(), saveContent)
            CSUnityEnginePlayerPrefs.Save()
            XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
        end
        --每天都显示一次的类型，保存每天5点的时间戳，然后用这个做比较
        if linkCfg.RedPointType == 2 then
            local todayTime = XTime.GetSeverTodayFreshTime()
            SavedTimeDataDic[activityId] = todayTime
            local saveContent = ""
            for id, time in pairs(SavedTimeDataDic) do
                saveContent = string.format("%s%d%s%d%s", saveContent, id, '|', time, '\t')
            end
            CSUnityEnginePlayerPrefs.SetString(XActivityManager.GetTodayTimeKeyStr(), saveContent)
            CSUnityEnginePlayerPrefs.Save()
            XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_ACTIVITIES_READ_CHANGE)
        end
    end

    --点击链接的时候通知后端任务已经完成
    function XActivityManager.TellFinishLinkTask(taskId, cb)
        local req = { ClientTaskType = taskId }
        XNetwork.Call(METHOD_NAME.LinkTaskFinished, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- [ 海外新增(Rooot活动)
    XActivityManager.RoootData = {
        Token = nil,
        StartTime = nil,
        ExchangeEndTime = nil,
    }
    function XActivityManager.OpenRoootUrl(hostUrl)
        if not hostUrl or hostUrl == "" then
            XUiManager.TipText("RoootActivityUrlError")
            return
        end
        if XActivityManager.RoootData.Token and XActivityManager.RoootData.StartTime and XActivityManager.RoootData.ExchangeEndTime then
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime < XActivityManager.RoootData.StartTime or nowTime > XActivityManager.RoootData.ExchangeEndTime then
                XUiManager.TipText("RoootActivityNotInTime")
            end
            local fullUrl = hostUrl.."?associate_token="..XActivityManager.RoootData.Token
            CS.UnityEngine.Application.OpenURL(fullUrl)
        else
            XNetwork.Call("RoootAuthRequest", {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XActivityManager.RoootData.Token = res.Token
                XActivityManager.RoootData.StartTime = res.StartTime
                XActivityManager.RoootData.ExchangeEndTime = res.ExchangeEndTime
                local fullUrl = hostUrl.."?associate_token="..XActivityManager.RoootData.Token
                CS.UnityEngine.Application.OpenURL(fullUrl)
            end)
        end
    end
    -- ]

    XActivityManager.Init()

    return XActivityManager
end
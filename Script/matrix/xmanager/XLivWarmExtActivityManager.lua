XLivWarmExtActivityCreator = function()
    local pairs = pairs
    local stringFormat = string.format

    local XLivWarmExtActivityManager = {}

    -----------------活动入口 begin----------------
    local _ActivityId = XLivWarmExtActivityConfig.GetDefaultActivityId() --当前开放活动Id
    local _ActivityEnd = false --活动是否结束
    local CheckLivExtBtnInterval = CS.XGame.ClientConfig:GetInt("LivExtBtnInterval")
    local LivWarmExtTimeId = 0


    local function UpdateActivityId(activityId)
        XCountDown.RemoveTimer(XCountDown.GTimerName.LivWarmExActivity)

        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XLivWarmExtActivityConfig.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId

        local nowTime = XTime.GetServerNowTimestamp()
        local leftTime = XLivWarmExtActivityManager.GetEndTime() - nowTime
        if leftTime > 0 then
            XCountDown.CreateTimer(XCountDown.GTimerName.LivWarmExActivity, leftTime)
        end
    end

    function XLivWarmExtActivityManager.GetActivityName()
        return XLivWarmExtActivityConfig.GetActivityName(_ActivityId)
    end

    function XLivWarmExtActivityManager.GetActivityId()
        return _ActivityId
    end

    function XLivWarmExtActivityManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XLivWarmExtActivityManager.GetStartTime()
        local endTime = XLivWarmExtActivityManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XLivWarmExtActivityManager.GetStartTime()
        local startTime = XLivWarmExtActivityConfig.GetActivityStartTime(_ActivityId)
        return startTime
    end

    function XLivWarmExtActivityManager.GetEndTime()
        local endTime = XLivWarmExtActivityConfig.GetActivityEndTime(_ActivityId)
        return endTime
    end

    function XLivWarmExtActivityManager.GetCurrActivityTime()
        return XLivWarmExtActivityManager.GetStartTime(), XLivWarmExtActivityManager.GetEndTime()
    end

    function XLivWarmExtActivityManager.GetLeftTimeStamp()
        local endTime = XLivWarmExtActivityManager.GetEndTime()
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
    end

    function XLivWarmExtActivityManager.SetActivityEnd()
        _ActivityEnd = true

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_END)
    end

    function XLivWarmExtActivityManager.ClearActivityEnd()
        _ActivityEnd = nil
    end

    function XLivWarmExtActivityManager.CheckActivityIsOpen()
        if not XLivWarmExtActivityManager.IsOpen() then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end
            XLivWarmExtActivityManager.ClearActivityEnd()
            XUiManager.TipText("ActivityMainLineEnd")
            XLuaUiManager.RunMain()
            return false
        end
        return true
    end
    -----------------活动入口 end----------------
    ----------红点-----
    --检查红点判断任务可领取
    function XLivWarmExtActivityManager.CheckTaskRedPoint()
        return XDataCenter.TaskManager.GetIsRewardFor(TaskType.LivWarmExtActivity)
    end

    function XLivWarmExtActivityManager.CheckTimeRedPoint()
        local length = XLivWarmExtActivityConfig.GetLivWarmExtTimelineLength()
        local timeId
        local isInTime
        for i = 1, length do
            timeId = XLivWarmExtActivityConfig.GetLivWarmExtTimelineTimeId(i)
            isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
            if isInTime then
                if not XLivWarmExtActivityManager.CheckEverClickIndex(i) then
                    return true
                end
            end
        end
        return false
    end

    --检查是否有未点击过的按钮
    function XLivWarmExtActivityManager.CheckEverClickIndex(clickIndex)
        local clickData = XSaveTool.GetData(stringFormat("%d_%d_XLivWarmExtActivityManager_CookieKeyClickIndex_%d", XPlayer.Id, _ActivityId,clickIndex))
        return clickData and true or false
    end

    function XLivWarmExtActivityManager.SaveClickIndex(clickIndex)
        local clickData = XSaveTool.GetData(stringFormat("%d_%d_XLivWarmExtActivityManager_CookieKeyClickIndex_%d", XPlayer.Id, _ActivityId,clickIndex))
        if not clickData then
            XSaveTool.SaveData(stringFormat("%d_%d_XLivWarmExtActivityManager_CookieKeyClickIndex_%d", XPlayer.Id, _ActivityId,clickIndex), true)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_CLICK,clickIndex)
        end
    end
    --------红点end-----

    local function ResetData()
		if not XTool.IsNumberValid(LivWarmExtTimeId) then
        	XScheduleManager.UnSchedule(LivWarmExtTimeId)
		end
        XLivWarmExtActivityManager.SetActivityEnd()
        _ActivityId = 0 --当前开放活动Id
        LivWarmExtTimeId = 0
    end

    function XLivWarmExtActivityManager.NotifyLivWarmExtActivityOnChange(data)
        local data = data.ExtActivityDb

        if XTool.IsNumberValid(_ActivityId) and data.ActivityId ~= _ActivityId then
            ResetData()
            XLivWarmExtActivityManager.Init()
        end
        UpdateActivityId(data.ActivityId)
    end

    function XLivWarmExtActivityManager.Init()
        LivWarmExtTimeId = XScheduleManager.ScheduleForever(function()
            XEventManager.DispatchEvent(XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_TIME)
        end,CheckLivExtBtnInterval,0)
    end

    XLivWarmExtActivityManager.Init()

    return XLivWarmExtActivityManager
end
---------------------Notify begin------------------
XRpc.NotifyLivWarmExtActivityOnChange = function(data)
    XDataCenter.LivWarmExtActivityManager.NotifyLivWarmExtActivityOnChange(data)
end
---------------------Notify end------------------    
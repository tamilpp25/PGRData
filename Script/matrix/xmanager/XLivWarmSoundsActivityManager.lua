XLivWarmSoundsActivityCreator = function()
    local pairs = pairs
    local stringFormat = string.format

    local XLivWarmSoundsActivityManager = {}

    -----------------活动入口 begin----------------
    local _ActivityId = XLivWarmSoundsActivityConfig.GetDefaultActivityId() --当前开放活动Id
    local _ActivityEnd = false --活动是否结束


    local function UpdateActivityId(activityId)
        XCountDown.RemoveTimer(XCountDown.GTimerName.LivWarmSoundsActivity)

        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XLivWarmSoundsActivityConfig.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId

        local nowTime = XTime.GetServerNowTimestamp()
        local leftTime = XLivWarmSoundsActivityManager.GetEndTime() - nowTime
        if leftTime > 0 then
            XCountDown.CreateTimer(XCountDown.GTimerName.LivWarmSoundsActivity, leftTime)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STATUS_CHANGE)
    end

    function XLivWarmSoundsActivityManager.GetActivityName()
        return XLivWarmSoundsActivityConfig.GetActivityName(_ActivityId)
    end

    function XLivWarmSoundsActivityManager.GetActivityId()
        return _ActivityId
    end

    function XLivWarmSoundsActivityManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XLivWarmSoundsActivityManager.GetStartTime()
        local endTime = XLivWarmSoundsActivityManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XLivWarmSoundsActivityManager.GetStartTime()
        local timerId = XLivWarmSoundsActivityConfig.GetActivityTimeId(_ActivityId)
        local startTime = XFunctionManager.GetStartTimeByTimeId(timerId)
        return startTime
    end

    function XLivWarmSoundsActivityManager.GetEndTime()
        local timerId = XLivWarmSoundsActivityConfig.GetActivityTimeId(_ActivityId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(timerId)
        return endTime
    end

    function XLivWarmSoundsActivityManager.GetCurrActivityTime()
        return XLivWarmSoundsActivityManager.GetStartTime(), XLivWarmSoundsActivityManager.GetEndTime()
    end

    function XLivWarmSoundsActivityManager.GetLeftTimeStamp()
        local endTime = XLivWarmSoundsActivityManager.GetEndTime()
        return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
    end

    function XLivWarmSoundsActivityManager.SetActivityEnd()
        _ActivityEnd = true

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_END)
    end

    function XLivWarmSoundsActivityManager.ClearActivityEnd()
        _ActivityEnd = nil
    end

    function XLivWarmSoundsActivityManager.OnActivityEnd()
        if not _ActivityEnd then
            return false
        end

        if CS.XFight.IsRunning
                or XLuaUiManager.IsUiLoad("UiLoading")
                or XLuaUiManager.IsUiLoad("UiSettleLose")
                or XLuaUiManager.IsUiLoad("UiSettleWin") then
            return false
        end

        --延迟是为了防止打断UI动画
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.RunMain()
        end, 1000)

        XLivWarmSoundsActivityManager.ClearActivityEnd()

        return true
    end

    function XLivWarmSoundsActivityManager.EnterUiMain(beforeOpenUiCb)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.KillZone) then
            return
        end

        if not XLivWarmSoundsActivityManager.IsOpen() then
            XUiManager.TipText("KillZoneActivityNotOpen")
            return
        end

        if beforeOpenUiCb then
            beforeOpenUiCb(function()
                XLuaUiManager.Open("UiLivWarmSoundsActivity")
            end)
        else
            XLuaUiManager.Open("UiLivWarmSoundsActivity")
        end
    end
    -----------------活动入口 end------------------
    -----------------关卡相关 begin------------------
    local XLivWarmSoundsStage = require("XEntity/XLivWarmActivity/XLivWarmSoundsStage")

    local _StageDic = {} --关卡记录
    local _NewStages = {} --可完成关卡


    local function GetStageInfo(stageId)
        return _StageDic[stageId]
    end

    --本地构造stageDb
    local function StageInfoInit()
        local stageIds = XLivWarmSoundsActivityConfig.GetStagesByActivityId(_ActivityId)
        for i, stageId in pairs(stageIds) do
            local stage = GetStageInfo(stageId)
            if not stage then
                stage = XLivWarmSoundsStage.New(stageId)
                _StageDic[stageId] = stage
            end
        end
    end

    local function UpdateStageInfo(data)
        local stageId = data.StageId
        local stage = GetStageInfo(stageId)
        if stage then
            stage:UpdateData(data)
        end
    end

    local function UpdateStagesInfo(data)
        --未完成的也会存储stage数据
        for _, info in pairs(data) do
            UpdateStageInfo(info)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_XLIVWARMSOUND_STAGE_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_STAGE_CHANGE)
    end

    --tip数量
    function XLivWarmSoundsActivityManager.StageTipCount(stageId)
        local stage = GetStageInfo(stageId)
        return stage and stage:GetTipCount() or 0
    end

    --tip数量是否最大
    function XLivWarmSoundsActivityManager.IsTipCountMax(stageId)
        local count = XLivWarmSoundsActivityManager.StageTipCount(stageId)
        if count >= #XLivWarmSoundsActivityConfig.GetStageHint(stageId) then
            return true
        end
        return false
    end

    --设置TipCount
    function XLivWarmSoundsActivityManager.SetTipCount(stageId)
        if not XTool.IsNumberValid(stageId) then
            return
        end
        local req = { StageId = stageId }
        XNetwork.Call("LivWarmSoundsActivityAddTipRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local stage = GetStageInfo(stageId)
            local oldTipCount = stage:GetTipCount()
            stage:SetTipCount(oldTipCount + 1)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_TIP_COUNT_CHANGE, oldTipCount + 1)
        end)
    end


    --关卡是否解锁
    function XLivWarmSoundsActivityManager.IsStageUnlock(stageId)
        local preStageId = XLivWarmSoundsActivityConfig.GetStagePreStageId(stageId)
        if XTool.IsNumberValid(preStageId) then
            return XLivWarmSoundsActivityManager.IsStageFinished(preStageId)
        end
        return true
    end

    --关卡是否通关
    function XLivWarmSoundsActivityManager.IsStageFinished(stageId)
        local stage = GetStageInfo(stageId)
        if XTool.IsTableEmpty(stage) then
            return false
        end
        return stage:IsFinished()
    end

    --关卡全部通关
    function XLivWarmSoundsActivityManager.IsAllStageFinished()
        local stageIds = XLivWarmSoundsActivityManager.GetStages()
        if not XTool.IsTableEmpty(stageIds) then
            for i, v in pairs(stageIds) do
                if not XLivWarmSoundsActivityManager.IsStageFinished(v) then
                    return false
                end
            end
        end
        return true
    end

    --关卡音效顺序
    function XLivWarmSoundsActivityManager.GetStageAnswer(stageId)
        local stageInfo = GetStageInfo(stageId)
        return stageInfo:GetAnswer()
    end

    --设置关卡音效顺序
    function XLivWarmSoundsActivityManager.SetStageAnswer(stageId, answer)
        local req = { StageId = stageId, Answer = answer }
        XNetwork.Call("LivWarmSoundsActivityChangeStageRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local stageInfo = GetStageInfo(stageId)
            stageInfo:SetAnswer(answer)
            stageInfo:SetIsWin(res.IsWin)
            XLivWarmSoundsActivityManager.UpdateNewStage()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CHANGE)
        end)
    end

    --本地设置关卡音效顺序
    function XLivWarmSoundsActivityManager.SetClientStageAnswer(stageId, answer)
        local stageInfo = GetStageInfo(stageId)
        stageInfo:SetAnswer(answer)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_STAGE_AUDIO_CLIENT_CHANGE)
    end

    --获取当前活动id下的所有stage
    function XLivWarmSoundsActivityManager.GetStages()
        return XLivWarmSoundsActivityConfig.GetStagesByActivityId(_ActivityId)
    end

    function XLivWarmSoundsActivityManager.GetIsActCanOpen()
        local stageIds = XLivWarmSoundsActivityManager.GetStages()
        local conditionId
        local desc
        local isPass
        table.sort(stageIds)
        for i, stageId in ipairs(stageIds) do
            conditionId = XLivWarmSoundsActivityConfig.GetStageCondition(stageId)
            isPass, desc = XConditionManager.CheckCondition(conditionId, stageId)
            return isPass, desc
        end
        return false
    end

    --打脸提示
    function XLivWarmSoundsActivityManager.CheckShowHelp()
        local IsShow = false
        local hitFaceData = XSaveTool.GetData(stringFormat("%d_%d_XLivWarmSoundsActivityManager_CookieKeyNewFirstOpen", XPlayer.Id, _ActivityId))
        if not hitFaceData then
            IsShow = true
            XSaveTool.SaveData(stringFormat("%d_%d_XLivWarmSoundsActivityManager_CookieKeyNewFirstOpen", XPlayer.Id, _ActivityId), true)
        end
        return IsShow
    end

    ------新开启关卡----
    function XLivWarmSoundsActivityManager.UpdateNewStage()
        local stageIds = XLivWarmSoundsActivityManager.GetStages()
        local conditionId
        _NewStages = {}
        for _, stageId in pairs(stageIds) do
            --关卡解锁且未通关
            conditionId = XLivWarmSoundsActivityConfig.GetStageCondition(stageId)
            if not XLivWarmSoundsActivityManager.IsStageFinished(stageId) and XConditionManager.CheckCondition(conditionId, stageId) then
                _NewStages[stageId] = stageId
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_NEW_STAGE_CHANGE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_XLIVWARMSOUND_ACTIVITY_NEW_STAGE_CHANGE)
    end

    --检查有没有新关卡
    function XLivWarmSoundsActivityManager.CheckIsHasNewStage()
        return not XTool.IsTableEmpty(_NewStages) and true or false
    end

    --最新关卡
    function XLivWarmSoundsActivityManager.GetTheNewestStage()
        local newest = 1
        if not XTool.IsTableEmpty(_NewStages) then
            for stageId in pairs(_NewStages) do
                if newest <= stageId then
                    newest = stageId
                end
            end
        end
        return newest
    end

    -----------------关卡相关 end------------------
    ----------红点-----
    --检查红点判断任务可领取
    function XLivWarmSoundsActivityManager.CheckTaskRedPoint()
        return XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.LivWarmSoundsActivity)
    end

    --检查红点判断有没有新关卡
    function XLivWarmSoundsActivityManager.CheckNewStageRedPoint()
        return XLivWarmSoundsActivityManager.CheckIsHasNewStage()
    end

    function XLivWarmSoundsActivityManager.CheckRedPoint()
        local result = XLivWarmSoundsActivityManager.CheckIsHasNewStage() or XLivWarmSoundsActivityManager.CheckTaskRedPoint()
        return result
    end

    --------红点end-----

    local function ResetData()
        XLivWarmSoundsActivityManager.SetActivityEnd()

        _ActivityId = 0 --当前开放活动Id
        _StageDic = {} --关卡记录
        _NewStages = {}
    end

    function XLivWarmSoundsActivityManager.NotifyLivWarmSoundsActivityOnChange(data)
        local data = data.ActivityDb

        if XTool.IsNumberValid(_ActivityId) and data.ActivityId ~= _ActivityId then
            ResetData()
            XLivWarmSoundsActivityManager.Init()
        end

        UpdateActivityId(data.ActivityId)
        UpdateStagesInfo(data.StageDbs)
        XLivWarmSoundsActivityManager.UpdateNewStage()
    end

    function XLivWarmSoundsActivityManager.Init()
        StageInfoInit()
    end

    XLivWarmSoundsActivityManager.Init()

    return XLivWarmSoundsActivityManager
end
---------------------Notify begin------------------
XRpc.NotifyLivWarmSoundsActivityOnChange = function(data)
    XDataCenter.LivWarmSoundsActivityManager.NotifyLivWarmSoundsActivityOnChange(data)
end
---------------------Notify end------------------    
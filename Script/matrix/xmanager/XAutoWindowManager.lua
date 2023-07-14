XAutoWindowManagerCreator = function()
    local XAutoWindowManager = {}

    local AutoWindowList = {}               -- 当前自动弹窗列表
    local AutoWindowIndex = 0               -- 当前自动弹出索引
    local IsFirstOpenAutoWindow = true      -- 是否第一次打开自动弹窗

    local SetPlayerPrefs = function(key, count)
        local needSave = false
        if CS.UnityEngine.PlayerPrefs.HasKey(key) then
            local showCount = CS.UnityEngine.PlayerPrefs.GetInt(key)
            if showCount < count then
                needSave = true
                CS.UnityEngine.PlayerPrefs.SetInt(key, showCount + 1)
            end
        else
            needSave = true
            CS.UnityEngine.PlayerPrefs.SetInt(key, 1)
        end
        return needSave
    end

    -- 检查周期内是否弹窗
    local CheckAutoType = function(autoType, count, configId, openTime)
        local needSave = false

        local now = XTime.GetServerNowTimestamp()
        local dateTime = CS.XDateUtil.GetGameDateTime(now)

        if autoType == XAutoWindowConfigs.AutoType.EachTime then
            return true
        elseif autoType == XAutoWindowConfigs.AutoType.EachDay then
            local dayZero = dateTime.Date:ToTimestamp()
            local key = XPrefs.AutoWindowEach .. tostring(XPlayer.Id) .. dayZero .. configId
            needSave = SetPlayerPrefs(key, count)
        elseif autoType == XAutoWindowConfigs.AutoType.EachWeek then
            local weekZero = CS.XDateUtil.GetFirstDayOfThisWeek(dateTime):ToTimestamp()
            local key = XPrefs.AutoWindowEach .. tostring(XPlayer.Id) .. weekZero .. configId
            needSave = SetPlayerPrefs(key, count)
        elseif autoType == XAutoWindowConfigs.AutoType.EachMonth then
            local monthZero = CS.XDateUtil.GetFirstDayOfThisMonth(dateTime):ToTimestamp()
            local key = XPrefs.AutoWindowEach .. tostring(XPlayer.Id) .. monthZero .. configId
            needSave = SetPlayerPrefs(key, count)
        elseif autoType == XAutoWindowConfigs.AutoType.Period then
            local key = XPrefs.AutoWindowPeriod .. tostring(XPlayer.Id) .. openTime .. configId
            needSave = SetPlayerPrefs(key, count)
        elseif autoType == XAutoWindowConfigs.AutoType.EachDayOffset then
            local key = ""
            local dayZero = dateTime.Date:ToTimestamp()
            if dateTime.Hour < 7 then
                key = XPrefs.AutoWindowEach .. tostring(XPlayer.Id) .. (dayZero - 86400) .. configId
            else
                key = XPrefs.AutoWindowEach .. tostring(XPlayer.Id) .. (dayZero) .. configId
            end
            needSave = SetPlayerPrefs(key, count)
            return needSave
        end

        if needSave then
            CS.UnityEngine.PlayerPrefs.Save()
        end

        return needSave
    end

    -- 开始自动弹窗
    function XAutoWindowManager.StartAutoWindow(justSignIn)
        if AutoWindowIndex <= 0 then
            AutoWindowList = {}
        elseif AutoWindowIndex > 0 and not justSignIn then
            AutoWindowIndex = AutoWindowIndex - 1
            XAutoWindowManager.NextAutoWindow()
            return true
        end

        AutoWindowIndex = 0
        local autoWindowControllerConfig = XAutoWindowConfigs.GetAutoWindowControllerConfig()
        for _, v in pairs(autoWindowControllerConfig) do
            for _, k in pairs(AutoWindowList) do
                if k.Id == v.Id then
                    goto continue
                end
            end

            if justSignIn and v.FunctionType ~= XAutoWindowConfigs.AutoFunctionType.Sign then
                goto continue
            end

            -- 对回归活动特殊处理，是否打脸不走配置表，而是根据外部接口来判断
            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Regression then
                if XDataCenter.RegressionManager.CheckNeedAutoWindow() then
                    table.insert(AutoWindowList, v)
                end
                goto continue
            end

            -- 对新回归活动特殊处理
            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewRegression then
                if XDataCenter.NewRegressionManager.CheckIsNeedAutoWindow() then
                    table.insert(AutoWindowList, v)
                end
                goto continue
            end

            local openTime = XFunctionManager.GetStartTimeByTimeId(v.TimeId)
            if not XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                goto continue
            end

            if v.ConditionId > 0 and not XConditionManager.CheckCondition(v.ConditionId) then
                goto continue
            end

            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Sign then
                local paramId = XFunctionConfig.GetParamId(v.SkipId)
                local subConfigId = XSignInConfigs.GetWelfareConfig(paramId).SubConfigId
                if not XDataCenter.SignInManager.IsShowSignIn(subConfigId)
                   or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.SignIn) then
                    goto continue
                end
                XDataCenter.SignInManager.SetNotifySign(false)
            end

            if not CheckAutoType(v.AutoType, v.AutoCount, v.Id, openTime) then
                goto continue
            end
            
            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.NewYearZhanBu then
                if XDataCenter.SignInManager.GetTodayDiviningState() then
                    goto continue
                end
            end
            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Fireworks then
                if not XDataCenter.FireworksManager.HasAvailableFireTimes() then
                    goto continue
                end
            end
            table.insert(AutoWindowList, v)
            :: continue ::
        end

        if #AutoWindowList <= 0 then
            return false
        end

        table.sort(AutoWindowList, function(a, b)
            return a.Pre > b.Pre
        end)

        XAutoWindowManager.NextAutoWindow()
        return true
    end

    -- 下一个动弹窗
    function XAutoWindowManager.NextAutoWindow()
        AutoWindowIndex = AutoWindowIndex + 1
        if AutoWindowIndex > #AutoWindowList then
            XAutoWindowManager.ClearAutoWindow()
            XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_END)
            return
        end

        XFunctionManager.SkipInterface(AutoWindowList[AutoWindowIndex].SkipId)
    end

    -- 结束自动弹窗
    function XAutoWindowManager.StopAutoWindow()
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)

        if AutoWindowIndex <= 0 then
            AutoWindowList = {}
            return
        end

        -- 判断是否需要继续弹窗
        if AutoWindowList[AutoWindowIndex].ContinueOpen then
           return
        end

        XAutoWindowManager.ClearAutoWindow()
    end

    -- 清除自动弹窗
    function XAutoWindowManager.ClearAutoWindow()
        AutoWindowList = {}
        AutoWindowIndex = 0
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)
    end

    function XAutoWindowManager.CheckAutoWindow()
        if XUiManager.IsHideFunc then return false end
        if IsFirstOpenAutoWindow then
            IsFirstOpenAutoWindow = false
            return XAutoWindowManager.StartAutoWindow()
        end

        return XAutoWindowManager.CheckContinueAutoWindow()
    end

    -- 检查是否继续自动弹窗
    function XAutoWindowManager.CheckContinueAutoWindow()
        -- 检查是否有推送签到
        local isNotifySignIn = XDataCenter.SignInManager.CheckNotifySign()
        local isContinueAuto = AutoWindowIndex > 0

        if not isNotifySignIn and not isContinueAuto then     -- 没有推送签到，没有继续弹窗
            return false
        elseif not isNotifySignIn and isContinueAuto then     -- 没有推送签到，有继续弹窗
            return XAutoWindowManager.StartAutoWindow()
        elseif isNotifySignIn and not isContinueAuto then     -- 有推送签到，没有继续弹窗
            return XAutoWindowManager.StartAutoWindow(true)
        elseif isNotifySignIn and isContinueAuto then         -- 有推送签到，有继续弹窗
            return XAutoWindowManager.StartAutoWindow(true)
        end

        return false
    end

    return XAutoWindowManager
end
XAutoWindowManagerCreator = function()
    local XAutoWindowManager = {}

    local AutoWindowList = {}               -- 当前自动弹窗列表
    local PassedWindowDic = {}              -- 已显示过的弹窗列表
    local CurWindow = nil                 -- 当前展示弹窗
    local IsFirstOpenAutoWindow = true      -- 是否第一次打开自动弹窗，打开过一次后标记为false

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
        end

        if needSave then
            CS.UnityEngine.PlayerPrefs.Save()
        end

        return needSave
    end

    -- 开始自动弹窗
    function XAutoWindowManager.StartAutoWindow(justSignIn)
        if CurWindow and not justSignIn then
            XAutoWindowManager.NextAutoWindow()
            return true
        end

        AutoWindowList = {}
        PassedWindowDic = {}
        CurWindow = nil

        XAutoWindowManager.CheckAddWindow()
        local isShow = #AutoWindowList > 0
        if isShow then
            XAutoWindowManager.NextAutoWindow()
        end
        return isShow
    end
    
    -- 检测添加弹窗数据
    function XAutoWindowManager.CheckAddWindow()
        local autoWindowControllerConfig = XAutoWindowConfigs.GetAutoWindowControllerConfig()
        for _, v in pairs(autoWindowControllerConfig) do
            -- 已有相同弹窗
            if PassedWindowDic[v.Id] then
                goto continue
            end
            for _, k in pairs(AutoWindowList) do
                if k.Id == v.Id then
                    goto continue
                end
            end

            --[[
            if justSignIn then
                if v.FunctionType ~= XAutoWindowConfigs.AutoFunctionType.Sign and
                    v.FunctionType ~= XAutoWindowConfigs.AutoFunctionType.WeekCard
                then
                    goto continue
                end
            end
            ]]

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

            -- 对回归活动特殊处理
            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.Regression3rd then
                if XDataCenter.Regression3rdManager.CheckOpenAutoWindow() then
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

            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.SClassConstructNovice then
                local paramId = XFunctionConfig.GetParamId(v.SkipId)
                local subConfigId = XSignInConfigs.GetWelfareConfig(paramId).SubConfigId
                local signInData = XDataCenter.SignInManager.GetSignInData(subConfigId)
                if not signInData or (signInData and signInData.Got) then
                    goto continue
                end
            end

            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.SummerSignIn then
                if not XDataCenter.SummerSignInManager.CheckIsNeedAutoWindow() then
                    goto continue
                end
            end

            if not CheckAutoType(v.AutoType, v.AutoCount, v.Id, openTime) then
                goto continue
            end

            if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.SUBPACKAGE.ENTRY_TYPE.AUTO_WINDOW, v.Id, true) then
                goto continue
            end

            if v.FunctionType == XAutoWindowConfigs.AutoFunctionType.WeekCard then
                local paramId = XFunctionConfig.GetParamId(v.SkipId)
                local subConfigId = XSignInConfigs.GetWelfareConfig(paramId).SubConfigId
                local weekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(subConfigId)
                if not weekCardData or weekCardData.IsGotToday then -- 没数据代表领过了或者没买
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
    end

    -- 下一个动弹窗
    function XAutoWindowManager.NextAutoWindow()
        XAutoWindowManager.CheckAddWindow()
        if #AutoWindowList <= 0 then
            XAutoWindowManager.ClearAutoWindow()
            XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_END)
            return
        end

        local window = table.remove(AutoWindowList, 1)
        PassedWindowDic[window.Id] = window
        CurWindow = window
        XFunctionManager.SkipInterface(CurWindow.SkipId)
    end

    -- 结束自动弹窗
    function XAutoWindowManager.StopAutoWindow()
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)

        if not CurWindow then
            AutoWindowList = {}
            PassedWindowDic = {}
            CurWindow = nil
            return
        end

        -- 判断是否需要继续弹窗
        if CurWindow.ContinueOpen then
           return
        end

        XAutoWindowManager.ClearAutoWindow()
    end

    -- 清除自动弹窗
    function XAutoWindowManager.ClearAutoWindow()
        AutoWindowList = {}
        PassedWindowDic = {}
        CurWindow = nil
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)
    end

    function XAutoWindowManager.CheckAutoWindow()
        if XUiManager.IsHideFunc then return false end
        if IsFirstOpenAutoWindow then
            IsFirstOpenAutoWindow = false
            return XAutoWindowManager.StartAutoWindow()
        end

        local res = XAutoWindowManager.CheckContinueAutoWindow()
        return res
    end
    
    function XAutoWindowManager.CheckCanPlayActionByAutoWindow()
        local res = XTool.IsTableEmpty(AutoWindowList) and not IsFirstOpenAutoWindow
        return res
    end

    -- 检查是否继续自动弹窗
    function XAutoWindowManager.CheckContinueAutoWindow()
        -- 检查是否有推送签到
        local isNotifySignIn = XDataCenter.SignInManager.CheckNotifySign()
        local isContinueAuto = #AutoWindowList > 0

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
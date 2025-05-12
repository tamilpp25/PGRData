XNewRegressionManagerCreator = function()
    local DAY_SECOND = 24 * 60 * 60
    local XNewRegressionManager = {}
    local Config = nil
    -- 签到管理
    local SignInManager = nil
    -- 邀请管理
    local InviteManager = nil
    -- 受邀管理
    local FettersManager = nil
    -- 抽奖管理字典
    -- 和服务器对过，在时间较长的情况下理论存在两种抽奖
    local GachaManagerDic = nil
    -- 任务管理
    local TaskManager = nil
    -- 优惠商店管理
    local ShopManager = nil
    -- 玩家自身活动开启时间
    local BeginTime = nil
    -- 活动状态 XNewRegressionConfigs.ActivityState
    local ActivityState = XNewRegressionConfigs.ActivityState.None
    -- 激活的子活动管理器
    local EnableChildManagers = nil

    -- data : XRegression2DataDb
    function XNewRegressionManager.InitWithServerData(data)
        -- 活动数据
        local activityData = data.ActivityData
        -- 防御服务器推送空数据
        if activityData == nil then return end
        Config = XNewRegressionConfigs.GetActivityConfig(activityData.Id)
        BeginTime = activityData.BeginTime
        ActivityState = activityData.State
        -- 清空子活动管理器
        EnableChildManagers = {}
        -- 签到数据
        if data.SignInData then
            XNewRegressionManager.GetSignInManager():InitWithServerData(data.SignInData)
            XNewRegressionManager.GetSignInManager():SetContinueDay(Config.ContinueDays)
            XNewRegressionManager.GetSignInManager():SetBeginTime(BeginTime)
            table.insert(EnableChildManagers, XNewRegressionManager.GetSignInManager())
        end
        -- 邀请数据
        if data.InviteData then
            XNewRegressionManager.GetInviteManager():InitWithServerData(data.InviteData)
            table.insert(EnableChildManagers, XNewRegressionManager.GetInviteManager())
            table.insert(EnableChildManagers, XNewRegressionManager.GetFettersManager())
        end
        -- 抽奖数据
        if data.GachaDatas then
            for _, gachaData in ipairs(data.GachaDatas) do
                if XNewRegressionConfigs.GetGachaConfig(gachaData.Id) ~= nil then
                    XNewRegressionManager.GetGachaManager(gachaData.Id):InitWithServerData(gachaData)
                    XNewRegressionManager.GetGachaManager(gachaData.Id):SetBeginTime(BeginTime)
                    table.insert(EnableChildManagers, XNewRegressionManager.GetGachaManager(gachaData.Id))
                end
            end
        end
        -- 任务数据
        -- 回归玩家的任务
        if ActivityState == XNewRegressionConfigs.ActivityState.InRegression and Config.InRegressionTaskId > 0 then
            XNewRegressionManager.GetTaskManager():InitWithConfigId(Config.InRegressionTaskId)
            table.insert(EnableChildManagers, XNewRegressionManager.GetTaskManager())
        -- 活跃玩家的任务
        elseif ActivityState == XNewRegressionConfigs.ActivityState.NotInRegression and Config.NotInRegressionTaskId > 0 then
            XNewRegressionManager.GetTaskManager():InitWithConfigId(Config.NotInRegressionTaskId)
            table.insert(EnableChildManagers, XNewRegressionManager.GetTaskManager())
        end
        -- --优惠商店
        local shopManager = XNewRegressionManager.GetShopManager()
        table.insert(EnableChildManagers, shopManager)
    end

    -- 检查是否需要自动弹窗
    function XNewRegressionManager.CheckIsNeedAutoWindow()
        if ActivityState ~= XNewRegressionConfigs.ActivityState.InRegression then
            return false
        end
        if XSaveTool.GetData(XNewRegressionManager.GetLocalSaveKey() .. "CheckIsNeedAutoWindow") then
            return false
        end
        XSaveTool.SaveData(XNewRegressionManager.GetLocalSaveKey() .. "CheckIsNeedAutoWindow", true)
        return true
    end

    function XNewRegressionManager.GetLocalSaveKey()
        return Config.Id .. XPlayer.Id .. "XNewRegressionManager"
    end

    function XNewRegressionManager.GetSignInManager()
        if SignInManager == nil then
            local script = require("XEntity/XNewRegression/Sign/XSignInManager")
            SignInManager = script.New(Config.Id)
        end
        return SignInManager
    end

    function XNewRegressionManager.GetInviteManager()
        if InviteManager == nil then
            local script = require("XEntity/XNewRegression/Invite/XInviteManager")
            InviteManager = script.New()
        end
        return InviteManager
    end

    function XNewRegressionManager.GetFettersManager()
        if FettersManager == nil then
            local script = require("XEntity/XNewRegression/Invite/XFettersManager")
            FettersManager = script.New()
        end
        return FettersManager
    end

    function XNewRegressionManager.GetGachaManager(id)
        GachaManagerDic = GachaManagerDic or {}
        if GachaManagerDic[id] == nil then
            local script = require("XEntity/XNewRegression/Gacha/XGachaManager")
            GachaManagerDic[id] = script.New(id)
        end
        return GachaManagerDic[id]
    end

    function XNewRegressionManager.GetTaskManager()
        if TaskManager == nil then
            local script = require("XEntity/XNewRegression/Task/XTaskManager")
            TaskManager = script.New()
        end
        return TaskManager
    end

    function XNewRegressionManager.GetShopManager()
        if ShopManager == nil then
            local script = require("XEntity/XNewRegression/Discount/XDiscountManager")
            ShopManager = script.New()
        end
        return ShopManager
    end

    function XNewRegressionManager.OpenMainUi()
        if not XNewRegressionManager.GetIsOpen(true) then
            return
        end
        --活动分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        XLuaUiManager.Open("UiReturnActivity")
    end

    function XNewRegressionManager.GetAssetItemIds()
        local result = {}
        -- 避免重复的情况
        local hashMap = {}
        local consumeId
        for id, manager in pairs(GachaManagerDic or {}) do
            consumeId = manager:GetConsumeId()
            if hashMap[consumeId] == nil then
                table.insert(result, consumeId)
            end
            hashMap[consumeId] = true
        end
        return result
    end

    -- 获取活动状态
    function XNewRegressionManager.GetActivityState()
        return ActivityState
    end

    function XNewRegressionManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end

    -- 获取活动开始时间
    function XNewRegressionManager.GetStartTime(activityState)
        if activityState == nil then activityState = ActivityState end
        -- 回归用户
        if activityState == XNewRegressionConfigs.ActivityState.InRegression then
            return BeginTime
        -- 活跃用户
        elseif activityState == XNewRegressionConfigs.ActivityState.NotInRegression then
            return XNewRegressionManager.GetInviteManager():GetStartTime()
        end
        return 0
    end

    -- 获取活动结束时间
    function XNewRegressionManager.GetEndTime(activityState)
        if activityState == nil then activityState = ActivityState end
        -- 回归用户，下一天的时间为上午5点
        if activityState == XNewRegressionConfigs.ActivityState.InRegression then
            local continueDay = Config and Config.ContinueDays or 0
            local biginTime = BeginTime or 0
            local endTime = biginTime + continueDay * DAY_SECOND
            return XTime.GetTimeDayFreshTime(endTime)
        -- 活跃用户和结束回归的用户
        elseif activityState == XNewRegressionConfigs.ActivityState.NotInRegression or activityState == XNewRegressionConfigs.ActivityState.RegressionEnded then
            return XNewRegressionManager.GetInviteManager():GetEndTime()
        end
        return 0
    end

    -- 获取活动剩余时间描述
    function XNewRegressionManager.GetLeaveTimeStr(timeFormatType, activityState)
        timeFormatType = timeFormatType or XUiHelper.TimeFormatType.NEW_REGRESSION
        local activityState = activityState or XNewRegressionManager.GetActivityState()
        local endTime = XNewRegressionManager.GetEndTime(activityState)
        return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), timeFormatType)
    end

    function XNewRegressionManager.GetIsOpen(showTip)
        if Config and XPlayer.GetLevel() < Config.Level then
            if showTip then
                XUiManager.TipErrorWithKey("LevelNotEnough")
            end
            return false
        end

        local activityState = XNewRegressionManager.GetActivityState()
        if activityState ~= XNewRegressionConfigs.ActivityState.InRegression and 
            activityState ~= XNewRegressionConfigs.ActivityState.NotInRegression and 
            activityState ~= XNewRegressionConfigs.ActivityState.RegressionEnded then
                if showTip then
                    XUiManager.TipErrorWithKey("ActivityAlreadyOver")
                end
                return false
        end

        if not XNewRegressionManager.GetIsInTime(activityState) then
            if showTip then
                XUiManager.TipErrorWithKey("ActivityAlreadyOver")
            end
            return false
        end
        return true
    end

    function XNewRegressionManager.GetIsOpenByActivityState(state, showTip)
        local activityState = XNewRegressionManager.GetActivityState()
        if activityState ~= state then
            return false
        end
        return XNewRegressionManager.GetIsOpen(showTip)
    end

    -- 获取活动是否在开启时间内
    function XNewRegressionManager.GetIsInTime(activityState)
        if activityState == nil then activityState = ActivityState end
        if activityState == XNewRegressionConfigs.ActivityState.NotInRegression or activityState == XNewRegressionConfigs.ActivityState.RegressionEnded then
            return XNewRegressionManager.GetInviteManager():IsActivityOpen()
        end

        local endTime = XNewRegressionManager.GetEndTime(activityState)
        return endTime > XTime.GetServerNowTimestamp()
    end

    -- 获取活动帮助id
    function XNewRegressionManager.GetHelpId()
        return XHelpCourseConfig.GetHelpCourseTemplateById(Config.HelpId).Function
    end

    function XNewRegressionManager.GetEnableChildManagers()
        if EnableChildManagers == nil then return {} end
        local result = {}
        local manager
        -- 排除掉没有开启的
        for i = #EnableChildManagers, 1, -1 do
            manager = EnableChildManagers[i]
            if manager:GetIsOpen() then
                table.insert(result, manager)
            end
        end
        table.sort(result, function(managerA, managerB)
            return managerA:GetButtonWeight() < managerB:GetButtonWeight()
        end)
        return result
    end

    function XNewRegressionManager.GetStoryId()
        return Config.StoryId
    end

    function XNewRegressionManager.GetActivityContinueDays()
        return Config and Config.ContinueDays or 0
    end

    ------------------回归自动播放剧情 begin-------------------
    local GetLocalSavedStoryKey = function()
        local id = Config.Id or 0
        local beginTime = BeginTime or 0
        return string.format("%s%d%d%d", "NewRegressionAutoStory", XPlayer.Id, id, beginTime)
    end

    function XNewRegressionManager.CheckAutoPlayStory()
        local activityState = XNewRegressionManager.GetActivityState()
        if activityState ~= XNewRegressionConfigs.ActivityState.InRegression then
            return
        end

        local localSavedKey = GetLocalSavedStoryKey()
        if XSaveTool.GetData(localSavedKey) then
            return
        end

        local storyId = XNewRegressionManager.GetStoryId()
        if XTool.IsNumberValid(storyId) then
            XDataCenter.MovieManager.PlayMovie(storyId)
            XSaveTool.SaveData(localSavedKey, true)
        end
    end
    ------------------回归自动播放剧情 end---------------------

    return XNewRegressionManager
end

XRpc.NotifyRegression2Data = function(data)
    XDataCenter.NewRegressionManager.InitWithServerData(data.Data)
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_REGRESSION_OPEN_STATUS_UPDATE)
end

XRpc.NotifyRegression2SignInData = function(data)
    XDataCenter.NewRegressionManager.GetSignInManager():UpdateWithServerData(data)
end

XRpc.NotifyRegression2InvitePoint = function(data)
    XDataCenter.NewRegressionManager.GetInviteManager():UpdateWithServerData(data)
end

XRpc.NotifyRegression2GachaChangedGroupDatas = function(data)
    XDataCenter.NewRegressionManager.GetGachaManager(data.Id):UpdateWithServerData(data)
end

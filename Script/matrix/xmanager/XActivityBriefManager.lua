XActivityBriefManagerCreator = function()
    local MethodName = {
        FinishBrirfStory = "FinishBriefStoryRequest"
    }

    local PlayedStoryDic = {}
    local OpenSpecialActivityCount = 0
    local CloseSpecialActivityCount = 0

    local SpecialActivityMaxEndTime = 0
    local pairs = pairs
    local ParseToTimestamp = XTime.ParseToTimestamp
    local CSUnityEnginePlayerPrefs = CS.UnityEngine.PlayerPrefs

    local ActivityConfig = XActivityBriefConfigs.GetActivityConfig()
    local FirstOpenUi = nil
    local FirstConditionalOpenUi = nil
    local COOKIE_FIRSTOPENUI_KEY = "IsFirstOpen"
    local COOKIE_FIRSTCONDITIONALOPENUI_KEY = "IsFirstConditionalOpen"
    ---@class XActivityBriefManager 活动界面管理器
    local XActivityBriefManager = {}
    local MAX_MODEL_NUMBER
    local ModelRankIndex

    local CheckIsNewActivityOpen = function(newCount)
        if OpenSpecialActivityCount ~= newCount then
            OpenSpecialActivityCount = newCount
            return true
        end
        return false
    end

    local CheckIsOldActivityEnd = function(newCount)
        if CloseSpecialActivityCount ~= newCount then
            CloseSpecialActivityCount = newCount
            return true
        end
        return false
    end

    local function Init()
        for _, v in pairs(XActivityBriefConfigs.GetAllActivityEntryConfig()) do
            --2.7屏蔽仅红点检测的条目
            if XTool.IsNumberValid(v.OnlyRedPoint) then
                goto CONTINUE
            end
            
            local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
            if SpecialActivityMaxEndTime < endTime then
                SpecialActivityMaxEndTime = endTime
            end
            
            :: CONTINUE ::
        end
        --游戏一开始随机获取其中一个数，用于活动界面随机显示一个模型
        -- local models = XActivityBriefConfigs.GetActivityModels()
        -- MAX_MODEL_NUMBER = #models == 0 and 1 or #models
        -- math.randomseed(os.time())
        -- ModelRankIndex = math.random(MAX_MODEL_NUMBER) 
    end

    function XActivityBriefManager.GetSpecialActivityMaxEndTime()
        return SpecialActivityMaxEndTime
    end

    function XActivityBriefManager.GetBtnTimeId(activityGroupId)
        local config = XActivityBriefConfigs.GetActivityGroupConfig(activityGroupId)
        return config.TimeId
    end

    function XActivityBriefManager.GetActivityStoryConfig()
        local storyConfig = XActivityBriefConfigs.GetActivityStoryConfig()
        return storyConfig
    end

    function XActivityBriefManager.InitPlayedStoryTemplates(ids)
        XActivityBriefConfigs.InitPlayedStoryTemplates(ids)
    end

    function XActivityBriefManager.AddPlayedStoryId(id)
        XActivityBriefConfigs.AddPlayedStoryId(id)
    end

    function XActivityBriefManager.GetActivityConditionDescById(id)
        local desc = XActivityBriefConfigs.GetActivityConditionDescById(id)
        return desc
    end

    function XActivityBriefManager.GetActivityShopIds()
        local shopIds = {}

        local shopInfoIds = ActivityConfig.ShopInfoId
        for index, shopInfoId in ipairs(shopInfoIds) do
            shopIds[index] = XActivityBriefConfigs.GetActivityShopByInfoId(shopInfoId).ShopId
        end

        return shopIds
    end

    function XActivityBriefManager.GetActivityShopNameByShopId(shopId)
        return XShopManager.GetShopName(shopId)
    end

    function XActivityBriefManager.GetActivityShopIdByIndex(index)
        return XActivityBriefConfigs.GetActivityShopByInfoId(ActivityConfig.ShopInfoId[index]).ShopId
    end

    function XActivityBriefManager.GetActivityShopConditionByShopId(shopId)
        return XShopManager.GetShopConditionIdList(shopId)
    end

    function XActivityBriefManager.GetActivityMain3DBg(panelType)
        return XActivityBriefConfigs.GetMain3DBgPath(panelType)
    end

    function XActivityBriefManager.GetActivityTaskBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskBg
    end

    function XActivityBriefManager.GetActivityTaskGotBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGotBg
    end

    function XActivityBriefManager.GetActivityTaskVipBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskVipBg
    end

    function XActivityBriefManager.GetActivityTaskVipGotBg()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskVipGotBg
    end

    function XActivityBriefManager.GetActivityActivityPointId()
        return XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).ActivityPointId
    end

    function XActivityBriefManager.CheckTaskIsInMark(Id)
        local MaskTaskIds = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).MarkTaskId
        for _, v in pairs(MaskTaskIds or {}) do
            if v == Id then
                return true
            end
        end
        return false
    end

    function XActivityBriefManager.GetActivityShopGoodsByShopIndex(index)
        local shopId = XActivityBriefManager.GetActivityShopIdByIndex(index)
        local goods = XShopManager.GetShopGoodsList(shopId)
        return goods
    end

    function XActivityBriefManager.GetActivityTaskTime()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return end
        return XTaskConfig.GetTimeLimitTaskTime(taskGroupId)
    end

    function XActivityBriefManager.IsActivityTaskInTime()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return false end
        return XTaskConfig.IsTimeLimitTaskInTime(taskGroupId)
    end

    function XActivityBriefManager.GetActivityTaskDatas()
        local taskGroupId = XActivityBriefConfigs.GetActivityTaskByInfoId(ActivityConfig.TaskInfoId).TaskGroupId
        if taskGroupId == 0 then return {} end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    end

    function XActivityBriefManager.CheckAnyTaskFinished()
        local taskDatas = XActivityBriefManager.GetActivityTaskDatas()

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        for _, taskData in pairs(taskDatas) do
            if taskData.State == achieved then
                return true
            end
        end

        return false
    end

    function XActivityBriefManager.GetNowActivityEntryConfig()
        local nowSpecialActivityTemplates = {}
        for _,v in pairs(XActivityBriefConfigs.GetAllActivityEntryConfig()) do
            --2.7屏蔽仅红点检测的条目
            if XTool.IsNumberValid(v.OnlyRedPoint) then
                goto CONTINUE
            end
            
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) and
                    (v.Condition == 0 or XConditionManager.CheckCondition(v.Condition)) then
                table.insert(nowSpecialActivityTemplates, v)
            end

            :: CONTINUE ::

        end
        
        return nowSpecialActivityTemplates
    end
    
    function XActivityBriefManager.CheckIsNewSpecialActivityOpen()
        local newCount, oldCount = 0, 0
        local timeOfNow = XTime.GetServerNowTimestamp()
        for _,v in pairs(XActivityBriefConfigs.GetAllActivityEntryConfig()) do
            --2.7屏蔽仅红点检测的条目
            if XTool.IsNumberValid(v.OnlyRedPoint) then
                goto CONTINUE
            end
            
            local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(v.TimeId)
            local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
            --不用CheckInTimeByTimeId，避免新活动开放，旧活动结束Count不会更改
            if timeOfNow >= timeOfBgn and 
                    (v.Condition == 0 or XConditionManager.CheckCondition(v.Condition)) then
                newCount = newCount + 1
            end

            if timeOfNow > timeOfEnd then --活动过期
                oldCount = oldCount + 1
            end
            
            ::CONTINUE::
        end
        return CheckIsNewActivityOpen(newCount) or CheckIsOldActivityEnd(oldCount)
    end

    function XActivityBriefManager.CheckActivityBriefOpen()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ActivityBrief) then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        return XFunctionManager.CheckInTimeByTimeId(ActivityConfig.TimeId)
    end

    --region v1.31 入场动画判定

    -- 根据面板的入场动效类型检查是否需要播放入场动效
    function XActivityBriefManager.IsShowEnterAni(panelType)
        local enterAniCheckType = XActivityBriefConfigs.GetEnterAniCheckType(panelType)
        -- 没有特殊入场动画则不判断
        if enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.None then
            return false
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.OnlyFirst then
            return XActivityBriefManager.IsFirstOpen(panelType)
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.EveryDay then
            return XActivityBriefManager.IsTodayFirstOpen(panelType)
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.EveryLogin then
            return XActivityBriefManager.IsLoginFirstOpen(panelType)
        end
    end

    -- v1.31 标记已经播放过
    function XActivityBriefManager.SetDontShowEnterAni(panelType)
        local enterAniCheckType = XActivityBriefConfigs.GetEnterAniCheckType(panelType)
        -- 没有特殊入场动画则不操作
        if enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.None then
            return
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.OnlyFirst then
            XActivityBriefManager.SetNotFirstOpen(panelType)
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.EveryDay then
            XActivityBriefManager.SetNotTodayFirstOpen(panelType)
        elseif enterAniCheckType == XActivityBriefConfigs.EnterAniCheckType.EveryLogin then
            XActivityBriefManager.SetNotLoginFirstOpen(panelType)
        end
    end

    -- 是否第一次进入界面
    function XActivityBriefManager.IsFirstOpen(panelType)
        if FirstOpenUi == nil then
            FirstOpenUi = not XActivityBriefManager.ReadCookie(COOKIE_FIRSTOPENUI_KEY .. panelType)
        end
        return FirstOpenUi
    end

    function XActivityBriefManager.SetNotFirstOpen(panelType)
        FirstOpenUi = false
        CSUnityEnginePlayerPrefs.SetInt(XActivityBriefManager.GetCookieKeyStr(COOKIE_FIRSTOPENUI_KEY .. panelType), 1)
        CSUnityEnginePlayerPrefs.Save()
    end

    function XActivityBriefManager.GetEveryDayFirstOpenCookieKey(panelType)
        -- 要求同步服务器5点刷新时间
        return XTime.GetServerNextTargetTime(5) .. COOKIE_FIRSTOPENUI_KEY .. panelType
    end

    -- 是否是本日第一次进入界面
    function XActivityBriefManager.IsTodayFirstOpen(panelType)
        return not XActivityBriefManager.ReadCookie(XActivityBriefManager.GetEveryDayFirstOpenCookieKey(panelType))
    end

    function XActivityBriefManager.SetNotTodayFirstOpen(panelType)
        local cookieKey = XActivityBriefManager.GetCookieKeyStr(XActivityBriefManager.GetEveryDayFirstOpenCookieKey(panelType))
        CSUnityEnginePlayerPrefs.SetInt(cookieKey, 1)
        CSUnityEnginePlayerPrefs.Save()
    end

    local LoginFirstOpen = {}
    -- 是否是本次登录第一次进入界面
    function XActivityBriefManager.IsLoginFirstOpen(panelType)
        if LoginFirstOpen[panelType] == nil then
            LoginFirstOpen[panelType] = true
        end
        return LoginFirstOpen[panelType]
    end

    function XActivityBriefManager.SetNotLoginFirstOpen(panelType)
        LoginFirstOpen[panelType] = false
    end

    --endregion


    --region v2.2 跳过入场动画功能相关

    function XActivityBriefManager.GetIsSkipAnim(panelType)
        local key = string.format("ActivityBrief_IsSkipAnim_%s_%s_%s", XPlayer.Id,panelType,ActivityConfig.TimeId)
        return XSaveTool.GetData(key)
    end

    function XActivityBriefManager.SetIsSkipAnim(panelType, active)
        local key = string.format("ActivityBrief_IsSkipAnim_%s_%s_%s", XPlayer.Id,panelType,ActivityConfig.TimeId)
        return XSaveTool.SaveData(key, active)
    end

    function XActivityBriefManager.CheckIsFirstReadedAnim(panelType)
        local key = string.format("ActivityBrief_IsFristReadVideo_%s_%s_%s", XPlayer.Id,panelType,ActivityConfig.TimeId)
        local isRead = XSaveTool.GetData(key)
        if not isRead and XActivityBriefConfigs.GetIsAfterFirstAnimSetSkip(panelType) then
            XActivityBriefManager.SetIsSkipAnim(panelType, true)
        end
        XSaveTool.SaveData(key, true)
        return isRead
    end

    --endregion


    --region v2.2 活动解锁动画相关

    ---获取需要播放解锁动画的ActivityBriefGroup
    ---@param panelType number activityBrieActivity.tab的Id
    ---@return table<number, number> 
    function XActivityBriefManager.GetNeedUnlockAnimGroupIdList(panelType)
        local needPlayAnimGroupIdList = {}
        local groupIdList = XActivityBriefConfigs.GetGroupIdList(panelType)
        for _, groupId in ipairs(groupIdList) do
            local inTime, _ = XActivityBrieIsOpen.Get(groupId)
            local isRemindWhenOpen = XTool.IsNumberValid(XActivityBriefConfigs.GetActivityBriefGroupIsRemindWhenOpen(groupId))
            -- 活动时间内,有解锁动画且解锁条件达标且没有播放缓存则加入播放列表
            if isRemindWhenOpen and inTime and not XActivityBriefManager.GetIsPlayedUnlockAnim(groupId) then
                table.insert(needPlayAnimGroupIdList, groupId)
            end
        end
        if not XTool.IsTableEmpty(needPlayAnimGroupIdList) then
            -- 播放排序
            table.sort(needPlayAnimGroupIdList, function (groupIdA, groupIdB)
                local priorityA = XActivityBriefConfigs.GetActivityBriefGroupRemindPriority(groupIdA)
                local priorityB = XActivityBriefConfigs.GetActivityBriefGroupRemindPriority(groupIdB)
                if priorityA ~= priorityB then
                    return priorityA < priorityB
                end
                return groupIdA > groupIdB
            end)
        end
        return needPlayAnimGroupIdList
    end

    ---某个特定的ActivityGroupId是否播放过解锁动画
    ---@param groupId any
    ---@return boolean
    function XActivityBriefManager.GetIsPlayedUnlockAnim(groupId)
        local key = XActivityBriefManager.IsPlayedUnlockAnimCacheKey(groupId)
        return XSaveTool.GetData(key, false)
    end

    ---设置播放过活动解锁动画缓存
    ---@param groupId number ActivityBriefGroup.tab的Id,对应XActivityBriefConfigs.ActivityGroupId
    function XActivityBriefManager.SetIsPlayedUnlockAnim(groupId)
        local key = XActivityBriefManager.IsPlayedUnlockAnimCacheKey(groupId)
        XSaveTool.SaveData(key, true)
    end

    ---是否播放过活动解锁动画缓存key
    ---@param groupId number ActivityBriefGroup.tab的Id,对应XActivityBriefConfigs.ActivityGroupId
    ---@return string
    function XActivityBriefManager.IsPlayedUnlockAnimCacheKey(groupId)
        local timeId = XActivityBriefConfigs.GetActivityBriefGroupTimeId(groupId)
        local key = string.format("ActivityBrief_IsPlayedUnlockAnim_%s_%s_%s", XPlayer.Id, groupId, timeId)
        return key
    end

    --endregion


    function XActivityBriefManager.IsAnimConditionPassed()
        local conditionId = ActivityConfig.AnimConditionId
        if conditionId == 0 then
            return false
        end
        return XConditionManager.CheckCondition(conditionId)
    end

    function XActivityBriefManager.IsFirstConditionalOpen()
        if FirstConditionalOpenUi == nil then
            FirstConditionalOpenUi = not XActivityBriefManager.ReadCookie(COOKIE_FIRSTCONDITIONALOPENUI_KEY)
        end
        return FirstConditionalOpenUi
    end

    function XActivityBriefManager.SetNotFirstConditionalOpen()
        FirstConditionalOpenUi = false
        CSUnityEnginePlayerPrefs.SetInt(XActivityBriefManager.GetCookieKeyStr(COOKIE_FIRSTCONDITIONALOPENUI_KEY), 1)
        CSUnityEnginePlayerPrefs.Save()
    end

    function XActivityBriefManager.GetCookieKeyStr(key)
        return string.format("%s%s%s", ActivityConfig.EndTimeStr, XPlayer.Id, key)
    end

    function XActivityBriefManager.ReadCookie(key)
        return CSUnityEnginePlayerPrefs.HasKey(XActivityBriefManager.GetCookieKeyStr(key))
    end


    function XActivityBriefManager.InitPlayedStoryDic(ids)
        for key, value in pairs(ids) do
            for id, playedStoryId in pairs(value) do
                PlayedStoryDic[playedStoryId] = true
            end
        end
    end

    function XActivityBriefManager.AddPlayedStoryId(id)
        PlayedStoryDic[id] = true
    end

    function XActivityBriefManager.GetPlayedStoryDic()
        return PlayedStoryDic
    end

    function XActivityBriefManager.SendStoryId(storyId)
        XNetwork.Call(MethodName.FinishBrirfStory, { Id = storyId }, function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            XActivityBriefManager.AddPlayedStoryId(storyId)
        end)
    end

    function XActivityBriefManager.QueryStatistics(storyId)
        local playeds = XActivityBriefManager.GetPlayedStoryDic()
        if playeds[storyId] == true then
            return
        end
        XActivityBriefManager.SendStoryId(storyId)
    end

    function XActivityBriefManager.GetModelRankIndex()
        ModelRankIndex = ModelRankIndex + 1
        if ModelRankIndex > MAX_MODEL_NUMBER then
            ModelRankIndex = 1
        end

        return ModelRankIndex
    end

    -- 打开商店
    function XActivityBriefManager.OpenShop(closeCb, openCb, selectedShopId, screenId)
        local shopIdList = XActivityBriefManager.GetActivityShopIds()
        XShopManager.GetShopInfoList(shopIdList, function()
            XLuaUiManager.Open("UiActivityBriefShop", closeCb, openCb, selectedShopId, screenId)
        end, XShopManager.ActivityShopType.BriefShop)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, Init)
    return XActivityBriefManager
end

XRpc.NotifyBriefStoryData = function(storyData)
    XDataCenter.ActivityBriefManager.InitPlayedStoryDic(storyData)
end
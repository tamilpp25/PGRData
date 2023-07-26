XNewActivityCalendarManagerCreator = function()
    local XNewActivityCalendar = require("XEntity/XNewActivityCalendar/XNewActivityCalendar")
    local XNewActivityCalendarActivityEntity = require("XEntity/XNewActivityCalendar/Entity/XNewActivityCalendarActivityEntity")
    local XNewActivityCalendarPeriodEntity = require("XEntity/XNewActivityCalendar/Entity/XNewActivityCalendarPeriodEntity")
    ---@class XNewActivityCalendarManager
    local XNewActivityCalendarManager = {}
    ---@type XNewActivityCalendar
    local ActivityCalendarViewModel = nil
    ---@type table<number, XNewActivityCalendarActivityEntity>
    local ActivityEntity = {}
    ---@type table<number, XNewActivityCalendarPeriodEntity>
    local PariodEntity = {}
    
    local RequestProto = {
        NewActivityCalendarGetDataRequest = "NewActivityCalendarGetDataRequest"
    }
    
    ---@return XNewActivityCalendarActivityEntity
    function XNewActivityCalendarManager.GetActivityEntity(activityId)
        if not XTool.IsNumberValid(activityId) then
            return
        end
        local entity = ActivityEntity[activityId]
        if not entity then
            entity = XNewActivityCalendarActivityEntity.New(activityId)
            ActivityEntity[activityId] = entity
        end
        return entity
    end
    
    ---@return XNewActivityCalendarPeriodEntity
    function XNewActivityCalendarManager.GetPeriodEntity(periodId)
        if not XTool.IsNumberValid(periodId) then
            return
        end
        local entity = PariodEntity[periodId]
        if not entity then
            entity = XNewActivityCalendarPeriodEntity.New(periodId)
            PariodEntity[periodId] = entity
        end
        return entity
    end
    
    ---@return XNewActivityCalendar
    function XNewActivityCalendarManager.GetViewModel()
        return ActivityCalendarViewModel
    end
    
    function XNewActivityCalendarManager.NewActivityCalendarGetDataRequest(cb)
        XNetwork.Call(RequestProto.NewActivityCalendarGetDataRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            --public XNewActivityCalendarDataDb NewActivityCalendarData;
            ActivityCalendarViewModel:UpdateRewardInfos(res.NewActivityCalendarData)
            if cb then
                cb()
            end
        end)
    end

    function XNewActivityCalendarManager.NotifyNewActivityCalendarData(data)
        --public List<int> OpenActivityIds;
        --public XNewActivityCalendarDataDb NewActivityCalendarData;
        if not ActivityCalendarViewModel then
            ActivityCalendarViewModel = XNewActivityCalendar.New()
        end
        ActivityCalendarViewModel:UpdateData(data)
    end
    
    function XNewActivityCalendarManager.GetIsOpen(noTips)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewActivityCalendar, false, noTips) or XUiManager.IsHideFunc then
            return false
        end
        local viewModel = XNewActivityCalendarManager.GetViewModel()
        if not viewModel then
            if not noTips then
                XUiManager.TipText("CommonActivityNotStart")
            end
            return false
        end
        return true
    end

    -- 获取周历活动信息（包含未开启、活动中）
    function XNewActivityCalendarManager.GetCalenderActivityInfo()
        local tempInfo = {}
        local allCalendarCfg = XNewActivityCalendarConfigs.GetAllCalendarActivityConfig()
        for _, calendarCfg in pairs(allCalendarCfg) do
            local activityEntity = XNewActivityCalendarManager.GetActivityEntity(calendarCfg.ActivityId)
            if activityEntity and (activityEntity:CheckActivityNotOpen() or activityEntity:CheckInActivity()) then
                table.insert(tempInfo, activityEntity)
            end
        end
        return tempInfo
    end

    -- 获取奖励信息（活动中）
    function XNewActivityCalendarManager.GetRewardItemData(activityId, isShowAllTemplate)
        local mainTemplateData, extraItemData = XNewActivityCalendarManager.GetTemplateData(activityId, true)
        if isShowAllTemplate then
            local tempData = appendArray(mainTemplateData, extraItemData)
            return tempData
        end
        if not XNewActivityCalendarManager.CheckIsAllReceiveMainTemplate(mainTemplateData) or XTool.IsTableEmpty(extraItemData) then
            return mainTemplateData
        end
        return extraItemData
    end
    
    -- 获取奖励数据(活动中)
    -- return 1 核心奖励 2 额外奖励
    function XNewActivityCalendarManager.GetTemplateData(activityId, isCheckNotOpen)
        local mainTemplateData = {}
        local extraItemData = {}
        local activityEntity = XNewActivityCalendarManager.GetActivityEntity(activityId)
        if not activityEntity then
            return mainTemplateData, extraItemData
        end
        -- 总核心奖励
        local totalMainTemplateData = activityEntity:GetTotalMainTemplateData()
        -- 额外奖励
        extraItemData = activityEntity:GetExtraItemData()
        -- 未开启显示总核心奖励
        local isShowAllTemplate = isCheckNotOpen and activityEntity:CheckActivityNotOpen() or false
        if isShowAllTemplate then
            return totalMainTemplateData, extraItemData
        end
        -- 已结束的时间断奖励信息
        local endItemData = {}
        local periodIds = activityEntity:GetPeriodId()
        for _, periodId in pairs(periodIds) do
            local periodEntity = XNewActivityCalendarManager.GetPeriodEntity(periodId)
            if periodEntity then
                local tempTemplateData = periodEntity:GetMainTemplateData(activityId)
                if periodEntity:CheckInTime() then
                    mainTemplateData = appendArray(mainTemplateData, tempTemplateData)
                elseif periodEntity:CheckEndTime() then
                    endItemData = appendArray(endItemData, tempTemplateData)
                end
            end
        end
        -- 合并相同的数据
        mainTemplateData = XNewActivityCalendarManager.MergeAndSortList(mainTemplateData)
        endItemData = XNewActivityCalendarManager.MergeAndSortList(endItemData)

        local totalTemplateDict = {}
        for _, info in pairs(totalMainTemplateData) do
            totalTemplateDict[info.TemplateId] = info
        end
        local endItemDict = {}
        for _, info in pairs(endItemData) do
            endItemDict[info.TemplateId] = info
        end

        -- 数据有可能会保存在已结束的时间断内 需要使用总的数量减去结束的数量（如果结束的领取数量大于配置的数量，实际的数量需要加上结束的差值）
        for _, info in pairs(mainTemplateData) do
            local totalTemplate = totalTemplateDict[info.TemplateId]
            local endTemplate = endItemDict[info.TemplateId]
            local endLerp = 0
            local curReceiveCount = totalTemplate.ReceiveCount
            if endTemplate then
                endLerp = endTemplate.ReceiveCount - endTemplate.Count
                curReceiveCount = totalTemplate.ReceiveCount - endTemplate.ReceiveCount
            end
            if endLerp > 0 then
                curReceiveCount = curReceiveCount + endLerp
            end
            info.ReceiveCount = curReceiveCount
        end

        return mainTemplateData, extraItemData
    end

    function XNewActivityCalendarManager.MergeAndSortList(data)
        if XTool.IsTableEmpty(data) then
            return {}
        end
        local mergeList = {}
        local mergeDict = {}
        for _, info in pairs(data) do
            local oldData = mergeDict[info.TemplateId]
            if oldData then
                mergeDict[info.TemplateId].Count = mergeDict[info.TemplateId].Count + info.Count
                mergeDict[info.TemplateId].ReceiveCount = mergeDict[info.TemplateId].ReceiveCount + info.ReceiveCount
            else
                mergeDict[info.TemplateId] = {
                    TemplateId = info.TemplateId,
                    Count = info.Count,
                    ReceiveCount = info.ReceiveCount,
                }
            end
        end
        for _, info in pairs(mergeDict) do
            table.insert(mergeList, info)
        end
        table.sort(mergeList, function(a, b)
            return a.TemplateId > b.TemplateId
        end)
        return mergeList
    end
    
    -- 检查核心奖励是否全部已领取
    function XNewActivityCalendarManager.CheckIsAllReceiveMainTemplate(data)
        if XTool.IsTableEmpty(data) then
            return true
        end
        for _, info in pairs(data) do
            local count = info.Count - info.ReceiveCount
            if count > 0 then
                return false
            end
        end
        return true
    end
    
    -- 检查核心奖励是否有未领取的奖励
    function XNewActivityCalendarManager.CheckNotReceiveMainTemplate(activityId)
        local mainTemplateData = XNewActivityCalendarManager.GetTemplateData(activityId)
        local isReceive = XNewActivityCalendarManager.CheckIsAllReceiveMainTemplate(mainTemplateData)
        return not isReceive
    end
    
    -- 检查在活动中是否有未领取的奖励
    function XNewActivityCalendarManager.CheckInActivityNotReceiveReward()
        local viewModel = XNewActivityCalendarManager.GetViewModel()
        if not viewModel then
            return false
        end
        local activityIds = viewModel:GetOpenActivityIds()
        for _, activityId in pairs(activityIds) do
            local mainTemplateData = XNewActivityCalendarManager.GetTemplateData(activityId)
            local isReceive = XNewActivityCalendarManager.CheckIsAllReceiveMainTemplate(mainTemplateData)
            if not isReceive then
                return true
            end
        end
        return false
    end
    
    -- 检查是否有新活动开启
    function XNewActivityCalendarManager.CheckIsNewActivityOpen()
        local viewModel = XNewActivityCalendarManager.GetViewModel()
        if not viewModel then
            return false
        end
        local activityIds = viewModel:GetOpenActivityIds()
        local localActivityIds = XNewActivityCalendarManager.GetLocalActivityIds()
        for _, id in pairs(activityIds) do
            if not table.contains(localActivityIds, id) then
                return true
            end
        end
        return false
    end
    
    -- 检查是否需要播放特效
    --1、刷光特效：
    --（1）大前提！只有满足这个前提，才会出现改特效：新周历内的活动还有未领取完的核心奖励
    --（2）每日登录，关闭主界面所有弹窗后播放一次即可
    --（3）有新活动开启后，返回主界面，播放一次即可
    function XNewActivityCalendarManager.CheckIsNeedPlayEffect()
        if XNewActivityCalendarManager.CheckIsPlayEffect() then
            return false  
        end
        local isRadPoint = XNewActivityCalendarManager.CheckActivityCalendarRadPoint()
        if isRadPoint then
            XNewActivityCalendarManager.SaveIsPlayEffect(true)
            return true
        end
        return false
    end
    
    -- 检查是否需要显示红点
    --2、摇铃动效：
    --（1）大前提！只有满足这个前提，才会出现改特效：新周历内的活动还有未领取完的核心奖励
    --（2）出现时机：每日登录和有新活动开启
    --（3）消失时机：玩家点进新周历结束
    function XNewActivityCalendarManager.CheckActivityCalendarRadPoint()
        if not XNewActivityCalendarManager.CheckInActivityNotReceiveReward() then
            return false
        end
        if not XNewActivityCalendarManager.CheckIsDailyFirstLogin() then
            return true
        end
        if XNewActivityCalendarManager.CheckIsNewActivityOpen() then
            return true
        end
        return false
    end

    --1、有新活动开启时    提示文本【新活动开启了】
    --2、有未领完核心奖励活动开启  提示文本【丰厚奖励活动】
    --3、领完核心奖励活动但还有活动正在进行  提示文本【这里有些活动】
    function XNewActivityCalendarManager.GetMainBtnShowTextDesc()
        if XNewActivityCalendarManager.CheckIsNewActivityOpen() then
            return XUiHelper.GetText("UiNewActivityCalendarBtnTips1")
        end
        if XNewActivityCalendarManager.CheckInActivityNotReceiveReward() then
            return XUiHelper.GetText("UiNewActivityCalendarBtnTips2")
        end
        return XUiHelper.GetText("UiNewActivityCalendarBtnTips3")
    end
    
    --region 本地数据

    function XNewActivityCalendarManager.GetDailyFirstLoginKey()
        local time = XTime.GetSeverTodayFreshTime()
        return string.format("NewActivityCalendarDailyFirstLogin_%s_%s", XPlayer.Id, time)
    end

    function XNewActivityCalendarManager.CheckIsDailyFirstLogin()
        local key = XNewActivityCalendarManager.GetDailyFirstLoginKey()
        local data = XSaveTool.GetData(key) or 0
        return data == 1
    end

    function XNewActivityCalendarManager.SaveIsDailyFirstLogin()
        local key = XNewActivityCalendarManager.GetDailyFirstLoginKey()
        local data = XSaveTool.GetData(key) or 0
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end

    function XNewActivityCalendarManager.GetPlayEffectKey()
        return string.format("NewActivityCalendarPlayEffect_%s", XPlayer.Id)
    end

    function XNewActivityCalendarManager.CheckIsPlayEffect()
        local key = XNewActivityCalendarManager.GetPlayEffectKey()
        local data = XSaveTool.GetData(key) or 0
        return data == 1
    end

    function XNewActivityCalendarManager.SaveIsPlayEffect(value)
        local key = XNewActivityCalendarManager.GetPlayEffectKey()
        XSaveTool.SaveData(key, value and 1 or 0)
    end

    function XNewActivityCalendarManager.GetLocalActivityIdsKey()
        return string.format("NewActivityCalendarLocalActivityIds_%s", XPlayer.Id)
    end
    
    function XNewActivityCalendarManager.GetLocalActivityIds()
        local key = XNewActivityCalendarManager.GetLocalActivityIdsKey()
        return XSaveTool.GetData(key) or {}
    end
    
    function XNewActivityCalendarManager.SaveLoaclActivityIds()
        local key = XNewActivityCalendarManager.GetLocalActivityIdsKey()
        local viewModel = XNewActivityCalendarManager.GetViewModel()
        local activityIds = {}
        if viewModel then
            activityIds = viewModel:GetOpenActivityIds()
        end
        XSaveTool.SaveData(key, activityIds)
    end
    
    --endregion
    
    function XNewActivityCalendarManager.Init()

    end

    XNewActivityCalendarManager.Init()
    return XNewActivityCalendarManager
end

XRpc.NotifyNewActivityCalendarData = function(data)
    XDataCenter.NewActivityCalendarManager.NotifyNewActivityCalendarData(data)   
end
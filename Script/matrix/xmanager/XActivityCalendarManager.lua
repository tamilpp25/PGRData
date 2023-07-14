XActivityCalendarManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local XActivityInfo = require("XEntity/XActivityCalendar/XActivityInfo")
    local XActivityCalendarManager = {}
    local ActivityInfoDic = {}

    local function Init()
        local activityConfigs = XActivityCalendarConfigs.GetActivityConfigs()
        for id,cfg in pairs(activityConfigs) do
            ActivityInfoDic[id] = XActivityInfo.New(cfg)
        end
    end

    function XActivityCalendarManager.GetActivityInfo(id)
        if not ActivityInfoDic[id] then
            XLog.Error("活动配置不存在，请检查ActivityCalendar.tab")
            return
        end
        return ActivityInfoDic[id]
    end

    function XActivityCalendarManager.GetInCalendarActivity()
        local tempList = {}
        for _,activityInfo in pairs(ActivityInfoDic) do
            local todayDt = CS.XDateUtil.GetGameDateTime(XTime.GetServerNowTimestamp())
            local weekStartTime = CS.XDateUtil.GetFirstDayOfThisWeek(todayDt, CS.System.DayOfWeek.Sunday):ToTimestamp()
            local weekEndTime = weekStartTime + CS.XDateUtil.ONE_WEEK_SECOND
            local activityStartTime = activityInfo:GetStartTime()
            local activityEndTime = activityInfo:GetEndTime()
            local isOpenThisWeek = activityEndTime > weekStartTime and activityStartTime < weekEndTime
            if activityInfo:IsInCalendar() and isOpenThisWeek then
                tableInsert(tempList, activityInfo)
            end
        end
        return tempList
    end

    --有新活动解锁
    function XActivityCalendarManager.CheckNewActivityUnlock()
        --本周内的活动
        local showActivityList = XActivityCalendarManager.GetInCalendarActivity()

        for _, activityInfo in pairs(showActivityList) do
            --是否达成开启活动的要求
            if not activityInfo:IsJudgeOpen() then
                goto continue
            end

            local activityStartTime = activityInfo:GetStartTime()
            local todayTime = XTime.GetServerNowTimestamp()

            --活动开始时间和当前时间在同一天
            if XTime.IsToday(activityStartTime, todayTime) and activityStartTime < todayTime then
                return true
            end

            :: continue ::
        end
        return false
    end

    --有活动准备结束
    function XActivityCalendarManager.CheckActivityReadyEnd()
        --本周内的活动
        local showActivityList = XActivityCalendarManager.GetInCalendarActivity()

        for _, activityInfo in pairs(showActivityList) do
            --是否达成开启活动的要求
            if not activityInfo:IsJudgeOpen() then
                goto continue
            end

            local activityEndTime = activityInfo:GetEndTime()
            local yesterdayTime = activityEndTime - CS.XDateUtil.ONE_DAY_SECOND
            local todayTime = XTime.GetServerNowTimestamp()

            --活动结束的前一天或者当天
            if XTime.IsToday(todayTime, yesterdayTime) or
                    (XTime.IsToday(todayTime, activityEndTime) and activityEndTime > todayTime) then
                return true
            end

            :: continue ::
        end
        return false
    end

    function XActivityCalendarManager.CheckWeekIsClick()
        local data = XSaveTool.GetData("ActivityCalendarWhetherClickButton")
        if data then
            local todayTime = XTime.GetServerNowTimestamp()
            if XTime.IsToday(data.Time, todayTime) then
                return data.IsClick
            end
        end
        return false
    end

    function XActivityCalendarManager.SaveWeekClick(isClick)
        if XActivityCalendarManager.CheckWeekIsClick() then
            return
        end
        
        local isShowRedPoint = XDataCenter.ActivityCalendarManager.CheckNewActivityUnlock() or
                XDataCenter.ActivityCalendarManager.CheckActivityReadyEnd()
        
        if not isShowRedPoint then
            return
        end
        
        local todayTime = XTime.GetServerNowTimestamp()
        local value = {
            Time = todayTime,
            IsClick = isClick
        }
        XSaveTool.SaveData("ActivityCalendarWhetherClickButton", value)
    end
    
    Init()
    return XActivityCalendarManager
end

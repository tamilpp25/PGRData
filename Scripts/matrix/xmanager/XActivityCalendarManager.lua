XActivityCalendarManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local XActivityInfo = require("XEntity/XActivityCalendar/XActivityInfo")
    local XActivityCalendarManager = {}
    local ActivityInfoDic = {}
    local HOUR = 60 * 60
    local WeekCalenderKey = {}

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
    
    -- 检测红点显示
    function XActivityCalendarManager.CheckActivityRedPoint()
        --本周内的活动
        local showActivityList = XActivityCalendarManager.GetInCalendarActivity()
        

        for _, activityInfo in pairs(showActivityList) do
            --是否达成开启活动的要求
            if not activityInfo:IsJudgeOpen() then
                goto continue
            end

            local beforeEndTime = CS.XGame.ClientConfig:GetInt("ActivityCalendarBeforeEndTime")  -- 单位小时
            local activityEndTime = activityInfo:GetEndTime()
            local now = XTime.GetServerNowTimestamp()

            local isInFight = activityInfo:IsInFightTimeId() -- 正在进行
            local isComingOpen = now < activityEndTime and now > activityEndTime - beforeEndTime * HOUR -- 即将结束
            local isClick = XActivityCalendarManager.CheckWeekIsClick() -- 是否点击
            if (isInFight or isComingOpen) and not isClick then
                return true
            end

            :: continue ::
        end
        return false
    end

    -- 每日提示key
    function XActivityCalendarManager.GetWeekCalenderKey()
        --每秒都在调用，使用缓存
        local id = XPlayer.Id
        if not WeekCalenderKey[id] then
            WeekCalenderKey = {}
            WeekCalenderKey[id] = string.format("%s_%s", "ActivityCalendarWhetherClickButton", id)
        end
        return WeekCalenderKey[id]
    end

    function XActivityCalendarManager.CheckWeekIsClick()
        local key = XActivityCalendarManager.GetWeekCalenderKey()
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end

    function XActivityCalendarManager.SaveWeekClick()
        if XActivityCalendarManager.CheckWeekIsClick() then
            return
        end

        local isShowRedPoint = XActivityCalendarManager.CheckActivityRedPoint()

        if not isShowRedPoint then
            return
        end

        local key = XActivityCalendarManager.GetWeekCalenderKey()
        local updateTime = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(key, updateTime)
    end
    
    Init()
    return XActivityCalendarManager
end

local XNewActivityCalendarTimeLimitInfo = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarTimeLimitInfo")
local XNewActivityCalendarWeekInfo = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarWeekInfo")

---@class XNewActivityCalendarData
local XNewActivityCalendarData = XClass(nil, "XNewActivityCalendarData")

function XNewActivityCalendarData:Ctor()
    -- 限时活动信息
    ---@type XNewActivityCalendarTimeLimitInfo[]
    self.TimeLimitActivityInfos = {}
    -- 周常活动信息
    ---@type XNewActivityCalendarWeekInfo[]
    self.WeekActivityInfos = {}
end

function XNewActivityCalendarData:NotifyNewActivityCalendarData(data)
    if not data then
        return
    end
    self.TimeLimitActivityInfos = {}
    self:UpdateTimeLimitActivityInfos(data.TimeLimitActivityInfos)
    self.WeekActivityInfos = {}
    self:UpdateWeekActivityInfos(data.WeekActivityInfos)
end

-- 更新限时活动信息
function XNewActivityCalendarData:UpdateTimeLimitActivityInfos(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        self:AddTimeLimitActivityInfo(info)
    end
end

function XNewActivityCalendarData:AddTimeLimitActivityInfo(info)
    local activityId = info.ActivityId
    local timeLimitInfo = self.TimeLimitActivityInfos[activityId]
    if not timeLimitInfo then
        timeLimitInfo = XNewActivityCalendarTimeLimitInfo.New()
        self.TimeLimitActivityInfos[activityId] = timeLimitInfo
    end
    timeLimitInfo:UpdateData(info)
end

-- 更新周常活动信息
function XNewActivityCalendarData:UpdateWeekActivityInfos(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        self:AddWeekActivityInfo(info)
    end
end

function XNewActivityCalendarData:AddWeekActivityInfo(info)
    local mainId = info.MainId
    local weekInfo = self.WeekActivityInfos[mainId]
    if not weekInfo then
        weekInfo = XNewActivityCalendarWeekInfo.New()
        self.WeekActivityInfos[mainId] = weekInfo
    end
    weekInfo:UpdateData(info)
end

-- 获取限时活动总领取数量
function XNewActivityCalendarData:GetTimeLimitTotalReceiveCount(activityId, templateId)
    local timeLimitInfo = self.TimeLimitActivityInfos[activityId]
    if not timeLimitInfo then
        return 0
    end
    return timeLimitInfo:GetTotalReceiveTemplateCount(templateId)
end

-- 获取限时活动当前期间的领取数量
function XNewActivityCalendarData:GetTimeLimitReceiveCount(activityId, periodId, templateId)
    local timeLimitInfo = self.TimeLimitActivityInfos[activityId]
    if not timeLimitInfo then
        return 0
    end
    return timeLimitInfo:GetReceiveTemplateCount(periodId, templateId)
end

function XNewActivityCalendarData:GetWeekSubIdByMainId(mainId)
    local weekInfo = self.WeekActivityInfos[mainId]
    if not weekInfo then
        return 0
    end
    return weekInfo:GetSubId()
end

-- 获取周常活动的领取数量
function XNewActivityCalendarData:GetWeekReceiveCount(mainId, templateId)
    local weekInfo = self.WeekActivityInfos[mainId]
    if not weekInfo then
        return 0
    end
    return weekInfo:GetTemplateIdCount(templateId)
end

function XNewActivityCalendarData:CheckIsHaveMainId(mainId)
    return self.WeekActivityInfos[mainId] and true or false
end

return XNewActivityCalendarData
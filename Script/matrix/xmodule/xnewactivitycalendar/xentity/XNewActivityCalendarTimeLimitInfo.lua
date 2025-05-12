local XNewActivityCalendarPeriodInfo = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarPeriodInfo")

---@class XNewActivityCalendarTimeLimitInfo
local XNewActivityCalendarTimeLimitInfo = XClass(nil, "XNewActivityCalendarTimeLimitInfo")

function XNewActivityCalendarTimeLimitInfo:Ctor()
    -- 活动Id
    self.ActivityId = 0
    -- 周期信息
    ---@type XNewActivityCalendarPeriodInfo[]
    self.PeriodInfos = {}
end

function XNewActivityCalendarTimeLimitInfo:UpdateData(data)
    self.ActivityId = data.ActivityId
    self.PeriodInfos = {}
    self:UpdatePeriodInfos(data.PeriodInfos)
end

function XNewActivityCalendarTimeLimitInfo:UpdatePeriodInfos(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        self:AddPeriodInfo(info)
    end
end

function XNewActivityCalendarTimeLimitInfo:AddPeriodInfo(info)
    local periodId = info.PeriodId
    local periodInfo = self.PeriodInfos[periodId]
    if not periodInfo then
        periodInfo = XNewActivityCalendarPeriodInfo.New()
        self.PeriodInfos[periodId] = periodInfo
    end
    periodInfo:UpdateData(info)
end

-- 获取当前活动的总领取数量
function XNewActivityCalendarTimeLimitInfo:GetTotalReceiveTemplateCount(templateId)
    local totalNum = 0
    for _, period in pairs(self.PeriodInfos) do
        totalNum = totalNum + period:GetTemplateIdCount(templateId)
    end
    return totalNum
end

-- 获取当前期间的数量
function XNewActivityCalendarTimeLimitInfo:GetReceiveTemplateCount(periodId, templateId)
    local periodInfo = self.PeriodInfos[periodId]
    if not periodInfo then
        return 0
    end
    return periodInfo:GetTemplateIdCount(templateId)
end

return XNewActivityCalendarTimeLimitInfo
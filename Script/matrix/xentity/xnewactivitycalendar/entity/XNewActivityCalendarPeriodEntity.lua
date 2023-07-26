---@class XNewActivityCalendarPeriodEntity
local XNewActivityCalendarPeriodEntity = XClass(nil, "XNewActivityCalendarPeriodEntity")

function XNewActivityCalendarPeriodEntity:Ctor(periodId)
    self:UpdatePeriodId(periodId)
end

function XNewActivityCalendarPeriodEntity:UpdatePeriodId(periodId)
    self.PeriodId = periodId
    self.Config = XNewActivityCalendarConfigs.GetCalendarPeriodConfig(periodId)
end

function XNewActivityCalendarPeriodEntity:GetTimeId()
    return self.Config.TimeId or 0
end

function XNewActivityCalendarPeriodEntity:GetMainTemplateId()
    return self.Config.MainTemplateId or {}
end

function XNewActivityCalendarPeriodEntity:GetMainTemplateCount()
    return self.Config.MainTemplateCount or {}
end

function XNewActivityCalendarPeriodEntity:GetMainTemplateData(activityId)
    local viewModel = XDataCenter.NewActivityCalendarManager.GetViewModel()
    if not viewModel then
        return {}
    end
    local itemData = {}
    local mainTemplateIds = self:GetMainTemplateId()
    local mainTemplateCounts = self:GetMainTemplateCount()
    for i, id in pairs(mainTemplateIds) do
        local count = mainTemplateCounts[i]
        local receiveCount = viewModel:GetReceiveTemplateCount(activityId, self.PeriodId, id)
        table.insert(itemData, {
            TemplateId = id,
            Count = count,
            ReceiveCount = receiveCount,
        })
    end
    return itemData
end

function XNewActivityCalendarPeriodEntity:CheckInTime()
    return XFunctionManager.CheckInTimeByTimeId(self:GetTimeId())
end

-- 检查是否结束
function XNewActivityCalendarPeriodEntity:CheckEndTime()
    local now = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
    if endTime > 0 and now >= endTime then
        return true
    end
    return false
end

return XNewActivityCalendarPeriodEntity
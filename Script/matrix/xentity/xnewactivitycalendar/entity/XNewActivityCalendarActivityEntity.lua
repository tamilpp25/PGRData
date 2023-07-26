---@class XNewActivityCalendarActivityEntity
local XNewActivityCalendarActivityEntity = XClass(nil, "XNewActivityCalendarActivityEntity")

function XNewActivityCalendarActivityEntity:Ctor(activityId)
    self:UpdateActivityId(activityId)
end

function XNewActivityCalendarActivityEntity:UpdateActivityId(activityId)
    self.ActivityId = activityId
    self.Config = XNewActivityCalendarConfigs.GetCalendarActivityConfig(activityId)
end

function XNewActivityCalendarActivityEntity:GetActivityId()
    return self.ActivityId
end

function XNewActivityCalendarActivityEntity:GetMainTimeId()
    return self.Config.MainTimeId or 0
end

function XNewActivityCalendarActivityEntity:GetMainTemplateId()
    return self.Config.MainTemplateId or {}
end

function XNewActivityCalendarActivityEntity:GetMainTemplateCount()
    return self.Config.MainTemplateCount or {}
end

function XNewActivityCalendarActivityEntity:GetExtraItem()
    return self.Config.ExtraItem or {}
end

function XNewActivityCalendarActivityEntity:GetPeriodId()
    return self.Config.PeriodId or {}
end

function XNewActivityCalendarActivityEntity:GetName()
    return self.Config.Name or ""
end

function XNewActivityCalendarActivityEntity:GetKind()
    return self.Config.Kind or {}
end

function XNewActivityCalendarActivityEntity:GetIsMajorActivity()
    return self.Config.IsMajorActivity or 0
end

function XNewActivityCalendarActivityEntity:GetSkipId()
    return self.Config.SkipId or 0
end

function XNewActivityCalendarActivityEntity:GetActivityIcon()
    return self.Config.ActivityIcon or ""
end

function XNewActivityCalendarActivityEntity:GetDescription()
    return self.Config.Description or ""
end

function XNewActivityCalendarActivityEntity:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetMainTimeId())
end

function XNewActivityCalendarActivityEntity:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetMainTimeId())
end

function XNewActivityCalendarActivityEntity:GetRemainingTime()
    local now = XTime.GetServerNowTimestamp()
    local remainningTime = self:GetEndTime() - now
    if remainningTime < 0 then
        return 0
    end
    return remainningTime
end

-- 获取总的核心奖励
function XNewActivityCalendarActivityEntity:GetTotalMainTemplateData()
    local viewModel = XDataCenter.NewActivityCalendarManager.GetViewModel()
    if not viewModel then
        return {}
    end
    local itemData = {}
    local mainTemplateIds = self:GetMainTemplateId()
    local mainTemplateCounts = self:GetMainTemplateCount()
    for i, id in pairs(mainTemplateIds) do
        local count = mainTemplateCounts[i]
        local receiveCount = viewModel:GetTotalReceiveTemplateCount(self.ActivityId, id)
        table.insert(itemData, {
            TemplateId = id,
            Count = count,
            ReceiveCount = receiveCount,
        })
    end
    table.sort(itemData, function(a, b)
        return a.TemplateId > b.TemplateId
    end)
    return itemData
end

-- 获取额外奖励
function XNewActivityCalendarActivityEntity:GetExtraItemData()
    local viewModel = XDataCenter.NewActivityCalendarManager.GetViewModel()
    if not viewModel then
        return {}
    end
    local itemData = {}
    for _, id in pairs(self:GetExtraItem()) do
        table.insert(itemData, {
            TemplateId = id,
            Count = 0,
            ReceiveCount = 0,
        })
    end
    return itemData
end

-- 检查是否结束
function XNewActivityCalendarActivityEntity:CheckActivityEnd()
    local now = XTime.GetServerNowTimestamp()
    local endTime = self:GetEndTime()
    if endTime > 0 and now >= endTime then
        return true
    end
    return false
end

-- 检查是否未开启
function XNewActivityCalendarActivityEntity:CheckActivityNotOpen()
    local now = XTime.GetServerNowTimestamp()
    local startTime = self:GetStartTime()
    if startTime > 0 and now < startTime then
        return true
    end
    return false
end

function XNewActivityCalendarActivityEntity:CheckInActivity()
    local viewModel = XDataCenter.NewActivityCalendarManager.GetViewModel()
    if not viewModel then
        return false
    end
    if viewModel:CheckCanOpenActivityId(self.ActivityId) and XFunctionManager.CheckInTimeByTimeId(self:GetMainTimeId()) then
        return true
    end
    return false
end

-- 检查是否是重点活动
function XNewActivityCalendarActivityEntity:CheckIsMajorActivity()
    return self:GetIsMajorActivity() == 1
end

return XNewActivityCalendarActivityEntity
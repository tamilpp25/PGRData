local XNewActivityCalendarItemInfo = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarItemInfo")

---@class XNewActivityCalendarPeriodInfo
local XNewActivityCalendarPeriodInfo = XClass(nil, "XNewActivityCalendarPeriodInfo")

function XNewActivityCalendarPeriodInfo:Ctor()
    -- 周期Id
    self.PeriodId = 0
    -- 已获得的奖励
    ---@type XNewActivityCalendarItemInfo[]
    self.GotRewards = {}
end

function XNewActivityCalendarPeriodInfo:UpdateData(data)
    self.PeriodId = data.PeriodId
    self.GotRewards = {}
    self:UpdateGotRewards(data.GotRewards)
end

function XNewActivityCalendarPeriodInfo:UpdateGotRewards(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        self:AddGotRewards(info)
    end
end

function XNewActivityCalendarPeriodInfo:AddGotRewards(info)
    local templateId = info.TemplateId
    local itemInfo = self.GotRewards[templateId]
    if not itemInfo then
        itemInfo = XNewActivityCalendarItemInfo.New()
        self.GotRewards[templateId] = itemInfo
    end
    itemInfo:UpdateData(info)
end

function XNewActivityCalendarPeriodInfo:GetTemplateIdCount(templateId)
    local itemInfo = self.GotRewards[templateId]
    if not itemInfo then
        return 0
    end
    return itemInfo:GetCount()
end

return XNewActivityCalendarPeriodInfo
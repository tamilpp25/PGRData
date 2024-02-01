---@class XNewActivityCalendarItemInfo
local XNewActivityCalendarItemInfo = XClass(nil, "XNewActivityCalendarItemInfo")

function XNewActivityCalendarItemInfo:Ctor()
    -- 物品Id
    self.TemplateId = 0
    -- 物品数量
    self.Count = 0
end

function XNewActivityCalendarItemInfo:UpdateData(data)
    self.TemplateId = data.TemplateId or 0
    self.Count = data.Count or 0
end

function XNewActivityCalendarItemInfo:GetCount()
    return self.Count
end

return XNewActivityCalendarItemInfo
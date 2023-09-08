local XNewActivityCalendarItemInfo = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarItemInfo")

---@class XNewActivityCalendarWeekInfo
local XNewActivityCalendarWeekInfo = XClass(nil, "XNewActivityCalendarWeekInfo")

function XNewActivityCalendarWeekInfo:Ctor()
    -- 周常Id
    self.MainId = 0
    -- 子Id
    self.SubId = 0
    -- 已获得的奖励
    ---@type XNewActivityCalendarItemInfo[]
    self.GotRewards = {}
end

function XNewActivityCalendarWeekInfo:UpdateData(data)
    self.MainId = data.MainId
    self.SubId = data.SubId
    self.GotRewards = {}
    self:UpdateGotRewards(data.GotRewards)
end

function XNewActivityCalendarWeekInfo:UpdateGotRewards(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        self:AddGotRewards(info)
    end
end

function XNewActivityCalendarWeekInfo:AddGotRewards(info)
    local templateId = info.TemplateId
    local itemInfo = self.GotRewards[templateId]
    if not itemInfo then
        itemInfo = XNewActivityCalendarItemInfo.New()
        self.GotRewards[templateId] = itemInfo
    end
    itemInfo:UpdateData(info)
end

function XNewActivityCalendarWeekInfo:GetMainId()
    return self.MainId
end

function XNewActivityCalendarWeekInfo:GetSubId()
    return self.SubId
end

function XNewActivityCalendarWeekInfo:GetTemplateIdCount(templateId)
    local itemInfo = self.GotRewards[templateId]
    if not itemInfo then
        return 0
    end
    return itemInfo:GetCount()
end

return XNewActivityCalendarWeekInfo

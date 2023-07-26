local type = type
local pairs = pairs

--[[public class XNewActivityCalendarPeriodInfo
{
    // 周期Id
    public int PeriodId;
    // 已获得的奖励
    public List<XNewActivityCalendarItemInfo> GotRewards = new List<XNewActivityCalendarItemInfo>();
}]]

local Default = {
    _PeriodId = 0, -- 周期Id
    _GotRewards = {}, -- 已获得奖励 TemplateId 物品Id Count 物品数量
}

---@class XNewActivityCalendarPeriodInfo
---@field _PeriodId number 周期Id
---@field _GotRewards table<number, table> 已获得奖励
local XNewActivityCalendarPeriodInfo = XClass(nil, "XNewActivityCalendarPeriodInfo")

function XNewActivityCalendarPeriodInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if data then
        self:UpdateData(data)
    end
end

function XNewActivityCalendarPeriodInfo:UpdateData(data)
    if not data then
        return
    end
    self._PeriodId = data.PeriodId
    self._GotRewards = {}
    for _, reward in pairs(data.GotRewards or {}) do
        self:UpdateReward(reward)
    end
end

function XNewActivityCalendarPeriodInfo:UpdateReward(data)
    local templateId = data.TemplateId
    self._GotRewards[templateId] = {
        TemplateId = templateId,
        Count = data.Count
    }
end

function XNewActivityCalendarPeriodInfo:GetTemplateIdCount(templateId)
    local reward = self._GotRewards[templateId]
    if not reward then
        return 0
    end
    return reward.Count or 0
end

return XNewActivityCalendarPeriodInfo
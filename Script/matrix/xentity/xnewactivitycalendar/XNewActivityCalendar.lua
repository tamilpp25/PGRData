local type = type
local pairs = pairs

local XNewActivityCalendarPeriodInfo = require("XEntity/XNewActivityCalendar/XNewActivityCalendarPeriodInfo")

--[[public class NotifyNewActivityCalendarData
{
    public List<int> OpenActivityIds;
    public XNewActivityCalendarDataDb NewActivityCalendarData;
}]]

local Default = {
    _OpenActivityIds = {}, -- 开启的活动id
    _RewardInfos = {}, -- 已获得的奖励
}

---@class XNewActivityCalendar
---@field _OpenActivityIds number[] 开启的活动id
---@field _RewardInfos table<number, table<number, XNewActivityCalendarPeriodInfo>> 以获得的奖励
local XNewActivityCalendar = XClass(nil, "XNewActivityCalendar")

function XNewActivityCalendar:Ctor(data)
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

function XNewActivityCalendar:UpdateData(data)
    if not data then
        return
    end
    self:UpdateOpenActivityIds(data.OpenActivityIds)
    self._RewardInfos = {}
    self:UpdateRewardInfos(data.NewActivityCalendarData)

    XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
end

function XNewActivityCalendar:UpdateOpenActivityIds(data)
    self._OpenActivityIds = data or {}
end

function XNewActivityCalendar:UpdateRewardInfos(data)
    if not data or not data.RewardInfos then
        return
    end
    for _, rewardInfo in pairs(data.RewardInfos) do
        self:UpdateRewardInfo(rewardInfo)
    end
end

function XNewActivityCalendar:UpdateRewardInfo(data)
    local activityId = data.ActivityId
    if not self._RewardInfos[activityId] then
        self._RewardInfos[activityId] = {}
    end
    for _, info in pairs(data.PeriodInfos or {}) do
        local periodId = info.PeriodId
        local periodInfo = self._RewardInfos[activityId][periodId]
        if not periodInfo then
            periodInfo = XNewActivityCalendarPeriodInfo.New()
            self._RewardInfos[activityId][periodId] = periodInfo
        end
        periodInfo:UpdateData(info)
    end
end

function XNewActivityCalendar:GetOpenActivityIds()
    return self._OpenActivityIds or {}
end

function XNewActivityCalendar:CheckCanOpenActivityId(activityId)
    if XTool.IsTableEmpty(self._OpenActivityIds) then
        return false
    end
    return table.contains(self._OpenActivityIds, activityId)
end

-- 获取当前活动的总领取数量
function XNewActivityCalendar:GetTotalReceiveTemplateCount(activityId, templateId)
    local info = self._RewardInfos[activityId]
    if not info then
        return 0
    end
    local totalNum = 0
    for _, period in pairs(info) do
        totalNum = totalNum + period:GetTemplateIdCount(templateId)
    end
    return totalNum
end

-- 获取当前期间的数量
function XNewActivityCalendar:GetReceiveTemplateCount(activityId, periodId, templateId)
    local info = self._RewardInfos[activityId]
    if not info then
        return 0
    end
    local period = info[periodId]
    if not period then
        return 0
    end
    return period:GetTemplateIdCount(templateId)
end

return XNewActivityCalendar
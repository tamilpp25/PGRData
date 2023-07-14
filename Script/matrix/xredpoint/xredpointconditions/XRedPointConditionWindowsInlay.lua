----------------------------------------------------------------
--新手任务奖励检测
local XRedPointConditionWindowsInlay = {}
local Events = nil

function XRedPointConditionWindowsInlay.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_DAILY_REFRESH),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
    }
    return Events
end

function XRedPointConditionWindowsInlay.Check()
    return XDataCenter.MarketingActivityManager.IsShowWindowsInlayRedPoint()
end

return XRedPointConditionWindowsInlay
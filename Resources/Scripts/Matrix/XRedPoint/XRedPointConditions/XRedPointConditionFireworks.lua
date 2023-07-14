----------------------------------------------------------------
--节红点检测
local XRedPointConditionFireworks = {}
local Events = nil

function XRedPointConditionFireworks.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN),
    }
    return Events
end

function XRedPointConditionFireworks.Check()
    return XDataCenter.FireworksManager.HasRedDot()
end

return XRedPointConditionFireworks
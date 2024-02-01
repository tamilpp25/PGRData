-- 反馈SDK红点
local XRedPointConditionFeedback = {}

local Events = nil
function XRedPointConditionFeedback.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_FEEDBACK_REFRESH),
    }
    return Events
end

function XRedPointConditionFeedback.Check()
    return XHeroSdkManager.CheckShowReddot()
end

return XRedPointConditionFeedback

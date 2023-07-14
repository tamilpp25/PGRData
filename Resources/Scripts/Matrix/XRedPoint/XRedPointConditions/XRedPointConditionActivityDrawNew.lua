----------------------------------------------------------------
-- 是否有新活动奖池开启
local XRedPointConditionActivityDrawNew = {}

local Events = nil
function XRedPointConditionActivityDrawNew.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_DRAW_ACTIVITYDRAW_CHANGE),
                XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
            }
    return Events
end

function XRedPointConditionActivityDrawNew.Check()
    return XDataCenter.DrawManager.CheckNewActivityDraw()
end

return XRedPointConditionActivityDrawNew
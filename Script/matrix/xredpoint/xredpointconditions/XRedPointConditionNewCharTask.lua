local XRedPointConditionNewCharTask = {}
local Events = nil
function XRedPointConditionNewCharTask.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_KORO_CHAR_ACTIVITY_REDPOINTEVENT),
            }
    return Events
end

function XRedPointConditionNewCharTask.Check()
    return XDataCenter.FubenNewCharActivityManager.CheckTaskRedPoint()
end

return XRedPointConditionNewCharTask
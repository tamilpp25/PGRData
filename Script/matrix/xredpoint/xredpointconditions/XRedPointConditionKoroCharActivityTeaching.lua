local XRedPointConditionKoroCharActivityTeaching = {}
local Events = nil
function XRedPointConditionKoroCharActivityTeaching.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KORO_CHAR_ACTIVITY_REDPOINTEVENT),
    }
    return Events
end

function XRedPointConditionKoroCharActivityTeaching.Check(activityId)
    return XDataCenter.FubenNewCharActivityManager.CheckTeachingRedPoint(activityId)
end

return XRedPointConditionKoroCharActivityTeaching
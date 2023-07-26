local XRedPointConditionKoroCharActivityTeaching = {}
local Events = nil
function XRedPointConditionKoroCharActivityTeaching.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KORO_CHAR_ACTIVITY_REDPOINTEVENT),
    }
    return Events
end

function XRedPointConditionKoroCharActivityTeaching.Check()
    return XDataCenter.FubenNewCharActivityManager.CheckTeachingRedPoint()
end

return XRedPointConditionKoroCharActivityTeaching
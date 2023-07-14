local XRedPointConditionKoroCharActivityChallenge = {}
local Events = nil
function XRedPointConditionKoroCharActivityChallenge.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KORO_CHAR_ACTIVITY_REDPOINTEVENT),
    }
    return Events
end

function XRedPointConditionKoroCharActivityChallenge.Check()
    return XDataCenter.FubenNewCharActivityManager.CheckChallengeRedPoint()
end

return XRedPointConditionKoroCharActivityChallenge
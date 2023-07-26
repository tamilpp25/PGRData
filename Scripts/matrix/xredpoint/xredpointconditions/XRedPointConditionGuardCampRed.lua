
local XRedPointConditionGuardCampRed = {}
local Events = nil
function XRedPointConditionGuardCampRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_GUARD_CAMP_ACTIVITY_DATA_CHANGE),
    }
    return Events
end

function XRedPointConditionGuardCampRed.Check()
    if XDataCenter.GuardCampManager.CheckRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionGuardCampRed
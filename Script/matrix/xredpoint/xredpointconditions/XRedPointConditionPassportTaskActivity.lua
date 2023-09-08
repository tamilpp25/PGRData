
local XRedPointConditionPassportTaskActivity = {}

local Events = nil

function XRedPointConditionPassportTaskActivity.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportTaskActivity.Check()
    if XMVCA.XPassport:CheckPassportAchievedTaskRedPoint(XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY) then
        return true
    end
    return false
end

return XRedPointConditionPassportTaskActivity
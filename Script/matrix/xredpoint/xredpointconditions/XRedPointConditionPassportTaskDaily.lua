
local XRedPointConditionPassportTaskDaily = {}

local Events = nil

function XRedPointConditionPassportTaskDaily.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportTaskDaily.Check()
    if XMVCA.XPassport:CheckPassportAchievedTaskRedPoint(XEnumConst.PASSPORT.TASK_TYPE.DAILY) then
        return true
    end
    return false
end

return XRedPointConditionPassportTaskDaily

local XRedPointConditionPassportTaskWeekly = {}

local Events = nil

function XRedPointConditionPassportTaskWeekly.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportTaskWeekly.Check()
    if XDataCenter.PassportManager.CheckPassportAchievedTaskRedPoint(XPassportConfigs.TaskType.Weekly) then
        return true
    end
    return false
end

return XRedPointConditionPassportTaskWeekly
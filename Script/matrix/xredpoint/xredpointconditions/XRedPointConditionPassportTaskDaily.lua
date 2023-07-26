
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
    if XDataCenter.PassportManager.CheckPassportAchievedTaskRedPoint(XPassportConfigs.TaskType.Daily) then
        return true
    end
    return false
end

return XRedPointConditionPassportTaskDaily
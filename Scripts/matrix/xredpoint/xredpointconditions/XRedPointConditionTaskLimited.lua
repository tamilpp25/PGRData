
local XRedPointConditionTaskLimited = {}
local Events = nil
function XRedPointConditionTaskLimited.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionTaskLimited.Check(limitedId)
    if not limitedId then
        return false
    end
    for _, taskGroupId in pairs(limitedId) do
        if XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId) then
            return true
        end
    end
    return false
end



return XRedPointConditionTaskLimited
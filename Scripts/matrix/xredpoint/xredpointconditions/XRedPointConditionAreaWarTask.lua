local XRedPointConditionAreaWarTask = {}
local Events = nil

function XRedPointConditionAreaWarTask.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
        }
    return Events
end

function XRedPointConditionAreaWarTask.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    return XDataCenter.AreaWarManager.CheckAllTaskHasRewardToGet()
end

return XRedPointConditionAreaWarTask

local XRedPointConditionEscapeTask = {}
local Events = nil

function XRedPointConditionEscapeTask.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
        }
    return Events
end

function XRedPointConditionEscapeTask.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Escape) then
        return false
    end
    return XDataCenter.EscapeManager.CheckTaskCanReward()
end

return XRedPointConditionEscapeTask

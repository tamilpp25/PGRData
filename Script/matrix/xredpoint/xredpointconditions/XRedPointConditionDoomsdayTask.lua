local XRedPointConditionDoomsdayTask = {}
local Events = nil

function XRedPointConditionDoomsdayTask.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
        }
    return Events
end

function XRedPointConditionDoomsdayTask.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Doomsday) then
        return false
    end
    if not XDataCenter.DoomsdayManager.IsOpen() then
        return false
    end
    return XDataCenter.DoomsdayManager.CheckTaskRewardToGet()
end

return XRedPointConditionDoomsdayTask

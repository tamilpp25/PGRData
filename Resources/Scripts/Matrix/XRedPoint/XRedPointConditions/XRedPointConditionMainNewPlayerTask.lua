----------------------------------------------------------------
--新手任务奖励检测
local XRedPointConditionMainNewPlayerTask = {}
local Events = nil

function XRedPointConditionMainNewPlayerTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FUNCTION_OPEN_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_NEWBIETASK_DAYCHANGED),
        XRedPointEventElement.New(XEventId.EVENT_NEWBIETASK_PROGRESSCHANGED),
    }
    return Events
end

function XRedPointConditionMainNewPlayerTask.Check()

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Target) then
        return false
    end

    if XDataCenter.TaskManager.CheckNewbieActivenessAvailable() then
        return true
    end

    local newbieTasks = XTaskConfig.GetNewPlayerTaskGroupTemplate()
    for _, v in pairs(newbieTasks or {}) do
        if XDataCenter.TaskManager.GetNewbiePlayTaskReddotByOpenDay(v.OpenDay) then
            return true
        end
    end
    return false

end

return XRedPointConditionMainNewPlayerTask
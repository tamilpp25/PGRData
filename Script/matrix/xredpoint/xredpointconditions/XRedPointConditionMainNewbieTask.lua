-- 新手任务二期
local XRedPointConditionMainNewbieTask = {}
local Evnets = nil

function XRedPointConditionMainNewbieTask.GetSubEvents()
    Evnets = Evnets or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FUNCTION_OPEN_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_NEWBIE_TASK_UNLOCK_PERIOD_CHANGED),
    }
    return Evnets
end

function XRedPointConditionMainNewbieTask.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewbieTask) then
        return false
    end
    
    return XDataCenter.NewbieTaskManager.CheckActivityEntryRedPoint()
end

return XRedPointConditionMainNewbieTask
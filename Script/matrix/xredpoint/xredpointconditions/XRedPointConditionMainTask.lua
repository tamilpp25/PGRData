----------------------------------------------------------------
--主界面任务奖励检测
local XRedPointConditionMainTask = {}
local SubConditions = nil
function XRedPointConditionMainTask.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_TASK_COURSE,
        XRedPointConditions.Types.CONDITION_TASK_TYPE,
    }
    return SubConditions
end

function XRedPointConditionMainTask.Check()

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_COURSE) and (not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskStory)) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Story) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Daily) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Weekly) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Activity) then
        return true
    end


    return false
end

return XRedPointConditionMainTask
----------------------------------------------------------------
--单个类型任务奖励检测
local XRedPointConditionTaskType = {}
local Events = nil
function XRedPointConditionTaskType.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FUNCTION_OPEN_COMPLETE),
    }
    return Events
end

function XRedPointConditionTaskType.Check(taskTypeList)
    if type(taskTypeList) == "table" then
        for _, taskType in pairs(taskTypeList) do
            if XRedPointConditionTaskType.CheckImpl(taskType) then
                return true
            end
        end
    else
        return XRedPointConditionTaskType.CheckImpl(taskTypeList)
    end
    
    return false
end

function XRedPointConditionTaskType.CheckImpl(taskType)
    if taskType == XDataCenter.TaskManager.TaskType.Activity and (not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskActivity)
        or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskActivity)) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.Daily and (not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskDay)
        or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskDay)) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.Weekly and (not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.TaskWeekly)
        or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskWeekly)) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.Story and XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskStory) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.ArenaOnlineWeekly and (not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.ArenaOnline) or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ArenaOnline)) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.InfestorWeekly and (not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.FubenInfesotorExplore) or XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenInfesotorExplore)) then
        return false
    end

    if taskType == XDataCenter.TaskManager.TaskType.Daily then --日活跃
        if XDataCenter.TaskManager.CheckHasDailyActiveTaskReward() then
            return true
        end
        --去掉周任务判断
        --    if XDataCenter.TaskManager.CheckHasWeekActiveTaskReward() then
        --        return true
        --    end
    end

    return XDataCenter.TaskManager.GetIsRewardForEx(taskType)
end

return XRedPointConditionTaskType
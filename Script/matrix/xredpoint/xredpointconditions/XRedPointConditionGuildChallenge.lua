
local XRedPointConditionGuildChallenge = {}

local SubCondition = nil
function XRedPointConditionGuildChallenge.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_TASK_TYPE,
    }
    return SubCondition
end

function XRedPointConditionGuildChallenge.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        return false
    end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.GuildDaily) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.GuildMainly) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.GuildWeekly) then
        return true
    end

    return false
end

return XRedPointConditionGuildChallenge
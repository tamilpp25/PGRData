local XRedPointConditionKoroCharActivity = {}
local SubCondition = nil
function XRedPointConditionKoroCharActivity.GetSubConditions()
    SubCondition = SubCondition or
    {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
        XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK,
    }
    return SubCondition
end

function XRedPointConditionKoroCharActivity.Check(activityId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewCharAct) then
        return false
    end

    if not XDataCenter.FubenNewCharActivityManager.IsOpen() then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED, activityId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED, activityId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK, activityId) then
        return true
    end

    return false
end

return XRedPointConditionKoroCharActivity
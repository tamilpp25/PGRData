local XRedPointConditionKoroCharActivity = {}
local SubCondition = nil
function XRedPointConditionKoroCharActivity.GetSubConditions()
    SubCondition = SubCondition or
    {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
    }
    return SubCondition
end

function XRedPointConditionKoroCharActivity.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.NewCharAct) then
        return false
    end

    if not XDataCenter.FubenNewCharActivityManager.IsOpen() then
        return false
    end

    if XRedPointConditionKoroCharActivityChallenge.Check() then
        return true
    end

    if XRedPointConditionKoroCharActivityTeaching.Check() then
        return true
    end

    return false
end

return XRedPointConditionKoroCharActivity
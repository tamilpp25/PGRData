---三合一红点汇总
local XRedPointConditionLivWarmActivitySummary = {}
local SubCondition = nil

function XRedPointConditionLivWarmActivitySummary.GetSubConditions()
    SubCondition = SubCondition or
            {
                XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_REWARD,
                XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY_CAN_CHALLENGE,
            }
    return SubCondition
end

function XRedPointConditionLivWarmActivitySummary.Check()
    if XRedPointConditionLivWarmActivityReward.Check() then
        return true
    end

    if XRedPointConditionLivWarmActivityCanChallenge.Check() then
        return true
    end

    return false
end

return XRedPointConditionLivWarmActivitySummary
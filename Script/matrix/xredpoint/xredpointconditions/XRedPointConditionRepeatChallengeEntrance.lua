local XRedPointConditionRepeatChallengeEntrance={}
local SubCondition = nil

function XRedPointConditionRepeatChallengeEntrance.GetSubConditions()
    return {
        XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_REWARD,
        XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_COIN,
    }
end

function XRedPointConditionRepeatChallengeEntrance.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_REWARD) or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_COIN)
end

return XRedPointConditionRepeatChallengeEntrance
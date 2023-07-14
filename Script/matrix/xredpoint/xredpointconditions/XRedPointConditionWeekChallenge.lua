----------------------------------------------------------------
local XRedPointConditionWeekChallenge = {}

function XRedPointConditionWeekChallenge.Check()
    return XDataCenter.WeekChallengeManager.IsAnyRewardCanReceived()
end

return XRedPointConditionWeekChallenge
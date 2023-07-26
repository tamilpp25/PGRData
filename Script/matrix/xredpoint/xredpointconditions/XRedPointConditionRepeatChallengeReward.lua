--角色入口红点检测
local XRedPointConditionRepeatChallengeReward = {}
local SubCondition = nil
function XRedPointConditionRepeatChallengeReward.GetSubConditions()
    return { } 
end

function XRedPointConditionRepeatChallengeReward.Check()
    return XDataCenter.FubenRepeatChallengeManager.GetRewardRed()
end

return XRedPointConditionRepeatChallengeReward
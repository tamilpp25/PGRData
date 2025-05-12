--角色入口红点检测
--- 2.13复刷关转常驻后奖励只在版本公告
local XRedPointConditionRepeatChallengeReward = {}
local SubCondition = nil

function XRedPointConditionRepeatChallengeReward.Check(taskTimeLimitId)
    local rewardRed = false
    if XTool.IsNumberValid(taskTimeLimitId) then
        rewardRed = XDataCenter.FubenRepeatChallengeManager.GetRewardRed(taskTimeLimitId)
    end
    return rewardRed

end

return XRedPointConditionRepeatChallengeReward
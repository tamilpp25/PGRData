--有可领取的任务奖励
local XRedPointConditionTheatreTaskRewardRedPoint = {}

function XRedPointConditionTheatreTaskRewardRedPoint.Check()
    return XDataCenter.TheatreManager.CheckTaskCanReward()
end

return XRedPointConditionTheatreTaskRewardRedPoint
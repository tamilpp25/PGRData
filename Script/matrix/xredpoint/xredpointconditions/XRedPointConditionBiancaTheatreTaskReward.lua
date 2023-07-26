--有可领取的任务奖励
local XRedPointConditionBiancaTheatreTaskReward = {}

function XRedPointConditionBiancaTheatreTaskReward.Check()
    return XDataCenter.BiancaTheatreManager.CheckTaskCanReward()
end

return XRedPointConditionBiancaTheatreTaskReward
----------------------------------------------------------------
--超难关：有可领取的奖励
local XRedPointConditionActivityBossSingleReward = {}

function XRedPointConditionActivityBossSingleReward.Check()
    return XDataCenter.FubenActivityBossSingleManager.CheckRedPoint()
end

return XRedPointConditionActivityBossSingleReward
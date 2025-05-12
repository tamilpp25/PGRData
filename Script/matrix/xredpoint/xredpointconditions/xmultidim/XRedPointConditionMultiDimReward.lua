----------------------------------------------------------------
--超难关：有可领取的奖励
local XRedPointConditionMultiDimReward = {}

function XRedPointConditionMultiDimReward.Check()
    return XDataCenter.MultiDimManager.CheckLimitTaskGroup()
end

return XRedPointConditionMultiDimReward
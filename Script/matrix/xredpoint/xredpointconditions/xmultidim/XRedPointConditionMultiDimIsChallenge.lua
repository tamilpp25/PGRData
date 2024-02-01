----------------------------------------------------------------
--超难关：有可领取的奖励
local XRedPointConditionMultiDimIsChallenge = {}

function XRedPointConditionMultiDimIsChallenge.Check()
    return XDataCenter.MultiDimManager.CheckTeamIsOpen()
end

return XRedPointConditionMultiDimIsChallenge
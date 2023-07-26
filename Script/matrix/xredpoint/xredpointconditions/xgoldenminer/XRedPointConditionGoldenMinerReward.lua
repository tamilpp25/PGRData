local XRedPointConditionGoldenMinerReward = {}

function XRedPointConditionGoldenMinerReward.Check()
    if XDataCenter.GoldenMinerManager.CheckTaskCanReward() then
        return true
    end
    return false
end

return XRedPointConditionGoldenMinerReward
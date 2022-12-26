local XRedPointConditionBabelTowerReward = {}

function XRedPointConditionBabelTowerReward.Check()
    local isRewardFor = XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.BabelTower)
    if isRewardFor then
        return true
    end

    return false
end

return XRedPointConditionBabelTowerReward
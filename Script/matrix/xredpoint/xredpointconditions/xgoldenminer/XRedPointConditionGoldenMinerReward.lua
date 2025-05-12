local XRedPointConditionGoldenMinerReward = {}

function XRedPointConditionGoldenMinerReward.Check()
    if XMVCA.XGoldenMiner:CheckHaveTaskCanRecv() then
        return true
    end
    return false
end

return XRedPointConditionGoldenMinerReward
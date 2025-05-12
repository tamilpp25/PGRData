local XRedPointConditionStageMemory = {}

function XRedPointConditionStageMemory.Check()
    if XMVCA.XStageMemory:IsShowRewardRedPoint() then
        return true
    end
    if XMVCA.XStageMemory:GetHasViewedToday() then
        return false
    end
    return XMVCA.XStageMemory:IsShowChallengeRedPoint()
end

return XRedPointConditionStageMemory
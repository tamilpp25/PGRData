local XRedPointConditionBossSingleAll = {}

function XRedPointConditionBossSingleAll.Check()
    local data = XMVCA.XFubenBossSingle:GetBossSingleData()
    local rewardCount = XMVCA.XFubenBossSingle:CheckRewardRedHint()
    local challengeCount = 0
    
    if data and not data:IsNewVersion() then
        return rewardCount
    end
    if XMVCA.XFubenBossSingle:CheckChallengeRedPoint() then
        challengeCount = 2
    end

    return rewardCount + challengeCount
end

return XRedPointConditionBossSingleAll

local XClickClearGameRewardData = XClass(nil, "XClickClearGameRewardData")

function XClickClearGameRewardData:Ctor(gameStageId, rewardId, rewardConditionDesc)
    self.GameStageId = gameStageId
    self.RewardId = rewardId
    self.ConditionDesc = rewardConditionDesc
    self.IsTaked = false
    self.IsCanTake = false
end

function XClickClearGameRewardData:GetGameStageId()
    return self.GameStageId
end

function XClickClearGameRewardData:GetRewardId()
    return self.RewardId
end

function XClickClearGameRewardData:GetConditionDesc()
    return self.ConditionDesc
end

function XClickClearGameRewardData:CheckIsTaked()
    return self.IsTaked
end

function XClickClearGameRewardData:SetIsTaked(isTaked)
    self.IsTaked = isTaked
end

function XClickClearGameRewardData:CheckCanTake()
    return self.IsCanTake
end

function XClickClearGameRewardData:SetCanTake(canTake)
    self.IsCanTake = canTake
end

return XClickClearGameRewardData
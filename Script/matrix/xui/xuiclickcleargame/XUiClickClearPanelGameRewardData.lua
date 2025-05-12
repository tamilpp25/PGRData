local XUiClickClearPanelGameRewardData = XClass(nil, "XUiClickClearPanelGameRewardData")

function XUiClickClearPanelGameRewardData:Ctor(gameStageId, rewardId, rewardConditionDesc)
    self.GameStageId = gameStageId
    self.RewardId = rewardId
    self.ConditionDesc = rewardConditionDesc
    self.IsTaked = false
    self.IsCanTake = false
end

function XUiClickClearPanelGameRewardData:GetGameStageId()
    return self.GameStageId
end

function XUiClickClearPanelGameRewardData:GetRewardId()
    return self.RewardId
end

function XUiClickClearPanelGameRewardData:GetConditionDesc()
    return self.ConditionDesc
end

function XUiClickClearPanelGameRewardData:CheckIsTaked()
    return self.IsTaked
end

function XUiClickClearPanelGameRewardData:SetIsTaked(isTaked)
    self.IsTaked = isTaked
end

function XUiClickClearPanelGameRewardData:CheckCanTake()
    return self.IsCanTake
end

function XUiClickClearPanelGameRewardData:SetCanTake(canTake)
    self.IsCanTake = canTake
end

return XUiClickClearPanelGameRewardData
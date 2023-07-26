local XPFReward = XClass(nil, "XPFReward")

function XPFReward:Ctor(id)
    self.Config = XPickFlipConfigs.GetRewardConfig(id)
    -- 奖励领取状态 0未开启 1已开启 XPickFlipConfigs.RewardState
    self.State = 0
    -- 奖励所在的位置
    self.Index = 0
end

function XPFReward:SetIndex(value)
    self.Index = value
end

function XPFReward:GetIndex()
    return self.Index 
end

-- XPickFlipConfigs.RewardState
function XPFReward:SetState(value)
    self.State = value
end

-- XPickFlipConfigs.RewardState
function XPFReward:GetState()
    return self.State
end

function XPFReward:GetId()
    return self.Config.Id
end

function XPFReward:GetIcon()
    return XEntityHelper.GetItemIcon(self:GetShowItemId())
end

function XPFReward:GetCount()
    return self.Config.Count
end

function XPFReward:GetIsReceived()
    return self.State == XPickFlipConfigs.RewardState.Fliped
end

function XPFReward:GetShowItemId()
    return self.Config.TemplateId
end

function XPFReward:GetType()
    return self.Config.Type
end

return XPFReward
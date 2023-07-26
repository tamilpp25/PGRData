local XPhasesRewardEntity = XClass(nil, "XPhasesRewardEntity")

function XPhasesRewardEntity:Ctor(id)
    self.Id = id
    self.IsCanGet = false
    self.IsGeted = false
end

function XPhasesRewardEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XPhasesRewardEntity:GetCfg()
    return XWorldBossConfigs.GetPhasesRewardemplatesById(self.Id)
end

function XPhasesRewardEntity:GetId()
    return self.Id
end

function XPhasesRewardEntity:GetIsCanGet()
    return self.IsCanGet
end

function XPhasesRewardEntity:GetIsGeted()
    return self.IsGeted
end

function XPhasesRewardEntity:GetHpPercent()
    return self:GetCfg().HpPercent
end

function XPhasesRewardEntity:GetRewardId()
    return self:GetCfg().RewardId
end

return XPhasesRewardEntity
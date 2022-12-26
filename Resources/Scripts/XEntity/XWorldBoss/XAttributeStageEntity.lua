local XAttributeStageEntity = XClass(nil, "XAttributeStageEntity")

function XAttributeStageEntity:Ctor(id)
    self.Id = id
    self.RewardFlag = false
    self.FinishCount = 0
    self.IsLock = true
    self.LockDesc = ""
end

function XAttributeStageEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
end

function XAttributeStageEntity:GetCfg()
    return XWorldBossConfigs.GetAttributeStageTemplatesById(self.Id)
end

function XAttributeStageEntity:GetStageCfg()
    return XDataCenter.FubenManager.GetStageCfg(self.Id)
end

function XAttributeStageEntity:GetId()
    return self.Id
end

function XAttributeStageEntity:GetIsRewardGeted()--区域关卡奖励是否领取
    return self.RewardFlag
end

function XAttributeStageEntity:GetFinishCount()--区域关卡全局完成次数
    return self.FinishCount
end

function XAttributeStageEntity:GetIsLock()--区域关卡是否未开启
    return self.IsLock
end

function XAttributeStageEntity:GetLockDesc()--区域关卡上锁提示
    return self.LockDesc
end

function XAttributeStageEntity:GetTotalFinishCount()
    return self:GetCfg().TotalFinishCount
end

function XAttributeStageEntity:GetPreStageId()
    return self:GetCfg().PreStageId
end

function XAttributeStageEntity:GetFinishReward()
    return self:GetCfg().FinishReward
end

function XAttributeStageEntity:GetBuffIds()
    return self:GetCfg().BuffId
end

function XAttributeStageEntity:GetConsumeId()
    return self:GetCfg().ConsumeId
end

function XAttributeStageEntity:GetConsumeCount()
    return self:GetCfg().ConsumeCount
end

function XAttributeStageEntity:GetStartStoryId()
    return self:GetCfg().StartStoryId
end

function XAttributeStageEntity:GetIsFinish()--区域关卡是否完成
    return self.FinishCount >= self:GetTotalFinishCount()
end

function XAttributeStageEntity:GetFinishPercent()--区域关卡是否完成
    return math.min(1, self.FinishCount / self:GetTotalFinishCount())
end

return XAttributeStageEntity
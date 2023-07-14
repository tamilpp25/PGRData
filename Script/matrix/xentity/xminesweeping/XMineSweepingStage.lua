local XMineSweepingStage = XClass(nil, "XMineSweepingStage")

function XMineSweepingStage:Ctor(id)
    self.StageId = id
    self.WhiteGridTotalNumber = 1--白色格总数（胜利条件）
    self.AllowMineNumber = 1--允许踩到雷格最大数（失败条件）
    self.WhiteGridOpenNumber = 0--已翻开白色格数
    self.MineGridOpenNumber = 0--已翻开雷格数
    self.FailedCounts = 0--已失败次数
    self.Status = XMineSweepingConfigs.StageState.Prepare --此状态代表关卡状态，章节状态就取自当前关卡状态
    self.IsStageLock = true
end

function XMineSweepingStage:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
    end
end

function XMineSweepingStage:GetStageId()
    return self.StageId
end

function XMineSweepingStage:GetWhiteGridTotalNumber()
    return self.WhiteGridTotalNumber
end

function XMineSweepingStage:GetAllowMineNumber()
    return self.AllowMineNumber
end

function XMineSweepingStage:GetWhiteGridOpenNumber()
    return self.WhiteGridOpenNumber
end

function XMineSweepingStage:GetMineGridOpenNumber()
    return self.MineGridOpenNumber
end

function XMineSweepingStage:GetFailedCounts()
    return self.FailedCounts
end

function XMineSweepingStage:GetStageStatus()
    return self.Status
end

function XMineSweepingStage:IsOngoing()
    return not self:IsFinish() and not self:IsFailed()
end

function XMineSweepingStage:IsLock()
    return self.IsStageLock
end

function XMineSweepingStage:IsFinish()
    return self.Status == XMineSweepingConfigs.StageState.Finish
end

function XMineSweepingStage:IsFailed()
    return self.Status == XMineSweepingConfigs.StageState.Failed
end

function XMineSweepingStage:GetCfg()
    return XMineSweepingConfigs.GetMineSweepingStageById(self.StageId)
end

function XMineSweepingStage:GetName()
    local tmpName = self:GetCfg().Name
    return string.gsub(tmpName,"_","-")
end

function XMineSweepingStage:GetCostCoinNum()
    return self:GetCfg().CostCoinNum
end

function XMineSweepingStage:GetRowCount()
    return self:GetCfg().RowCount
end

function XMineSweepingStage:GetColumnCount()
    return self:GetCfg().ColumnCount
end

function XMineSweepingStage:GetRewardId()
    return self:GetCfg().RewardId
end

function XMineSweepingStage:GetWinEffect()
    return self:GetCfg().WinEffect
end

function XMineSweepingStage:GetCanFailedCounts()
    return self:GetCfg().CanFailedCounts
end

function XMineSweepingStage:GetCanFailedCountByIndex(index)
    return self:GetCfg().CanFailedCounts[index] or 0
end

return XMineSweepingStage
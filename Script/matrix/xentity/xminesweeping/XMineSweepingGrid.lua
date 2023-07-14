local XMineSweepingGrid = XClass(nil, "XMineSweepingGrid")

function XMineSweepingGrid:Ctor(x, y)
    self.XIndex = x
    self.YIndex = y
    self.Type = XMineSweepingConfigs.GridType.Unknown
    self.RoundMineNumber = 0
end

function XMineSweepingGrid:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
    end
end

function XMineSweepingGrid:GetPosIndex()
    return self.XIndex, self.YIndex
end

function XMineSweepingGrid:IsUnknown()
    return self.Type == XMineSweepingConfigs.GridType.Unknown
end

function XMineSweepingGrid:IsSafe()
    return self.Type == XMineSweepingConfigs.GridType.Safe
end

function XMineSweepingGrid:IsMine()
    return self.Type == XMineSweepingConfigs.GridType.Mine
end

function XMineSweepingGrid:IsFlag()
    return self.Type == XMineSweepingConfigs.GridType.Flag
end

function XMineSweepingGrid:ResetGridType()
    self.Type = XMineSweepingConfigs.GridType.Unknown
    self.RoundMineNumber = 0
end

function XMineSweepingGrid:GetRoundMineNumber()
    return self.RoundMineNumber
end

return XMineSweepingGrid
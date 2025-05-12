---@class XRogueSimEventGamble
local XRogueSimEventGamble = XClass(nil, "XRogueSimEventGamble")

function XRogueSimEventGamble:Ctor()
    -- 自增ID
    self.Id = 0
    -- 配置表ID
    self.EventOptionId = 0
    -- 格子ID
    self.GridId = 0
    -- 可领奖励回合数
    self.RewardTurnNumber = 0
    -- 奖励比例索引
    self.RewardRateIndex = -1
    -- 消耗资源与货物
    self.CostResourceIds = {}
    self.CostResourceCounts = {}
    self.CostCommodityIds = {}
    self.CostCommodityCounts = {}
end

function XRogueSimEventGamble:UpdateEventGambleData(data)
    self.Id = data.Id or 0
    self.EventOptionId = data.EventOptionId or 0
    self.GridId = data.GridId or 0
    self.RewardTurnNumber = data.RewardTurnNumber or 0
    self.RewardRateIndex = data.RewardRateIndex or -1
    self.CostResourceIds = data.CostResourceIds or {}
    self.CostResourceCounts = data.CostResourceCounts or {}
    self.CostCommodityIds = data.CostCommodityIds or {}
    self.CostCommodityCounts = data.CostCommodityCounts or {}
end

function XRogueSimEventGamble:GetId()
    return self.Id
end

function XRogueSimEventGamble:GetEventOptionId()
    return self.EventOptionId
end

function XRogueSimEventGamble:GetGridId()
    return self.GridId
end

function XRogueSimEventGamble:GetRewardTurnNumber()
    return self.RewardTurnNumber
end

function XRogueSimEventGamble:GetRewardRateIndex()
    return self.RewardRateIndex + 1
end

function XRogueSimEventGamble:GetCostResourceIds()
    return self.CostResourceIds
end

function XRogueSimEventGamble:GetCostResourceCounts()
    return self.CostResourceCounts
end

function XRogueSimEventGamble:GetCostCommodityIds()
    return self.CostCommodityIds
end

function XRogueSimEventGamble:GetCostCommodityCounts()
    return self.CostCommodityCounts
end

return XRogueSimEventGamble

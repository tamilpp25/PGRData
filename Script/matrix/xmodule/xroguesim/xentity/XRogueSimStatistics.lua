---@class XRogueSimStatistics
local XRogueSimStatistics = XClass(nil, "XRogueSimStatistics")

function XRogueSimStatistics:Ctor()
    -- 销售统计
    ---@type table<number, number>
    self.Sales = {}
    -- 生产统计
    ---@type table<number, number>
    self.Productions = {}
    -- 事件统计
    ---@type table<number, number>
    self.Events = {}
    -- 金币统计
    self.Gold = 0
    -- 回合内金币统计
    self.GoldInTurn = 0
    -- 经验统计
    self.Exp = 0
    -- 回合内临时背包生产统计
    ---@type table<number, number>
    self.ProductionsInBagTurn = {}
    -- 回合内探索格子数
    self.ExploredGridCountInTurn = 0
end

function XRogueSimStatistics:UpdateStatisticsData(data)
    self.Sales = data.Sales or {}
    self.Productions = data.Productions or {}
    self.Events = data.Events or {}
    self.Gold = data.Gold or 0
    self.GoldInTurn = data.GoldInTurn or 0
    self.Exp = data.Exp or 0
    self.ProductionsInBagTurn = data.ProductionsInBagTurn or {}
    self.ExploredGridCountInTurn = data.ExploredGridCountInTurn or 0
end

-- 获取销售统计数量通过货物Id
function XRogueSimStatistics:GetSellStatisticsCountById(id)
    return self.Sales[id] or 0
end

-- 获取生产统计数量通过货物Id
function XRogueSimStatistics:GetProductionStatisticsCountById(id)
    return self.Productions[id] or 0
end

-- 获取事件统计数量通过事件Id
function XRogueSimStatistics:GetEventStatisticsCountById(id)
    return self.Events[id] or 0
end

-- 获取金币统计数量
function XRogueSimStatistics:GetGoldStatisticsCount()
    return self.Gold
end

return XRogueSimStatistics

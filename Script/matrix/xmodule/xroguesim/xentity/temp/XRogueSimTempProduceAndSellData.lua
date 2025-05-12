-- 临时生成和销售数据
---@class XRogueSimTempProduceAndSellData
local XRogueSimTempProduceAndSellData = XClass(nil, "XRogueSimTempProduceAndSellData")

function XRogueSimTempProduceAndSellData:Ctor()
    -- 分配的生产力
    self.ProducePlan = {}
    -- 出售数量
    self.SellPlan = {}
    -- 出售预设比例
    self.SellPlanPreset = {}
end

-- 更新生产数据
function XRogueSimTempProduceAndSellData:UpdateTempProducePlanById(id, count)
    self.ProducePlan[id] = count
end

-- 更新销售数据
function XRogueSimTempProduceAndSellData:UpdateTempSellPlanById(id, count)
    self.SellPlan[id] = count
end

-- 更新销售预设数据
function XRogueSimTempProduceAndSellData:UpdateTempSellPlanPresetById(id, count)
    self.SellPlanPreset[id] = count
end

-- 获取生产数据
function XRogueSimTempProduceAndSellData:GetTempProducePlanCountById(id)
    return self.ProducePlan[id] or 0
end

-- 获取销售数据
function XRogueSimTempProduceAndSellData:GetTempSellPlanCountById(id)
    return self.SellPlan[id] or 0
end

-- 获取销售预设数据
function XRogueSimTempProduceAndSellData:GetTempSellPlanPresetCountById(id)
    return self.SellPlanPreset[id] or 0
end

return XRogueSimTempProduceAndSellData

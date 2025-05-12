---@class XRogueSimCommodityProduceResultItem
local XRogueSimCommodityProduceResultItem = XClass(nil, "XRogueSimCommodityProduceResultItem")

function XRogueSimCommodityProduceResultItem:Ctor()
    self.CommodityId = 0
    self.ProduceCount = 0
    self.IsCritical = false
    self.IsOverflow = false
end

function XRogueSimCommodityProduceResultItem:UpdateProduceResultItem(data)
    self.CommodityId = data.CommodityId or 0
    self.ProduceCount = data.ProduceCount or 0
    self.IsCritical = data.IsCritical or false
    self.IsOverflow = data.IsOverflow or false
end

-- 获取货物Id
function XRogueSimCommodityProduceResultItem:GetCommodityId()
    return self.CommodityId
end

-- 获取生产数量
function XRogueSimCommodityProduceResultItem:GetProduceCount()
    return self.ProduceCount
end

-- 是否暴击
function XRogueSimCommodityProduceResultItem:GetIsCritical()
    return self.IsCritical
end

-- 是否溢出
function XRogueSimCommodityProduceResultItem:GetIsOverflow()
    return self.IsOverflow
end

return XRogueSimCommodityProduceResultItem

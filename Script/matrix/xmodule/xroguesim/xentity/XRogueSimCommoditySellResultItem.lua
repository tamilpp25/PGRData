---@class XRogueSimCommoditySellResultItem
local XRogueSimCommoditySellResultItem = XClass(nil, "XRogueSimCommoditySellResultItem")

function XRogueSimCommoditySellResultItem:Ctor()
    self.CommodityId = 0
    self.Price = 0
    self.PriceRate = 0
    self.SellCount = 0
    self.SellAwardCount = 0
    self.IsCritical = false
end

function XRogueSimCommoditySellResultItem:UpdateSellResultItem(data)
    self.CommodityId = data.CommodityId or 0
    self.Price = data.Price or 0
    self.PriceRate = data.PriceRate or 0
    self.SellCount = data.SellCount or 0
    self.SellAwardCount = data.SellAwardCount or 0
    self.IsCritical = data.IsCritical or false
end

-- 获取货物Id
function XRogueSimCommoditySellResultItem:GetCommodityId()
    return self.CommodityId
end

-- 获取货物单价
function XRogueSimCommoditySellResultItem:GetPrice()
    return self.Price
end

-- 获取货物单价倍率
function XRogueSimCommoditySellResultItem:GetPriceRate()
    return self.PriceRate
end

-- 获取出售数量
function XRogueSimCommoditySellResultItem:GetSellCount()
    return self.SellCount
end

-- 获取货物出售价格
function XRogueSimCommoditySellResultItem:GetSellAwardCount()
    return self.SellAwardCount
end

-- 是否暴击
function XRogueSimCommoditySellResultItem:GetIsCritical()
    return self.IsCritical
end

return XRogueSimCommoditySellResultItem

---@class XTheatre4ShopGoods
local XTheatre4ShopGoods = XClass(nil, "XTheatre4ShopGoods")

function XTheatre4ShopGoods:Ctor()
    -- 商品id
    self.GoodsId = 0
    -- 库存
    self.Stock = 0
    -- 是否免费
    self.IsFree = false
end

-- 服务端通知
function XTheatre4ShopGoods:NotifyShopGoodsData(data)
    self.GoodsId = data.GoodsId or 0
    self.Stock = data.Stock or 0
    self.IsFree = data.IsFree or false
end

-- 获取商品Id
function XTheatre4ShopGoods:GetGoodsId()
    return self.GoodsId
end

-- 获取库存
function XTheatre4ShopGoods:GetStock()
    return self.Stock
end

-- 是否免费
function XTheatre4ShopGoods:GetIsFree()
    return self.IsFree
end

return XTheatre4ShopGoods

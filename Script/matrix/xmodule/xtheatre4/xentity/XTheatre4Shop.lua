---@class XTheatre4Shop
local XTheatre4Shop = XClass(nil, "XTheatre4Shop")

function XTheatre4Shop:Ctor()
    -- 商店id
    self.ShopId = 0
    -- 已刷新次数
    self.RefreshTimes = 0
    -- 商品列表 可重复
    ---@type XTheatre4ShopGoods[]
    self.Goods = {}
    -- 免费购买次数
    self.FreeBuyTimes = 0
    -- 折扣(万分比)
    self.Discount = 0
end

-- 服务端通知
function XTheatre4Shop:NotifyShopData(data)
    self.ShopId = data.ShopId or 0
    self.RefreshTimes = data.RefreshTimes or 0
    self:UpdateGoods(data.Goods)
    self.FreeBuyTimes = data.FreeBuyTimes or 0
    self.Discount = data.Discount or 0
end

function XTheatre4Shop:UpdateGoods(data)
    self.Goods = {}
    if not data then
        return
    end
    for k, v in ipairs(data) do
        self:AddGoods(k, v)
    end
end

function XTheatre4Shop:AddGoods(index, data)
    if not data then
        return
    end
    ---@type XTheatre4ShopGoods
    local goods = require("XModule/XTheatre4/XEntity/XTheatre4ShopGoods").New()
    goods:NotifyShopGoodsData(data)
    self.Goods[index] = goods
end

-- 获取商店Id
function XTheatre4Shop:GetShopId()
    return self.ShopId
end

-- 获取已刷新次数
function XTheatre4Shop:GetRefreshTimes()
    return self.RefreshTimes
end

-- 获取商品列表
---@return XTheatre4ShopGoods[]
function XTheatre4Shop:GetGoods()
    return self.Goods
end

-- 获取免费购买次数
function XTheatre4Shop:GetFreeBuyTimes()
    return self.FreeBuyTimes
end

-- 获取折扣
function XTheatre4Shop:GetDiscount()
    -- 无折扣
    if self.Discount == 0 then
        return 1
    end
    local discount = self.Discount + XEnumConst.Theatre4.RatioDenominator
    if discount <= 0 then
        return 0
    end
    return discount / XEnumConst.Theatre4.RatioDenominator
end

return XTheatre4Shop

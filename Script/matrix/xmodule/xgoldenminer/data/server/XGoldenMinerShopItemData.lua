local XGoldenMinerItemBase = require("XModule/XGoldenMiner/Data/Base/XGoldenMinerItemBase")

--黄金矿工商店随机出的商品
---@class XGoldenMinerShopItemData:XGoldenMinerItemBase
local XGoldenMinerShopItemData = XClass(XGoldenMinerItemBase, "XGoldenMinerShopItemData")

function XGoldenMinerShopItemData:Ctor()
    self._BuyStatus = 0 --是否已经被购买
    self._Prices = 0    --售价（未算上折扣
end

function XGoldenMinerShopItemData:UpdateData(data)
    self._Prices = data.Prices
    self:UpdateBuyStatus(data.BuyStatus)
end

function XGoldenMinerShopItemData:UpdateBuyStatus(state)
    self._BuyStatus = state
end

function XGoldenMinerShopItemData:GetGoldItemId()
    return self:GetItemId()
end

function XGoldenMinerShopItemData:GetBuyStatus()
    return self._BuyStatus
end

function XGoldenMinerShopItemData:GetPrices()
    return self._Prices
end

return XGoldenMinerShopItemData
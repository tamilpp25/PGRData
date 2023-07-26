local XGoldenMinerItemBase = require("XEntity/XGoldenMiner/XGoldenMinerItemBase")
local type = type

--黄金矿工商店随机出的商品
---@class XGoldenMinerCommodityDb:XGoldenMinerItemBase
local XGoldenMinerCommodityDb = XClass(XGoldenMinerItemBase, "XGoldenMinerCommodityDb")

local Default = {
    _BuyStatus = 0, --是否已经被购买
    _Prices = 0,    --售价（未算上折扣）
}

function XGoldenMinerCommodityDb:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XGoldenMinerCommodityDb:UpdateData(data)
    self._Prices = data.Prices
    self:UpdateBuyStatus(data.BuyStatus)
end

function XGoldenMinerCommodityDb:UpdateBuyStatus(state)
    self._BuyStatus = state
end

function XGoldenMinerCommodityDb:GetGoldItemId()
    return self:GetItemId()
end

function XGoldenMinerCommodityDb:GetBuyStatus()
    return self._BuyStatus
end

function XGoldenMinerCommodityDb:GetPrices()
    return self._Prices
end

return XGoldenMinerCommodityDb
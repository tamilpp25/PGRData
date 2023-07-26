local XSpecialSaleEntity = XClass(nil, "XSpecialSaleEntity")

function XSpecialSaleEntity:Ctor(id)
    self.Id = id
    self.IsPurchased = false

    self.DiscountDic = {}
    for _,discountId in pairs(self:GetDiscountIds() or {}) do
        self.DiscountDic[discountId] = self:GetDiscountCfgById(discountId)
    end

    self.MinConsumeCount = 0
    self.MinDiscountText = ""
end

function XSpecialSaleEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XSpecialSaleEntity:GetCfg()
    return XWorldBossConfigs.GetBossShopTemplatesById(self.Id)
end

function XSpecialSaleEntity:GetDiscountCfgById(id)
    return XWorldBossConfigs.GetBossShopDiscountTemplatesById(id)
end

function XSpecialSaleEntity:GetId()
    return self.Id
end

function XSpecialSaleEntity:GetDiscountDic()--打折数据字典
    return self.DiscountDic
end

function XSpecialSaleEntity:GetRewardId()
    return self:GetCfg().RewardId
end

function XSpecialSaleEntity:GetConsumeId()
    return self:GetCfg().ConsumeId
end

function XSpecialSaleEntity:GetConsumeCount()
    return self:GetCfg().ConsumeCount
end

function XSpecialSaleEntity:GetMinConsumeCount()
    return self.MinConsumeCount
end

function XSpecialSaleEntity:GetMinDiscountText()
    return self.MinDiscountText
end

function XSpecialSaleEntity:GetDiscountIds()
    return self:GetCfg().DiscountId
end

function XSpecialSaleEntity:GetShopImg()
    return self:GetCfg().ShopImg
end

function XSpecialSaleEntity:GetDiscountDic()
    return self.DiscountDic
end

function XSpecialSaleEntity:GetDiscountById(id)
    if not self.DiscountDic[id] then
        XLog.Error("SpecialSale Id:"..self.Id.." Is Not Have Discount id:"..id)
    end
    return self.DiscountDic[id]
end

return XSpecialSaleEntity
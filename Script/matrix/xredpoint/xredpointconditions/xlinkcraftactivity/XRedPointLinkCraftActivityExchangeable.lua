local XRedPointLinkCraftActivityExchangeable = {}

function XRedPointLinkCraftActivityExchangeable.Check()
    
    local timeId = XMVCA.XLinkCraftActivity:GetClientConfigInt('ShopShowReddotTimeId')

    if not XTool.IsNumberValid(timeId) or not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    
    local shopId = XMVCA.XLinkCraftActivity:GetCurShopId()
    if XTool.IsNumberValid(shopId) then
        local goods = XShopManager.GetShopGoodsList(shopId, true)
        --判断当前货币是否能购买那些还有余量的商品，能则为true
        for i, v in ipairs(goods) do
            -- 先判断商品是否解锁
            local conditionIds = v.ConditionIds
            local goodsUnLock = true
            if not XTool.IsTableEmpty(conditionIds) then
                if XTool.GetTableCount(v.ConditionIds) > 0 then
                    for _, id in pairs(v.ConditionIds) do
                        local ret, desc = XConditionManager.CheckCondition(id)
                        if not ret then
                            goodsUnLock = false
                            break
                        end
                    end
                end
            end
            
            if goodsUnLock and v.TotalBuyTimes < v.BuyTimesLimit then
                for i2, v2 in ipairs(v.ConsumeList) do
                    if XDataCenter.ItemManager.GetCount(v2.Id) >= v2.Count then
                        return true
                    end
                end
            end
        end
        return false
    else
        return false
    end
end


return XRedPointLinkCraftActivityExchangeable
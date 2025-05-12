local XRedPointGame2048Store = {}

function XRedPointGame2048Store:Check()
    if not XMVCA.XGame2048:ExCheckInTime() or not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Game2048, false, true) then
        return false
    end

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, false, true) then
        return false
    end
    
    if not XMVCA.XGame2048:CheckLeftDaySatisfyStoreReddotEnable() then
        return false
    end

    local shopId = XMVCA.XGame2048:GetCurShopId()
    if XTool.IsNumberValid(shopId) then
        local goods = XShopManager.GetShopGoodsList(shopId, true)
        local now = XTime.GetServerNowTimestamp()
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

            if XTool.IsNumberValid(v.OnSaleTime) and now < v.OnSaleTime then
                goodsUnLock = false
            end

            if XTool.IsNumberValid(v.SelloutTime) and XShopManager.GetLeftTime(v.SelloutTime) <= 0 then
                goodsUnLock = false
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

return XRedPointGame2048Store
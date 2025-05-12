local XRedPointConditionRepeatChallengeCoin={}

function XRedPointConditionRepeatChallengeCoin.Check()
    if  XDataCenter.FubenRepeatChallengeManager.IsOpen() then
        ---@type XTableRepeatChallengeActivity
        local activityCfg = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig()

        if activityCfg and XTool.IsNumberValid(activityCfg.ActcvityShopId) then
            return XRedPointConditionRepeatChallengeCoin.CheckIsShopExchangeable(activityCfg.ActcvityShopId, activityCfg.ShopRedPointSortId)
        end
        
    end
    
    return false
end

function XRedPointConditionRepeatChallengeCoin.CheckIsShopExchangeable(shopId, sortId)
    if XTool.IsNumberValid(shopId) then
        if not XDataCenter.ActivityBriefManager.CheckShopInTimeByShopId(shopId) then
            return false
        end
        
        local goods = XShopManager.GetShopGoodsList(shopId, true)
        
        local targetGoods = nil
        local hasTargetLimit = false
        if XTool.IsNumberValid(sortId) then
            targetGoods = XActivityBriefConfigs.GetActivityShopGoodsSortById(sortId)
            if targetGoods then
                targetGoods = targetGoods.TargetIds
                hasTargetLimit = not XTool.IsTableEmpty(targetGoods)
            end
        end
        
        -- 没有限定商品则无需红点
        if not hasTargetLimit then
            return false
        end
        
        --判断当前货币是否能购买那些还有余量的商品，能则为true
        for i, v in ipairs(goods) do
            -- 没有购买上限次数的商品不用判断
            if not XTool.IsNumberValid(v.BuyTimesLimit) then
                goto CONTINUE
            end
            
            -- 不属于限定商品的不用判断
            if hasTargetLimit and not table.contains(targetGoods, v.Id) then
                goto CONTINUE
            end
            
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
            -- 复刷关活动商店内的限购道具的限购次数未全部消耗完
            if goodsUnLock and v.TotalBuyTimes < v.BuyTimesLimit then
                return true
            end
            
            :: CONTINUE ::
        end
    end
    return false
end

return XRedPointConditionRepeatChallengeCoin
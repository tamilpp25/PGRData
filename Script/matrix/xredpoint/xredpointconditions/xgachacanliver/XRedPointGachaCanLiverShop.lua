local XRedPointGachaCanLiverShop = {}


function XRedPointGachaCanLiverShop:Check()
    if not XMVCA.XGachaCanLiver:GetIsOpen() then
        return false
    end

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) then
        return false
    end
    
    -- 是否未首次进入过商店
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.ShopNoEnter) then
        return true
    end

    if XMVCA.XGachaCanLiver:CheckShopGoodsReddot() then
        return true
    end
    
    -- 限时卡池结束后、常驻卡池抽完，且有货币的情况下是否进入过商店
    -- 如果这个红点已经被消掉了，那么则无需再进行其他条件的判断
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.ShopNoEnterAfterTLClsoed) then
        if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsOutTime()
                and XMVCA.XGachaCanLiver:CheckGachaIsSellOutRare(XMVCA.XGachaCanLiver:GetCurActivityResidentGachaId())
                and XMVCA.XGachaCanLiver:CheckHasItemCoin() then
            
            return true
        end
    end

    return false
end

return XRedPointGachaCanLiverShop
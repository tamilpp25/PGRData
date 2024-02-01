local XPurchasePackage = require("XEntity/XPurchase/XPurchasePackage")
local XYKPurchasePackage = XClass(XPurchasePackage, "XYKPurchasePackage")

function XYKPurchasePackage:Ctor(id)
end

-- 获取购买次数限制
function XYKPurchasePackage:GetBuyLimitTime()
    return CS.XGame.ClientConfig:GetInt("PurchaseYKTotalCount") or 1
end

-- 获取当前购买次数
function XYKPurchasePackage:GetCurrentBuyTime()
    local count = CS.XGame.ClientConfig:GetInt("PurchaseYKLimtCount") or 30
    return math.ceil(self.Data.DailyRewardRemainDay / count)
end

function XYKPurchasePackage:CheckCanBuy(count, disCountCouponIndex, notEnoughCb)
    --卖完了，不管
    if self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes then 
        XUiManager.TipText("PurchaseLiSellOut")
        return 0
    end
    --没有上架
    if self.Data.TimeToShelve > 0 and self.Data.TimeToShelve > XTime.GetServerNowTimestamp() then
        XUiManager.TipText("PurchaseBuyNotSet")
        return 0
    end
    --下架了
    if self.Data.TimeToUnShelve > 0 and self.Data.TimeToUnShelve < XTime.GetServerNowTimestamp() then
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end
    --v1.28 采购优化-月卡购买次数不足
    local count = CS.XGame.ClientConfig:GetInt("PurchaseYKLimtCount") or 30
    if math.ceil(self.Data.DailyRewardRemainDay / count) == CS.XGame.ClientConfig:GetInt("PurchaseYKTotalCount") then
        XUiManager.TipText("PurchaseYKIsOnBuyLimt")
        return 0
    end
    --钱不够
    if self.Data.ConsumeCount > 0 and self.Data.ConsumeCount > XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.HongKa) then
        if XUiHelper.CanBuyInOtherPlatformHongKa(self.Data.ConsumeCount) then
            return 2
        end
        XUiHelper.OpenPurchaseBuyHongKaCountTips()
        if notEnoughCb then
            local payCount = self.Data.ConsumeCount - XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.HongKa)
            notEnoughCb(XPurchaseConfigs.TabsConfig.Pay, payCount)
            return 3
        end
        return 0
    end
    return 1
end

return XYKPurchasePackage
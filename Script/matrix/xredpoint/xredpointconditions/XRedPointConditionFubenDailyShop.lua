local XRedPointConditionFubenDailyShop = {}
local Events = nil

function XRedPointConditionFubenDailyShop.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_DAILY_SHOP_CHECK_NEW),
    }
    return Events
end

function XRedPointConditionFubenDailyShop.Check(shopItemList)
    return XShopManager.CheckDailyShopHasNewSuit(shopItemList)
end

return XRedPointConditionFubenDailyShop
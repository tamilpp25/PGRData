local XRedPointConditionConsumeActivityBuyGoods = {}
local Events = nil

function XRedPointConditionConsumeActivityBuyGoods.GetSubEvents()
    ---@type ConsumeDrawActivityEntity
    local consumeDrawActivity = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawActivity()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. consumeDrawActivity:GetShopCoinItemId()),
    }
    return Events
end

function XRedPointConditionConsumeActivityBuyGoods.Check()
    return XDataCenter.AccumulatedConsumeManager.CheckCanBuyGoods()
end

return XRedPointConditionConsumeActivityBuyGoods
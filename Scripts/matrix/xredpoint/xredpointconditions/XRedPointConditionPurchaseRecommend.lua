local XRedPointConditionPurchaseRecommend = {}
local Events = nil

function XRedPointConditionPurchaseRecommend.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_PURCHASE_RECOMMEND_RED),
    }
    return Events
end

function XRedPointConditionPurchaseRecommend.Check()
    return XDataCenter.PurchaseManager.GetRecommendManager():GetIsShowRedPoint()
end

return XRedPointConditionPurchaseRecommend
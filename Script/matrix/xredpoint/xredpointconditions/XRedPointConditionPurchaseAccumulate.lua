----------------------------------------------------------------
local XRedPointConditionPurchaseAccumulate = {}
local Events = nil

function XRedPointConditionPurchaseAccumulate.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ACCUMULATED_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_ACCUMULATED_REWARD)
    }
    return Events
end

function XRedPointConditionPurchaseAccumulate.Check()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PurchaseAdd) then
        return false
    end

    return XDataCenter.PurchaseManager.AccumulatePayRedPoint()
end

return XRedPointConditionPurchaseAccumulate
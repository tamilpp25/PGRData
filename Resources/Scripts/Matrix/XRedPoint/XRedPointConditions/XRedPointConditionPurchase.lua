----------------------------------------------------------------
local XRedPointConditionPurchase = {}
local SubCondition = nil
function XRedPointConditionPurchase.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_PURCHASE_LB_RED,
        XRedPointConditions.Types.CONDITION_ACCUMULATE_PAY_RED,
    }
    return SubCondition
end

function XRedPointConditionPurchase.Check()
    local f = XRedPointConditionPurchaseLB.Check()
    if f then
        return true
    end
    f = XRedPointConditionPurchaseAccumulate.Check()
    if f then
        return true
    end
    return false
end

return XRedPointConditionPurchase
local XRedPointConditionLuckyTenant2 = {}

function XRedPointConditionLuckyTenant2.Check()
    return XMVCA.XLuckyTenant:IsShowRedDot()
end

return XRedPointConditionLuckyTenant2

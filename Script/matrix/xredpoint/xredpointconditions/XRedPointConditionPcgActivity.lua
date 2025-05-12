local XRedPointConditionPcgActivity = {}

function XRedPointConditionPcgActivity.Check()
    return XMVCA.XPcg:IsShowRed()
end

return XRedPointConditionPcgActivity
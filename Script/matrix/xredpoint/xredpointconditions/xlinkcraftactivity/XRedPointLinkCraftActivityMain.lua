local XRedPointLinkCraftActivityMain = {}

function XRedPointLinkCraftActivityMain.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LINKCRAFT_NEWCHAPTER) or
            XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_LINKCRAFT_EXCHANGEABLE)
end

return XRedPointLinkCraftActivityMain
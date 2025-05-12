local XRedPointMechanismActivityMain = {}

function XRedPointMechanismActivityMain.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MECHANISM_NEWCHAPTER) or
            XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MECHANISM_EXCHANGEABLE)
end

return XRedPointMechanismActivityMain
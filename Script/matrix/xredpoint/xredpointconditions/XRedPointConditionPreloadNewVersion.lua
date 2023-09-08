local XRedPointConditionPreloadNewVersion = {}

function XRedPointConditionPreloadNewVersion.Check()
    return XMVCA.XPreload:CheckHasNewPreload()
end

return XRedPointConditionPreloadNewVersion
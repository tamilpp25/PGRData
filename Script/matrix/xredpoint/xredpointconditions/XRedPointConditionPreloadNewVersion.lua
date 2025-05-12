local XRedPointConditionPreloadNewVersion = {}

local Events = nil
function XRedPointConditionPreloadNewVersion.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XAgencyEventId.EVENT_PRELOAD_RED_POINT_UPDATE),
    }
    return Events
end

function XRedPointConditionPreloadNewVersion.Check()
    return XMVCA.XPreload:CheckHasNewPreload()
end

return XRedPointConditionPreloadNewVersion
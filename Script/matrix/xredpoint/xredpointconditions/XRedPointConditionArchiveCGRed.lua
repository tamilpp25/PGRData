local XRedPointConditionArchiveCGRed = {}
local Events = nil

function XRedPointConditionArchiveCGRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_CG),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_CG),
    }
    return Events
end

function XRedPointConditionArchiveCGRed.Check(id)
    return XMVCA.XArchive.CGArchiveCom:CheckCGRedPoint(id)
end

return XRedPointConditionArchiveCGRed
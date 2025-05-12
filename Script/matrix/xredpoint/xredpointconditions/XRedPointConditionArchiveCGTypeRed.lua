local XRedPointConditionArchiveCGTypeRed = {}
local Events = nil

function XRedPointConditionArchiveCGTypeRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_CG),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_CG),
    }
    return Events
end

function XRedPointConditionArchiveCGTypeRed.Check(groupId)
    return XMVCA.XArchive.CGArchiveCom:CheckCGRedPointByGroup(groupId)
end

return XRedPointConditionArchiveCGTypeRed
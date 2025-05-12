local XRedPointConditionArchivePVTypeRed = {}
local Events = nil

function XRedPointConditionArchivePVTypeRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_PV),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_PV),
    }
    return Events
end

function XRedPointConditionArchivePVTypeRed.Check(groupId)
    return XMVCA.XArchive:CheckPVRedPointByGroup(groupId)
end

return XRedPointConditionArchivePVTypeRed
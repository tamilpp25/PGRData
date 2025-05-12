local XRedPointConditionArchivePVRed = {}
local Events = nil

function XRedPointConditionArchivePVRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_PV),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_PV),
    }
    return Events
end

function XRedPointConditionArchivePVRed.Check(id)
    return XMVCA.XArchive:CheckPVRedPoint(id)
end

return XRedPointConditionArchivePVRed
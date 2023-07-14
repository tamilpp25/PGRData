local XRedPointConditionArchivePVAll = {}
local Events = nil

function XRedPointConditionArchivePVAll.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_PV),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_PV),
    }
    return Events
end

function XRedPointConditionArchivePVAll.Check()
    return XDataCenter.ArchiveManager.CheckPVRedPointByGroup() and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive)
end

return XRedPointConditionArchivePVAll
local XRedPointConditionArchiveCGAll = {}
local Events = nil

function XRedPointConditionArchiveCGAll.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_MARK_CG),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_CG),
    }
    return Events
end

function XRedPointConditionArchiveCGAll.Check()
    return XDataCenter.ArchiveManager.CheckCGRedPointByGroup() and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive)
end

return XRedPointConditionArchiveCGAll
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
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) and XMVCA.XArchive.CGArchiveCom:CheckCGRedPointByGroup() 
end

return XRedPointConditionArchiveCGAll
--
-- Author: wujie
-- Note: 图鉴意识红点

local XRedPointConditionArchiveAwareness = {}
local Events = nil

function XRedPointConditionArchiveAwareness.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SUIT),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING),
    }
    return Events
end

function XRedPointConditionArchiveAwareness.Check()
    return (XMVCA.XArchive:IsHaveNewAwarenessSuit() or XMVCA.XArchive:IsHaveNewAwarenessSetting())
        and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive)
end

return XRedPointConditionArchiveAwareness
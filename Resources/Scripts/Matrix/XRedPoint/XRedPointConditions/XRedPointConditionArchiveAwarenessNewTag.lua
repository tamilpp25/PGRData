-- Author: wujie
-- Note: 图鉴武器新得时的红点
local XRedPointConditionArchiveAwarenessNewTag = {}
local Events = nil

function XRedPointConditionArchiveAwarenessNewTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SUIT),
    }
    return Events
end

function XRedPointConditionArchiveAwarenessNewTag.Check()
    return true
end

return XRedPointConditionArchiveAwarenessNewTag
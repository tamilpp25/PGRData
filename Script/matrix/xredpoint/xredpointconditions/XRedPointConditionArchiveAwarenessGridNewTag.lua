-- Author: wujie
-- Note: 图鉴武器新得时的红点
local XRedPointConditionArchiveAwarenessGridNewTag = {}
local Events = nil

function XRedPointConditionArchiveAwarenessGridNewTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT),
    }
    return Events
end

function XRedPointConditionArchiveAwarenessGridNewTag.Check(suitId)
    return XMVCA.XArchive:IsNewAwarenessSuit(suitId)
end

return XRedPointConditionArchiveAwarenessGridNewTag
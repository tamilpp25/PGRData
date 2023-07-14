-- Author: wujie
-- Note: 图鉴武器设定新得时的红点

local XRedPointConditionArchiveAwarenessSettingUnlock = {}
local Events = nil

function XRedPointConditionArchiveAwarenessSettingUnlock.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING),
    }
    return Events
end

function XRedPointConditionArchiveAwarenessSettingUnlock.Check(suitId)
    return XDataCenter.ArchiveManager.IsNewAwarenessSetting(suitId)
end

return XRedPointConditionArchiveAwarenessSettingUnlock
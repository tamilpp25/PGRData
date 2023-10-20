local XRedPointConditionArchiveMonsterAll = {}
local Events = nil

function XRedPointConditionArchiveMonsterAll.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING),
    }
    return Events
end

function XRedPointConditionArchiveMonsterAll.Check()
    return XMVCA.XArchive:IsMonsterHaveRedPointByAll() and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive)
end

return XRedPointConditionArchiveMonsterAll
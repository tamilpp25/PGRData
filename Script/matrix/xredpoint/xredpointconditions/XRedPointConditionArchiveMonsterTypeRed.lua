local XRedPointConditionArchiveMonsterTypeRed = {}
local Events = nil

function XRedPointConditionArchiveMonsterTypeRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING),
    }
    return Events
end

function XRedPointConditionArchiveMonsterTypeRed.Check(type)
    return XMVCA.XArchive:IsMonsterHaveRedPointByType(type) and
    not XMVCA.XArchive:IsMonsterHaveNewTagByType(type)
end

return XRedPointConditionArchiveMonsterTypeRed
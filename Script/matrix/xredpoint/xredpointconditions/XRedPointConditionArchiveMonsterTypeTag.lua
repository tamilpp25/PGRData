local XRedPointConditionArchiveMonsterTypeTag = {}
local Events = nil

function XRedPointConditionArchiveMonsterTypeTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER),
    }
    return Events
end

function XRedPointConditionArchiveMonsterTypeTag.Check(type)
    return XMVCA.XArchive:IsMonsterHaveNewTagByType(type)
end

return XRedPointConditionArchiveMonsterTypeTag
local XRedPointConditionArchiveMonsterTag = {}
local Events = nil

function XRedPointConditionArchiveMonsterTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER),
    }
    return Events
end

function XRedPointConditionArchiveMonsterTag.Check(monsterId)
    return XMVCA.XArchive:IsMonsterHaveNewTagById(monsterId)
end

return XRedPointConditionArchiveMonsterTag
local XRedPointConditionArchiveMonsterInfo = {}
local Events = nil

function XRedPointConditionArchiveMonsterInfo.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO),
    }
    return Events
end

function XRedPointConditionArchiveMonsterInfo.Check(monsterId)
    return XDataCenter.ArchiveManager.IsHaveNewMonsterInfoByNpcId(monsterId)
end

return XRedPointConditionArchiveMonsterInfo
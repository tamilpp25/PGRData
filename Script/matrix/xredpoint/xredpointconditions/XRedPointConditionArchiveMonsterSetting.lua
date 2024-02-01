local XRedPointConditionArchiveMonsterSetting = {}
local Events = nil

function XRedPointConditionArchiveMonsterSetting.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING),
    }
    return Events
end

function XRedPointConditionArchiveMonsterSetting.Check(monsterId)
    return XMVCA.XArchive:IsHaveNewMonsterSettingByNpcId(monsterId)
end

return XRedPointConditionArchiveMonsterSetting
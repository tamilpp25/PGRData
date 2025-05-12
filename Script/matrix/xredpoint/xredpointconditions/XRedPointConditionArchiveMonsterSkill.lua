local XRedPointConditionArchiveMonsterSkill = {}
local Events = nil

function XRedPointConditionArchiveMonsterSkill.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL),
    }
    return Events
end

function XRedPointConditionArchiveMonsterSkill.Check(monsterId)
    return XMVCA.XArchive:IsHaveNewMonsterSkillByNpcId(monsterId)
end

return XRedPointConditionArchiveMonsterSkill
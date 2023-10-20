
----------------------------------------------------------------
--新的角色跃升开启
local XRedPointConditionCharacterNewEnhanceSkillTips = {}
local Events = nil

function XRedPointConditionCharacterNewEnhanceSkillTips.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_SYN),
    }
    return Events
end

function XRedPointConditionCharacterNewEnhanceSkillTips.Check(characterId)
    if not characterId then
        return false
    end

    return XMVCA.XCharacter:CheckIsShowNewEnhanceTips(characterId)
end

return XRedPointConditionCharacterNewEnhanceSkillTips
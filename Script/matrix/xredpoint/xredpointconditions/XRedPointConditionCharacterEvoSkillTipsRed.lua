
----------------------------------------------------------------
--角色技能红点检测
local XRedPointConditionCharacterEvoSkillTipsRed = {}

function XRedPointConditionCharacterEvoSkillTipsRed.Check(characterId)
    if not characterId then
        return false
    end

    return XMVCA.XCharacter:CheckCharEvoSkillTipsRed(characterId)
end

return XRedPointConditionCharacterEvoSkillTipsRed
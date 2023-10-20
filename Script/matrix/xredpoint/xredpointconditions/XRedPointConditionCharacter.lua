
----------------------------------------------------------------
--角色入口红点检测
local XRedPointConditionCharacter = {}
local SubCondition = nil
function XRedPointConditionCharacter.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_CHARACTER_UNLOCK,
        XRedPointConditions.Types.CONDITION_CHARACTER_GRADE ,
        XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY,
        XRedPointConditions.Types.CONDITION_EXHIBITION_NEW,
        XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS,
    }
    return SubCondition
end

function XRedPointConditionCharacter.Check(characterId)
    if not characterId then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CHARACTER_UNLOCK, characterId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CHARACTER_GRADE, characterId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY, characterId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_EXHIBITION_NEW, characterId) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS, characterId) then
        return true
    end

    return false
end

return XRedPointConditionCharacter

----------------------------------------------------------------
--角色技能红点检测
local XRedPointConditionCharacterSkill = {}
local Events = nil
function XRedPointConditionCharacterSkill.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_LEVEL_UP),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_SKILL_UP),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_QUALITY_PROMOTE),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_SKILL_UNLOCK),
    }
    return Events
end

function XRedPointConditionCharacterSkill.Check(characterId)

    if not characterId then
        return false
    end

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterSkill) then
        return false
    end

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)

    return ag:CanPromoteSkill(characterId) or ag:CheckCharacterEnhanceSkillShowRed(characterId)
end

return XRedPointConditionCharacterSkill
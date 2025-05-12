
----------------------------------------------------------------
--角色升品红点检测
local XRedPointConditionCharacterQuality = {}
local Events = nil
function XRedPointConditionCharacterQuality.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_QUALITY_STAR_PROMOTE),
        XRedPointEventElement.New(XEventId.EVENT_CHARACTER_QUALITY_PROMOTE),
    }
    return Events
end

function XRedPointConditionCharacterQuality.Check(characterId)

    if not characterId then
        return false
    end

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.CharacterQuality) then
        return false
    end

    local canPromote = ag:CanPromoteQuality(characterId)
    return canPromote
end

return XRedPointConditionCharacterQuality
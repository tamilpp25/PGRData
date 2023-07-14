
----------------------------------------------------------------
--角色解锁红点检测
local XRedPointConditionCharacterUnlock = {}

function XRedPointConditionCharacterUnlock.Check(characterId)
    if not characterId then
        return false
    end

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)

    local canUnlock = ag:CanCharacterUnlock(characterId)
    return canUnlock
end

return XRedPointConditionCharacterUnlock
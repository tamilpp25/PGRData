
----------------------------------------------------------------
--角色类型按钮红点检测
local XRedPointConditionCharacterType = {}
local SubCondition = nil
function XRedPointConditionCharacterType.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_CHARACTER
    }
    return SubCondition
end

function XRedPointConditionCharacterType.Check(type)
    local characterList = XMVCA.XCharacter:GetCharacterList()
    if not characterList then
        return false
    end

    local count = #characterList
    local isEnough = false

    for i = 1, count do
        local character = characterList[i]
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CHARACTER, character.Id) then
            if type == XEnumConst.CHARACTER.CharacterType.Normal and (not XMVCA.XCharacter:GetIsIsomer(character.Id)) then
                isEnough = true
                break
            elseif type == XEnumConst.CHARACTER.CharacterType.Isomer and XMVCA.XCharacter:GetIsIsomer(character.Id) then
                isEnough = true
                break
            end
        end
    end
    return isEnough
end

return XRedPointConditionCharacterType
local XRedPointConditionMaverickCharacterMain = {}
local SubCondition
function XRedPointConditionMaverickCharacterMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER,
    }
    return SubCondition
end

function XRedPointConditionMaverickCharacterMain.Check()
    local memberIds = XDataCenter.MaverickManager.GetMemberIds()
    for _, memberId in ipairs(memberIds) do
        if XRedPointConditionMaverickCharacter.Check(memberId) then
            return true
        end
    end
    
    return false
end

return XRedPointConditionMaverickCharacterMain
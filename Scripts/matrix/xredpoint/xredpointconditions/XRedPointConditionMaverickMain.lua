local XRedPointConditionMaverickMain = {}
local SubCondition
function XRedPointConditionMaverickMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_MAVERICK_TASK,
        XRedPointConditions.Types.CONDITION_MAVERICK_PATTERN,
        XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER_MAIN,
    }
    return SubCondition
end

function XRedPointConditionMaverickMain.Check()
    if XDataCenter.MaverickManager.IsActivityEnd() then
        return false
    end
    
    if XRedPointConditionMaverickTask.Check() then
        return true
    end

    if XRedPointConditionMaverickCharacterMain.Check() then
        return true
    end
    
    local patternIds = XDataCenter.MaverickManager.GetPatternIds()

    for _, patternId in ipairs(patternIds) do
        if XRedPointConditionMaverickPattern.Check(patternId) then
            return true
        end
    end
    
    return false
end

return XRedPointConditionMaverickMain
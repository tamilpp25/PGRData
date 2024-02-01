local XRedPointConditionTurntableSummary = {}
local SubCondition = nil

function XRedPointConditionTurntableSummary.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_TURNTABLE_TASK,
        XRedPointConditions.Types.CONDITION_TURNTABLE_REWARD,
        XRedPointConditions.Types.CONDITION_TURNTABLE_TIMES,
    }
    return SubCondition
end

function XRedPointConditionTurntableSummary.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TURNTABLE_TASK) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TURNTABLE_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TURNTABLE_TIMES) then
        return true
    end
    return false
end

return XRedPointConditionTurntableSummary
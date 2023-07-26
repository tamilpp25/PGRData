local XRedPointConditionTurntableSummary = {}
local SubCondition = nil

function XRedPointConditionTurntableSummary.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.XRedPointConditionTurntableTask,
        XRedPointConditions.Types.XRedPointConditionTurntableReward,
        XRedPointConditions.Types.XRedPointConditionTurntableTimes,
    }
    return SubCondition
end

function XRedPointConditionTurntableSummary.Check()
    if XRedPointConditionTurntableTask.Check() then
        return true
    end
    if XRedPointConditionTurntableReward.Check() then
        return true
    end
    if XRedPointConditionTurntableTimes.Check() then
        return true
    end
    return false
end

return XRedPointConditionTurntableSummary
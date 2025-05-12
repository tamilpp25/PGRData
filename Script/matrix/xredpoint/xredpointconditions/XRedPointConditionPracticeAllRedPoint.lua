local XRedPointConditionPracticeAllRedPoint = {}
local SubConditions = nil

function XRedPointConditionPracticeAllRedPoint.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_PRACTICE_BOSS_CHALLENGE_NEW,
    }
    return SubConditions
end

function XRedPointConditionPracticeAllRedPoint.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_PRACTICE_BOSS_CHALLENGE_NEW) then
        return true
    end
    return false
end

return XRedPointConditionPracticeAllRedPoint
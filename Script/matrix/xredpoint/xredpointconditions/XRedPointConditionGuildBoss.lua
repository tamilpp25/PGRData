
local XRedPointConditionGuildBoss = {}

local SubCondition = nil
function XRedPointConditionGuildBoss.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
    }
    return SubCondition
end

function XRedPointConditionGuildBoss.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE) then
        return true
    end

    return false
end



return XRedPointConditionGuildBoss
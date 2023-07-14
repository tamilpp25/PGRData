
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
    if XRedPointConditionGuildBossHp.Check() then
        return true
    end

    if XRedPointConditionGuildBossScore.Check() then
        return true
    end

    return false
end



return XRedPointConditionGuildBoss
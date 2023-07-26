local XRedPointConditionMonsterCombatActivity = {}

function XRedPointConditionMonsterCombatActivity.Check()
    if XDataCenter.MonsterCombatManager.CheckActivityRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionMonsterCombatActivity
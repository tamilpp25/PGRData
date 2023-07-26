--SP枢纽作战-任务奖励
local XRedPointConditionPivotCombatTaskRewardRedPoint = {}

function XRedPointConditionPivotCombatTaskRewardRedPoint.Check()
    return XDataCenter.PivotCombatManager.CheckTaskRewardRedPoint()
end

return XRedPointConditionPivotCombatTaskRewardRedPoint
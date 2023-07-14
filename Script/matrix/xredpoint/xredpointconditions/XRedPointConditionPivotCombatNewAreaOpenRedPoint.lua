--SP枢纽作战-新区域开放
local XRedPointConditionPivotCombatNewAreaOpenRedPoint = {}

function XRedPointConditionPivotCombatNewAreaOpenRedPoint.Check(regionId)
    return XDataCenter.PivotCombatManager.CheckNewAreaOpenRedPoint(regionId)
end
return XRedPointConditionPivotCombatNewAreaOpenRedPoint
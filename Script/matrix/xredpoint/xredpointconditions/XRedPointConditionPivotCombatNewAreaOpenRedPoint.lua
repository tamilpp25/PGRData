--SP枢纽作战-新区域开放
local XRedPointConditionPivotCombatNewAreaOpenRedPoint = {}

function XRedPointConditionPivotCombatNewAreaOpenRedPoint.Check(regionId)
    if XTool.IsNumberValid(regionId) then
        return XDataCenter.PivotCombatManager.CheckNewAreaOpenRedPoint(regionId)
    end
    local regionIds = XDataCenter.PivotCombatManager.GetSecondaryRegionIds()
    for _, regionId in ipairs(regionIds) do
        if XDataCenter.PivotCombatManager.CheckNewAreaOpenRedPoint(regionId) then
            return true
        end
    end
    return false
end
return XRedPointConditionPivotCombatNewAreaOpenRedPoint
--SP枢纽作战红点
local XRedPointConditionPivotCombatAllRedPoint = {}
local SubCondition = nil

function XRedPointConditionPivotCombatAllRedPoint.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_NEW_AREA_OPEN_RED_POINT,
        XRedPointConditions.Types.CONDITION_PIVOTCOMBAT_TASK_REWARD_RED_POINT,
    }
    return SubCondition
end

function XRedPointConditionPivotCombatAllRedPoint.Check()
    if XRedPointConditionPivotCombatTaskRewardRedPoint.Check() then
        return true
    end
    local regionIds = XDataCenter.PivotCombatManager.GetSecondaryRegionIds()
    for _, regionId in ipairs(regionIds) do
        if XRedPointConditionPivotCombatNewAreaOpenRedPoint.Check(regionId) then
            return true
        end
    end
    return false
end

return XRedPointConditionPivotCombatAllRedPoint
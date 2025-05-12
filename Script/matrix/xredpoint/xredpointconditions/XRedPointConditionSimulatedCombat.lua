
local XRedPointConditionSimulatedCombat = {}
local SubCondition = nil
function XRedPointConditionSimulatedCombat.GetSubConditions()
    SubCondition =  SubCondition or
        {
            XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_CHALLENGE,
            XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_POINT,
            XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_STAR,
            XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_TASK,
        }
    return SubCondition
end

function XRedPointConditionSimulatedCombat.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenSimulatedCombat) then
        return false
    end
    
    if not XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate() then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_POINT) then
        return true
    end
    
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_TASK) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_CHALLENGE) then
        return true
    end

    return false
end

return XRedPointConditionSimulatedCombat
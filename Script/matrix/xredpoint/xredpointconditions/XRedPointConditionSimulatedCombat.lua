
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

    if XRedPointConditionSimulatedCombatPoint.Check() then
        return true
    end
    
    if XRedPointConditionSimulatedCombatTask.Check() then
        return true
    end

    if XRedPointConditionSimulatedCombatChallenge.Check() then
        return true
    end

    return false
end

return XRedPointConditionSimulatedCombat
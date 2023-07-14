local XRedPointConditionReformAllRedPoint = {}

function XRedPointConditionReformAllRedPoint.Check()
    if not XDataCenter.ReformActivityManager.GetIsOpen() then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Reform) then
        return false
    end
    if XRedPointConditionReformTaskGetReward.Check() then
        return true
    end
    if XRedPointConditionReformBaseStageOpen.Check() then
        return true
    end
    if XRedPointConditionReformEvolvableStageUnlock.Check() then
        return true
    end
    return false
end

return XRedPointConditionReformAllRedPoint
local XRedPointConditionReformAllRedPoint = {}

function XRedPointConditionReformAllRedPoint.Check()
    if not XMVCA.XReform:GetIsOpen() then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Reform) then
        return false
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_REFORM_TASK_GET_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_REFORM_BASE_STAGE_OPEN) then
        return true
    end
    return false
end

return XRedPointConditionReformAllRedPoint
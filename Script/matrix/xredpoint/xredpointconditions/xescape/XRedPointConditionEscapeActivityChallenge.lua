local XRedPointConditionEscapeActivityChallenge = {}

function XRedPointConditionEscapeActivityChallenge.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Escape) then
        return false
    end
    if XDataCenter.EscapeManager.CheckIsNeedActivityChallenge() then
        return true
    end
    return false
end

return XRedPointConditionEscapeActivityChallenge

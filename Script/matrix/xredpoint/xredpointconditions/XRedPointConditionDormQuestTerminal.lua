local XRedPointConditionDormQuestTerminal = {}

function XRedPointConditionDormQuestTerminal.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DormQuest) then
        return false
    end
    return XDataCenter.DormQuestManager.CheckDormEntrustRedPoint()
end

return XRedPointConditionDormQuestTerminal
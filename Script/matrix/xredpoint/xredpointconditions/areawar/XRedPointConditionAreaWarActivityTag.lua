local XRedPointConditionAreaWarActivityTag = {}

function XRedPointConditionAreaWarActivityTag.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    if XDataCenter.AreaWarManager.IsNewChapterOpen() then
        return true
    end
    return false
end

return XRedPointConditionAreaWarActivityTag
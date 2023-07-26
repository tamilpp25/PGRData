local XRedPointConditionMaverickPattern = {}

function XRedPointConditionMaverickPattern.Check(patternId)
    local isEnd, isNotStart = XDataCenter.MaverickManager.IsPatternEnd(patternId)
    if isEnd or isNotStart then
        return false
    end

    return not XDataCenter.MaverickManager.GetPatternEnterFlag(patternId)
end

return XRedPointConditionMaverickPattern
local XRedPointConditionMemorySaveChapterReward = {}

function XRedPointConditionMemorySaveChapterReward.Check(chapterId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MemorySave) then
        return false
    end
    if not XDataCenter.MemorySaveManager.IsOpen() then
        return false
    end
    if not XDataCenter.MemorySaveManager.IsChapterOpen(chapterId) then
        return false
    end
    if XDataCenter.MemorySaveManager.IsTreasureUnlock(chapterId) then
        return true
    end
    return false
end

return XRedPointConditionMemorySaveChapterReward
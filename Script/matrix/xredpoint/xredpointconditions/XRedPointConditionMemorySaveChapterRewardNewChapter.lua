local SubCondition = nil

local XRedPointConditionMemorySaveChapterRewardNewChapter = {} -- 活动入口红点

function XRedPointConditionMemorySaveChapterRewardNewChapter.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD,
    }
    return SubCondition
end

function XRedPointConditionMemorySaveChapterRewardNewChapter.Check(chapterId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MemorySave) then
        return false
    end
    if not XDataCenter.MemorySaveManager.IsOpen() then
        return false
    end
    if not XDataCenter.MemorySaveManager.IsChapterOpen(chapterId) then
        return false
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD, chapterId) then --检查是否有奖励
        return true
    end
    if XDataCenter.MemorySaveManager.IsFirstEntry(chapterId) then -- 首次进入场景
        return true
    end
    return false
end

return XRedPointConditionMemorySaveChapterRewardNewChapter
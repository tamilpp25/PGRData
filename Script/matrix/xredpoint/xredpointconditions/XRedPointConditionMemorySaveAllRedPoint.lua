local Event = nil
local SubCondition = nil

local XRedPointConditionMemorySaveAllRedPoint = {} -- 活动入口红点

function XRedPointConditionMemorySaveAllRedPoint.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD,
        XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD_NEW_CHAPTER,
    }
    return SubCondition
end

function XRedPointConditionMemorySaveAllRedPoint.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MemorySave) then
        return false
    end
    if not XDataCenter.MemorySaveManager.IsOpen() then
        return false
    end
    local chapterIds = XDataCenter.MemorySaveManager.GetActivityChapterIds()
    for _, chapterId in ipairs(chapterIds) do
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD_NEW_CHAPTER, chapterId) then
            return true
        end
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD, chapterId) then
            return true
        end
    end
    return false
end

return XRedPointConditionMemorySaveAllRedPoint
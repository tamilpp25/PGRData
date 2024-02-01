local XRedPointConditionShortStoryChapterReward = {}
local SubCondition = nil

function XRedPointConditionShortStoryChapterReward.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_SHORT_STORY_TREASURE,     -- 故事集章节收集奖励
        XRedPointConditions.Types.CONDITION_ZHOUMU_TASK,              -- 周目挑战任务
    }
    return SubCondition
end

function XRedPointConditionShortStoryChapterReward.Check(chapterId)
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_SHORT_STORY_TREASURE, chapterId) then
        return true
    end
    
    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
    local zhouMuId = XFubenShortStoryChapterConfigs.GetZhouMuId(chapterMainId)
    if zhouMuId == 0 then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ZHOUMU_TASK, zhouMuId) then
        return true
    end

    return false
end
return XRedPointConditionShortStoryChapterReward
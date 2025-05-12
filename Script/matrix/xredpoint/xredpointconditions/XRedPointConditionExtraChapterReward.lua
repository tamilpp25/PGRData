local XRedPointConditionExtraChapterReward = {}
local SubCondition = nil

function XRedPointConditionExtraChapterReward.GetSubConditions()
    SubCondition =  SubCondition or
            {
                XRedPointConditions.Types.CONDITION_EXTRA_TREASURE,     -- 外篇章节收集奖励
                XRedPointConditions.Types.CONDITION_ZHOUMU_TASK,        -- 周目挑战任务
            }
    return SubCondition
end

function XRedPointConditionExtraChapterReward.Check(chapterId)
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_EXTRA_TREASURE, chapterId) then
        return true
    end

    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(chapterId)
    local chapterMainId = (chapterInfo or {}).ChapterMainId or 0
    local zhouMuId = XFubenExtraChapterConfigs.GetZhouMuId(chapterMainId)
    if zhouMuId == 0 then
        return false
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ZHOUMU_TASK, zhouMuId) then
        return true
    end

    return false
end
return XRedPointConditionExtraChapterReward

----------------------------------------------------------------
--章节红点检测
local XRedPointConditionChapterReward = {}

local SubCondition = nil
function XRedPointConditionChapterReward.GetSubConditions()
    SubCondition =  SubCondition or
            {
                XRedPointConditions.Types.CONDITION_MAINLINE_TREASURE,  -- 主线章节收集奖励
                XRedPointConditions.Types.CONDITION_ZHOUMU_TASK,        -- 周目挑战任务
                XRedPointConditions.Types.CONDITION_TRPG_MAIN_VIEW,     -- 周年庆跑团
            }
    return SubCondition
end

function XRedPointConditionChapterReward.Check(chapterId)
    if XRedPointConditionMainLineTreasure.Check(chapterId) then
        return true
    end

    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(chapterId)
    local chapterMainId = chapterInfo and chapterInfo.ChapterMainId or 0
    if XRedPointConditionZhouMuTask.Check(chapterMainId) then
        return true
    end

    if XRedPointConditionTRPGMainView.Check(chapterId) then
        return true
    end

    return false
end

return XRedPointConditionChapterReward
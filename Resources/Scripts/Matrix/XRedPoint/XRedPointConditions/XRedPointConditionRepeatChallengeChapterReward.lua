----------------------------------------------------------------
--节红点检测
local XRedPointConditionRepeatChallengeChapterReward = {}

function XRedPointConditionRepeatChallengeChapterReward.Check(chapterId)
    return XDataCenter.FubenRepeatChallengeManager.CheckChapterRewardCanGetReal(chapterId)
end

return XRedPointConditionRepeatChallengeChapterReward
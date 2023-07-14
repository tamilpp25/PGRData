--角色入口红点检测
local XRedPointConditionRepeatChallengeReward = {}
local SubCondition = nil
function XRedPointConditionRepeatChallengeReward.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_REPEAT_CHALLENGE_CHAPTER_REWARD,
    }
    return SubCondition
end

function XRedPointConditionRepeatChallengeReward.Check()
    local allChapterIds = XDataCenter.FubenRepeatChallengeManager.GetAllChapterIds()

    for _, chapterId in pairs(allChapterIds) do
        if XRedPointConditionRepeatChallengeChapterReward.Check(chapterId) then
            return true
        end
    end

    return false
end

return XRedPointConditionRepeatChallengeReward
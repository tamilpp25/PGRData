local XRedPointConditionTRPGMainView = {}
local SubCondition = nil

function XRedPointConditionTRPGMainView.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_TRPG_MAIN_MODE,
        XRedPointConditions.Types.CONDITION_TRPG_SECOND_MAIN_REWARD,
    }
    return SubCondition
end

function XRedPointConditionTRPGMainView.Check(chapterId)
    if chapterId ~= XDataCenter.FubenMainLineManager.TRPGChapterId then
        return false
    end

    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(chapterId)
    if (not chapterInfo) or (not chapterInfo.Unlock and not chapterInfo.IsOpen) then
        return false
    end

    if XRedPointConditionTRPGMainMode.Check() then
        return true
    end

    if XRedPointTRPGSecondMainReward.Check() then
        return true
    end

    return false
end

return XRedPointConditionTRPGMainView
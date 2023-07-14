local XRedPointConditionPracticeBossChallengeNew = {}

function XRedPointConditionPracticeBossChallengeNew.Check()
    local chapterIdList = XPracticeConfigs.GetPracticeChapterIdListByType(XPracticeConfigs.PracticeType.Boss)
    for _, chapterId in ipairs(chapterIdList) do
        if not XDataCenter.PracticeManager.CheckBossNewChallengerRedPoint(chapterId) and
            XTool.IsNumberValid(XPracticeConfigs.GetPracticeSubTagById(chapterId)) and
            XDataCenter.PracticeManager.CheckUnLockBtnState(chapterId) then
            return true
        end
    end
    return false
end

return XRedPointConditionPracticeBossChallengeNew
----------------------------------------------------------------
--番外剧情：有可挑战关卡

local XRedPointConditionExtra = {}
local Events = nil
function XRedPointConditionExtra.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_STAGE_SYNC),
    }
    return Events
end

function XRedPointConditionExtra.Check(args)
    local isOpen = XActivityBrieIsOpen.Get(args.activityGroupId, args)
    if isOpen then
        local mainChapter = XRedPointConditionExtra.GetMainChapter()
        local chapter = XRedPointConditionExtra.GetChapterByDifficult(mainChapter, args.difficultType)

        return XRedPointConditionExtra.CheckIsNew(chapter)
    else
        return false
    end
end

function XRedPointConditionExtra.GetChapterByDifficult(mainChapter, difficult)
    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfoForOrderId(difficult, mainChapter.OrderId)
    local chapterId = XDataCenter.ExtraChapterManager.GetChapterIdByChapterExtraId(chapterInfo.ChapterMainId, difficult)
    local chapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterId)

    return chapter
end

function XRedPointConditionExtra.CheckIsNew(chapter)
    local stageIds = chapter.StageId
    for i,stageId in ipairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Unlock and not stageInfo.Passed then
            return true
        end
    end
end

function XRedPointConditionExtra.GetMainChapter()
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.Extra)
    local skipId = config.SkipId
    local jumpData = XFunctionConfig.GetSkipList(skipId)
    local chapterId = jumpData.CustomParams[1]
    local mainChapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterId)

    return mainChapter
end

return XRedPointConditionExtra
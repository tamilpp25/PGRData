local Events = nil

local XRedPointConditionKillZoneNewChapter = {}

function XRedPointConditionKillZoneNewChapter.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_NEW_CHAPTER_CHANGE),
    }
    return Events
end

function XRedPointConditionKillZoneNewChapter.Check(chapterId)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    if XDataCenter.KillZoneManager.CheckNewChapterRedPoint(chapterId) then
        return true
    end

    if XDataCenter.KillZoneManager.CheckDailyStageRedPoint(chapterId) then
        return true
    end

    return false
end

return XRedPointConditionKillZoneNewChapter
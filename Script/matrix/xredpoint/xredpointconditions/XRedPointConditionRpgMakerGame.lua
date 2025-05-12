
local XRedPointConditionRpgMakerGame = {}

local Events = nil

function XRedPointConditionRpgMakerGame.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
        }
    return Events
end

function XRedPointConditionRpgMakerGame.Check()
    --if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgMakerActivity) then
    --    return false
    --end
    --if not XDataCenter.RpgMakerGameManager.CheckActivityIsOpen(true) then
    --    return false
    --end
    --local taskRedot = XDataCenter.RpgMakerGameManager.CheckRedPoint()
    --local chapterGroupRedot = XDataCenter.RpgMakerGameManager.CheckAllChapterGroupRedPoint()
    --local chapterRedot = XDataCenter.RpgMakerGameManager.CheckFirstChapterGroupRedPoint()
    --return taskRedot or chapterGroupRedot or chapterRedot
    return false
end

return XRedPointConditionRpgMakerGame
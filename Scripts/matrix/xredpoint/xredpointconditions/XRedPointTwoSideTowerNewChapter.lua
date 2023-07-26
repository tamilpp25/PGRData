
local XRedPointTwoSideTowerNewChapter= {}
local Events = nil

function XRedPointTwoSideTowerNewChapter.GetSubEvents()
    Events = Events or {
    }
    return Events
end

function XRedPointTwoSideTowerNewChapter.Check()
    return XDataCenter.TwoSideTowerManager.CheckChapterOpenRed()
end

return XRedPointTwoSideTowerNewChapter
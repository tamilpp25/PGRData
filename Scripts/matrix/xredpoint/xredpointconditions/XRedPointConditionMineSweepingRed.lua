local XRedPointConditionMineSweepingRed = {}
local Events = nil
function XRedPointConditionMineSweepingRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
        XRedPointEventElement.New(XEventId.EVENT_MINESWEEPING_STAGESTART),
        XRedPointEventElement.New(XEventId.EVENT_MINESWEEPING_GRIDOPEN),
        XRedPointEventElement.New(XEventId.EVENT_MINESWEEPING_STORYPLAY),
    }
    return Events
end

function XRedPointConditionMineSweepingRed.Check()
    return XDataCenter.MineSweepingManager.CheckHaveRed()
end

return XRedPointConditionMineSweepingRed
----------------------------------------------------------------
--预热关拼图小游戏关卡标题红点
local XRedPointConditionDragPuzzleTab = {}
local Events = nil
function XRedPointConditionDragPuzzleTab.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PLAYED_VIDEO),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE),
    }
    return Events
end

function XRedPointConditionDragPuzzleTab.Check(index)
    return XDataCenter.FubenActivityPuzzleManager.CheckTabRedPointByIndex(index)
end

return XRedPointConditionDragPuzzleTab
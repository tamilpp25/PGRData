----------------------------------------------------------------
--预热关拼图小游戏有未观看剧情红点
local XRedPointConditionDragPuzzleVideo = {}
local Events = nil
function XRedPointConditionDragPuzzleVideo.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PLAYED_VIDEO),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD),
    }
    return Events
end

function XRedPointConditionDragPuzzleVideo.Check(puzzleId)
    return XDataCenter.FubenActivityPuzzleManager.CheckVideoRedPoint(puzzleId)
end

return XRedPointConditionDragPuzzleVideo
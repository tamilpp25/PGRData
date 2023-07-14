----------------------------------------------------------------
--预热关拼图小游戏有可领取奖励红点
local XRedPointConditionDragPuzzleAward = {}
local Events = nil
function XRedPointConditionDragPuzzleAward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD),
    }
    return Events
end

function XRedPointConditionDragPuzzleAward.Check()
    return XDataCenter.FubenActivityPuzzleManager.CheckAwardRedPoint()
end

return XRedPointConditionDragPuzzleAward
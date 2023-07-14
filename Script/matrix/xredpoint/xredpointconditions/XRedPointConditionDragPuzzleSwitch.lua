----------------------------------------------------------------
--预热关拼图小游戏碎片转化红点
local XRedPointConditionDragPuzzleSwitch = {}
local Events = nil
function XRedPointConditionDragPuzzleSwitch.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE),
    }
    return Events
end

function XRedPointConditionDragPuzzleSwitch.Check()
    return XDataCenter.FubenActivityPuzzleManager.CheckSwitchRedPoint()
end

return XRedPointConditionDragPuzzleSwitch
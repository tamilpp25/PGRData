----------------------------------------------------------------
--预热关拼图小游戏解密面板特效
local XRedPointConditionDragPuzzleDecryption = {}
local Events = nil
function XRedPointConditionDragPuzzleDecryption.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_DECRYPTION),
        XRedPointEventElement.New(XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE),
    }
    return Events
end

function XRedPointConditionDragPuzzleDecryption.Check(puzzleId)
    return XDataCenter.FubenActivityPuzzleManager.CheckDecryptionRedPoint(puzzleId)
end

return XRedPointConditionDragPuzzleDecryption
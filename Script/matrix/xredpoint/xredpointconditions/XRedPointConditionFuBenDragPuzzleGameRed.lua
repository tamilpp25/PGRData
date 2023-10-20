----------------------------------------------------------------
--预热关拼图小游戏入口
local XRedPointConditionFuBenDragPuzzleGameRed = {}
local SubCondition = nil
function XRedPointConditionFuBenDragPuzzleGameRed.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_SWITCH,
        XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_AWARD,
        XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_VIDEO,
        XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_DECRYPTION,
    }
    return SubCondition
end

function XRedPointConditionFuBenDragPuzzleGameRed.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_SWITCH) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_AWARD) then
        return true
    end

    if XDataCenter.FubenActivityPuzzleManager.CheckAllVideoRedPoint() then
        return true
    end

    if XDataCenter.FubenActivityPuzzleManager.CheckAllPuzzleDecryptionRedPoint() then
        return true
    end

    return false
end

return XRedPointConditionFuBenDragPuzzleGameRed
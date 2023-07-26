local TABLE_PUZZLE_ACTIVITY_PATH = "Share/MiniActivity/PuzzleActivity.tab"
local TABLE_PUZZLE_ACTIVITY_PIECE_PATH = "Share/MiniActivity/PuzzleActivityPiece.tab"

local PuzzleActivityTemplates = nil
local PuzzleActivityPieceTemplates = nil

XPuzzleActivityConfigs = XPuzzleActivityConfigs or {}

XPuzzleActivityConfigs.PuzzleCondition = {
    NotCollected = 0, -- 未翻转
    Activated = 1, -- 已翻转
    Inactivated = 2, -- 未翻转，可翻转
}

XPuzzleActivityConfigs.PuzzleRewardState = {
    Unrewarded = 0,-- 未领取
    Rewarded = 1,   -- 已领取
    CanReward = 2, -- 未领取，可领取
}

XPuzzleActivityConfigs.PieceFlipKey = "PuzzleActivityPieceFlip"
XPuzzleActivityConfigs.RewardKey = "PuzzleActivityReward"

function XPuzzleActivityConfigs.Init()
    PuzzleActivityTemplates = XTableManager.ReadByIntKey(TABLE_PUZZLE_ACTIVITY_PATH, XTable.XTablePuzzleActivity, "Id")
    PuzzleActivityPieceTemplates = XTableManager.ReadByIntKey(TABLE_PUZZLE_ACTIVITY_PIECE_PATH, XTable.XTablePuzzleActivityPiece, "Id")

end

function XPuzzleActivityConfigs.GetTemplates()
    return PuzzleActivityTemplates
end

function XPuzzleActivityConfigs.GetPieceTemplates()
    return PuzzleActivityPieceTemplates
end
local tableInsert = table.insert

XFubenActivityPuzzleConfigs = XFubenActivityPuzzleConfigs or {}

XFubenActivityPuzzleConfigs.PuzzleState = {
    Incomplete = 0,
    Complete = 1,
    PuzzleCompleteButNotDecryption = 2,
}

XFubenActivityPuzzleConfigs.CompleteRewardState = {
    Unrewarded = 0,
    Rewarded = 1,
}

XFubenActivityPuzzleConfigs.PlayVideoState = {
    UnPlay = 0,
    Played = 1,
}

XFubenActivityPuzzleConfigs.HelpHitFaceState = {
    UnHit = 0,
    Hited = 1,
}

XFubenActivityPuzzleConfigs.PuzzleType = {
    Define = 1,
    Decryption = 2,
}

XFubenActivityPuzzleConfigs.PLAY_VIDEO_STATE_KEY = "DRAG_PUZZLE_PLAY_VIDEO_STATE_KEY"
XFubenActivityPuzzleConfigs.HELP_HIT_FACE_KEY = "DRAG_PUZZLE_HELP_HIT_FACE_KEY"
XFubenActivityPuzzleConfigs.PASSWORD_HIT_MESSAGE_COUNT = "PASSWORD_HIT_MESSAGE_COUNT"

local DRAG_PUZZLE_ACTIVITY_PATH = "Share/MiniActivity/DragPuzzle/DragPuzzleActivity.tab"
local DRAG_PUZZLE_ACTIVITY_PUZZLE_PATH = "Share/MiniActivity/DragPuzzle/DragPuzzleActivityPuzzle.tab"
local DRAG_PUZZLE_ACTIVITY_PIECE_PATH = "Share/MiniActivity/DragPuzzle/DragPuzzleActivityPiece.tab"
local DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH = "Share/MiniActivity/DragPuzzle/DragPuzzleActivityPassword.tab"

local ActivityTemplates = {}
local PuzzleTemplates = {}
local PuzzleTemplatesWithAct = {}
local PieceTemplates = {}
local PieceTemplatesWithPuzzle = {}
local PuzzleDecryptionPassword = {}

function XFubenActivityPuzzleConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(DRAG_PUZZLE_ACTIVITY_PATH, XTable.XTableDragPuzzleActivity, "Id")

    PuzzleTemplates = XTableManager.ReadByIntKey(DRAG_PUZZLE_ACTIVITY_PUZZLE_PATH, XTable.XTableDragPuzzleActivityPuzzle, "Id")
    for _, puzzleInfo in ipairs(PuzzleTemplates) do
        if not PuzzleTemplatesWithAct[puzzleInfo.ActId] then
            PuzzleTemplatesWithAct[puzzleInfo.ActId] = {}
        end
        tableInsert(PuzzleTemplatesWithAct[puzzleInfo.ActId], puzzleInfo)
    end

    PieceTemplates = XTableManager.ReadByIntKey(DRAG_PUZZLE_ACTIVITY_PIECE_PATH, XTable.XTableDragPuzzleActivityPiece, "Id")
    for _, pieceInfo in ipairs(PieceTemplates) do
        if not PieceTemplatesWithPuzzle[pieceInfo.PuzzleId] then
            PieceTemplatesWithPuzzle[pieceInfo.PuzzleId] = {}
        end
        tableInsert(PieceTemplatesWithPuzzle[pieceInfo.PuzzleId], pieceInfo)
    end

    local puzzlePasswordTemplates = XTableManager.ReadByIntKey(DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH, XTable.XTableDragPuzzleActivityPassword, "Id")
    PuzzleDecryptionPassword = {}
    for _, puzzlePasswordTemplate in ipairs(puzzlePasswordTemplates) do
        PuzzleDecryptionPassword[puzzlePasswordTemplate.PuzzleId] = puzzlePasswordTemplate
    end
end

function XFubenActivityPuzzleConfigs.GetActivityTemplates()
    if not ActivityTemplates then
        return nil
    end

    return ActivityTemplates
end

function XFubenActivityPuzzleConfigs.GetActivityTemplateById(actId)
    if not ActivityTemplates then
        return nil
    end

    return ActivityTemplates[actId]
end

function XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(id)
    return PuzzleTemplates[id]
end

function XFubenActivityPuzzleConfigs.GetPuzzleTemplatesByActId(actId)
    if not PuzzleTemplatesWithAct then
        return nil
    end

    return PuzzleTemplatesWithAct[actId]
end

function XFubenActivityPuzzleConfigs.GetPieceTemplatesByPuzzleId(puzzleId)
    if not PieceTemplatesWithPuzzle then
        return nil
    end

    return PieceTemplatesWithPuzzle[puzzleId]
end

function XFubenActivityPuzzleConfigs.GetPieceIconById(pieceId)
    return PieceTemplates[pieceId].FragmentUrl
end

function XFubenActivityPuzzleConfigs.GetPieceCorrectIdxById(pieceId)
    return PieceTemplates[pieceId].CorrectIdx
end

function XFubenActivityPuzzleConfigs.GetPuzzlePasswordHintById(puzzleId)
    if not PuzzleDecryptionPassword[puzzleId] then
        XLog.Error("Can Find Password Info By PieceId:" .. puzzleId .. ",Plase Check " ..DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH)
    end

    return PuzzleDecryptionPassword[puzzleId].PasswordHint
end

function XFubenActivityBossSingleConfigs.GetPuzzlePasswordHintMessage(puzzleId)
    if not PuzzleDecryptionPassword[puzzleId] then
        XLog.Error("Can Find Password Info By PieceId:" .. puzzleId .. ",Plase Check " ..DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH)
    end

    return PuzzleDecryptionPassword[puzzleId].HintMessage
end

function XFubenActivityPuzzleConfigs.GetPuzzlePasswordLengthById(puzzleId)
    if not PuzzleDecryptionPassword[puzzleId] then
        XLog.Error("Can Find Password Info By PieceId:" .. puzzleId .. ",Plase Check " ..DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH)
        return 0
    end

    return #PuzzleDecryptionPassword[puzzleId].Password
end

function XFubenActivityPuzzleConfigs.GetPuzzleDecryptionImgUrl(puzzleId)
    if not PuzzleDecryptionPassword[puzzleId] then
        XLog.Error("Can Find Password Info By PieceId:" .. puzzleId .. ",Plase Check " ..DRAG_PUZZLE_ACTIVITY_PASSWORD_PATH)
    end

    return PuzzleDecryptionPassword[puzzleId].DecryptionImgUrl
end
XMineSweepingConfigs = XMineSweepingConfigs or {}

local TABLE_MINESWEEPING_ACTIVITY = "Share/MiniActivity/MineSweepingGame/MineSweepingActivity.tab"
local TABLE_MINESWEEPING_CHAPTER = "Share/MiniActivity/MineSweepingGame/MineSweepingChapter.tab"
local TABLE_MINESWEEPING_STAGE = "Share/MiniActivity/MineSweepingGame/MineSweepingStage.tab"

local MineSweepingActivityCfgs = {}
local MineSweepingChapterCfgs = {}
local MineSweepingStageCfgs = {}

XMineSweepingConfigs.GridType = {
    Unknown = 0,
    Safe = 1,
    Mine = 2,
    Flag = 3,
}

XMineSweepingConfigs.StageState = {
    Prepare = 1,
    Sweeping = 2,
    Finish = 3,
    Failed = 4,
}

XMineSweepingConfigs.SpecialState = {
    None = 0,
    StageWin = 1,
    StageLose = 2,
    ChapterWin = 3,
}

function XMineSweepingConfigs.Init()
    MineSweepingActivityCfgs = XTableManager.ReadByIntKey(TABLE_MINESWEEPING_ACTIVITY, XTable.XTableMineSweepingActivity, "Id")
    MineSweepingChapterCfgs = XTableManager.ReadByIntKey(TABLE_MINESWEEPING_CHAPTER, XTable.XTableMineSweepingChapter, "Id")
    MineSweepingStageCfgs = XTableManager.ReadByIntKey(TABLE_MINESWEEPING_STAGE, XTable.XTableMineSweepingStage, "Id")
end

function XMineSweepingConfigs.GetMineSweepingActivityCfgs()
    return MineSweepingActivityCfgs
end

function XMineSweepingConfigs.GetMineSweepingChapterCfgs()
    return MineSweepingChapterCfgs
end

function XMineSweepingConfigs.GetMineSweepingStageCfgs()
    return MineSweepingStageCfgs
end

function XMineSweepingConfigs.GetMineSweepingActivityById(id)
    if not MineSweepingActivityCfgs[id] then
        XLog.Error("id is not exist in "..TABLE_MINESWEEPING_ACTIVITY.." id = " .. id)
        return
    end
    return MineSweepingActivityCfgs[id]
end

function XMineSweepingConfigs.GetMineSweepingChapterById(id)
    if not MineSweepingChapterCfgs[id] then
        XLog.Error("id is not exist in "..TABLE_MINESWEEPING_CHAPTER.." id = " .. id)
        return
    end
    return MineSweepingChapterCfgs[id]
end

function XMineSweepingConfigs.GetMineSweepingStageById(id)
    if not MineSweepingStageCfgs[id] then
        XLog.Error("id is not exist in "..TABLE_MINESWEEPING_STAGE.." id = " .. id)
        return
    end
    return MineSweepingStageCfgs[id]
end

function XMineSweepingConfigs.GetGridKeyByPos(x, y)
    local pos_X = x or 0
    local pos_Y = y or 0
    return string.format("%d_%d", pos_X, pos_Y)
end
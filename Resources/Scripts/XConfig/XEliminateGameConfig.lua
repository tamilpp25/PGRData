XEliminateGameConfig = XEliminateGameConfig or {}


local TABLE_ELIMINATEGAME_GAME = "Share/EliminateGame/EliminateGame.tab"
local TABLE_ELIMINATEGAME_GRID = "Share/EliminateGame/EliminateGrid.tab"
local TABLE_ELIMINATEGAME_REWARD = "Share/EliminateGame/EliminateReward.tab"
local TABLE_ELIMINATEGAME_GRID_TYPE = "Share/EliminateGame/EliminateGridType.tab"

local EliminateGameConfig = {}
local EliminateGridConfig = {}
local EliminateRewardConfig = {}
local EliminateGridTypeConfig = {}

function XEliminateGameConfig.Init()
    EliminateGameConfig = XTableManager.ReadByIntKey(TABLE_ELIMINATEGAME_GAME, XTable.XTableEliminateGame, "Id")
    EliminateGridConfig = XTableManager.ReadByIntKey(TABLE_ELIMINATEGAME_GRID, XTable.XTableEliminateGrid, "Id")
    EliminateRewardConfig = XTableManager.ReadByIntKey(TABLE_ELIMINATEGAME_REWARD, XTable.XTableEliminateReward, "Id")
    EliminateGridTypeConfig = XTableManager.ReadByIntKey(TABLE_ELIMINATEGAME_GRID_TYPE, XTable.XTableEliminateGridType, "Id")
end


--获取消除游戏
function XEliminateGameConfig.GetEliminateGame(id)
    if not EliminateGameConfig or not EliminateGameConfig[id] then
        XLog.ErrorTableDataNotFound("XEliminateGameConfig.GetEliminateGame", "Id", TABLE_ELIMINATEGAME_GAME, "id", tostring(id))
        return nil
    end

    return EliminateGameConfig[id]
end


--获取消除游戏格子
function XEliminateGameConfig.GetEliminateGameGrid(id)
    if not EliminateGridConfig or not EliminateGridConfig[id] then
        XLog.ErrorTableDataNotFound("XEliminateGameConfig.GetEliminateGameGrid", "Id", TABLE_ELIMINATEGAME_GRID, "id", tostring(id))
        return nil
    end

    return EliminateGridConfig[id]
end


--获取消除游戏奖励
function XEliminateGameConfig.GetEliminateGameReward(id)
    if not EliminateRewardConfig or not EliminateRewardConfig[id] then
        XLog.ErrorTableDataNotFound("XEliminateGameConfig.GetEliminateGameReward", "Id", TABLE_ELIMINATEGAME_REWARD, "id", tostring(id))
        return nil
    end

    return EliminateRewardConfig[id]
end


--获取格子
function XEliminateGameConfig.GetEliminateGameGridByType(typeId)
    if not EliminateGridTypeConfig then
        XLog.ErrorTableDataNotFound("XEliminateGameConfig.GetEliminateGameGridByType", "Id", TABLE_ELIMINATEGAME_GRID_TYPE, "typeId", tostring(typeId))
        return nil
    end

    for i, v in pairs(EliminateGridTypeConfig) do
        if v.Type == typeId then
            return v
        end
    end

    return nil
end


-- --获取格子
-- function XEliminateGameConfig.GetEliminateGameGridById(id)
--     if not EliminateGridTypeConfig or not EliminateGridTypeConfig[id] then
--         XLog.ErrorTableDataNotFound("XEliminateGameConfig.GetEliminateGameGridById", "Id", TABLE_ELIMINATEGAME_GRID_TYPE, "id", tostring(id))
--         return nil
--     end
--     return EliminateGridTypeConfig[id]
-- end
--获取消除游戏奖励
function XEliminateGameConfig.GetEliminateGameRewardByGameId(id)
    local rewards = {}
    for _, v in pairs(EliminateRewardConfig) do
        if v.GameId == id then
            table.insert(rewards, v)
        end
    end

    return rewards
end
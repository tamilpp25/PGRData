XEliminateGameManagerCreator = function()

    local XEliminateGameManager = {}


    local Proto = {
        RequestEliminateGameData = "EliminateGameDataRequest", --请求数据
        RequestEliminateGameFlip = "EliminateGameFlipRequest", --翻牌
        RequestEliminateGameMove = "EliminateGameMoveRequest", --移动
        RequestEliminateGameReset = "EliminateGameResetRequest", --重置
        RequestEliminateGameGetReward = "EliminateGameGetRewardRequest", --奖励
    }


    XEliminateGameManager.EliminateGameSpecialType = {
        Obstacle = 0, --障碍
        Space = 1001, --空
    }

    XEliminateGameManager.EliminateGameState = {
        Close = 0, --关闭
        Flip = 1, --翻牌
        Move = 2 --移动
    }


    XEliminateGameManager.EliminateGridState = {
        Cover = 0, --盖住
        Normal = 1, --正常
        Reward = 2  --已经消除
    }


    local EliminateGameData = {}

    function XEliminateGameManager.Init()

    end

    --获取
    function XEliminateGameManager.GetEliminateGameData(id)
        return EliminateGameData[id]
    end

    --尝试获取
    function XEliminateGameManager.TryGetEliminateGameData(id, cb)
        if not EliminateGameData or not EliminateGameData[id] then
            XEliminateGameManager.RequestEliminateGameData(id, cb)
        else
            if cb then
                cb()
            end
        end
    end

    --初始化游戏数据
    function XEliminateGameManager.InitEliminateGameData(id, res)
        local data = EliminateGameData[id] or {}
        data.State = res.State
        data.CurGrids = res.CurGrids
        data.RewardIds = res.RewardIds
        data.MoveCost = res.MoveCost
        local gameConfig = XEliminateGameConfig.GetEliminateGame(id)
        if not gameConfig then
            return
        end

        data.Config = gameConfig
        local gridInfo = {}
        local eliminateInfo = {}

        local isEliminateAll = true

        for k, v in pairs(data.CurGrids) do
            local grid = v
            gridInfo[grid.X] = gridInfo[grid.X] or {}
            gridInfo[grid.X][grid.Y] = grid

            local gridCfg = XEliminateGameConfig.GetEliminateGameGrid(grid.Id)
            if grid.State == XEliminateGameManager.EliminateGridState.Reward then
                local count = eliminateInfo[gridCfg.Type] or 0
                eliminateInfo[gridCfg.Type] = count + 1
            end

            if grid.State == XEliminateGameManager.EliminateGridState.Normal and gridCfg.Type ~= XEliminateGameManager.EliminateGameSpecialType.Space and gridCfg.Type ~= XEliminateGameManager.EliminateGameSpecialType.Obstacle then
                isEliminateAll = false
            end

        end
        data.IsEliminateAll = isEliminateAll
        data.EliminateInfo = eliminateInfo
        data.GridInfo = gridInfo
        data.Rewards = XEliminateGameConfig.GetEliminateGameRewardByGameId(id)

        EliminateGameData[id] = data
    end



    --判断是否领奖
    function XEliminateGameManager.IsRewarded(id, rewardId)
        local gameData = EliminateGameData[id]

        if not gameData then
            return false
        end

        if not gameData.RewardIds then
            return false
        end

        for i, v in ipairs(gameData.RewardIds) do
            if v == rewardId then
                return true
            end
        end

        return false
    end


    --判断是否完成
    function XEliminateGameManager.IsRewardFinish(rewardCfg)
        local gameData = EliminateGameData[rewardCfg.GameId]

        if not gameData then
            return false
        end

        if not gameData.EliminateInfo then
            return false
        end

        local count = gameData.EliminateInfo[rewardCfg.GridType]
        if not count then
            return false
        end

        if count >= rewardCfg.GridCount then
            return true
        end

        return false
    end

    --检测是否有奖励
    function XEliminateGameManager.CheckGameHasReward(gameId)
        if XEliminateGameManager.CheckTimeOut(gameId, true) then
            return
        end

        local gameData = EliminateGameData[gameId]
        if not gameData then
            return
        end

        local rewardList = gameData.Rewards
        for _, v in ipairs(rewardList) do
            local isRewarded = XEliminateGameManager.IsRewarded(v.GameId, v.Id)
            local isFinish = XEliminateGameManager.IsRewardFinish(v)
            if not isRewarded and isFinish then
                return true
            end
        end

        return false
    end

    --检测过期
    function XEliminateGameManager.CheckTimeOut(id, isShowTip)
        if id <= 0 then
            return true
        end

        local curTime = XTime.GetServerNowTimestamp()
        local config = XEliminateGameConfig.GetEliminateGame(id)
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(config.TimeId)
        if curTime < startTime then
            if isShowTip then
                XUiManager.TipMsg(CS.XTextManager.GetText("EliminateNotOpen"))
            end
            return true
        end

        if curTime > endTime then
            if isShowTip then
                XUiManager.TipMsg(CS.XTextManager.GetText("EliminateTimeOut"))
            end
            return true
        end

        return false
    end


    function XEliminateGameManager.CheckCanFlipGrid(gameId)
        if XEliminateGameManager.CheckTimeOut(gameId, true) then
            return
        end

        local gameData = EliminateGameData[gameId]
        if not gameData then
            return
        end

        local flipCostItem = gameData.Config.FlipItemId
        local count = XDataCenter.ItemManager.GetCount(flipCostItem)
        local name = XDataCenter.ItemManager.GetItemName(flipCostItem)
        if count <= 0 or count < gameData.Config.FlipItemCount then
            XUiManager.TipMsg(string.format(CS.XTextManager.GetText("EliminateFlipItemLack"), gameData.Config.FlipItemCount, name))
            return false
        end

        return true
    end


    function XEliminateGameManager.CheckCanExchangeGrid(gameId, isTip)
        if XEliminateGameManager.CheckTimeOut(gameId, true) then
            return
        end

        local gameData = EliminateGameData[gameId]
        if not gameData then
            return
        end

        local costItem = gameData.Config.MoveItemId
        local count = XDataCenter.ItemManager.GetCount(costItem)
        local name = XDataCenter.ItemManager.GetItemName(costItem)
        if count <= 0 or count < gameData.Config.MoveItemCount then
            if isTip then
                XUiManager.TipMsg(string.format(CS.XTextManager.GetText("EliminateExchangeItemLack"), gameData.Config.MoveItemCount, name))
            end
            return false
        end

        return true
    end



    --翻牌处理
    function XEliminateGameManager.OnFlip(gameId, x, y, result)
        local gameData = EliminateGameData[gameId]
        if not gameData then
            return
        end

        if result.State and gameData.State ~= result.State then
            XUiManager.TipText("EliminateFlipEnd", XUiManager.UiTipType.Tip)
            gameData.State = result.State
        end

        local eliminateInfo = {}
        for k, v in pairs(gameData.CurGrids) do
            --被翻开
            if v.X == x and v.Y == y then
                v.State = XEliminateGameManager.EliminateGridState.Normal
            end

            --检测消除
            if result.EliminateGrids then
                for _, var in ipairs(result.EliminateGrids) do
                    if v.X == var.X and v.Y == var.Y then
                        v.State = var.State
                    end
                end
            end

            local grid = v
            local gridCfg = XEliminateGameConfig.GetEliminateGameGrid(grid.Id)
            if grid.State == XEliminateGameManager.EliminateGridState.Reward then
                local count = eliminateInfo[gridCfg.Type] or 0
                eliminateInfo[gridCfg.Type] = count + 1
            end
        end

        gameData.EliminateInfo = eliminateInfo
    end

    --格子交换
    function XEliminateGameManager.OnExchangeGrid(gameId, x, y, dstX, dstY, result)
        local gameData = EliminateGameData[gameId]
        if not gameData then
            return
        end

        gameData.MoveCost = result.MoveCost

        --交换ID
        local lineCount = gameData.Config.LineCount
        local indexA = x + (y - 1) * lineCount
        local indexB = dstX + (dstY - 1) * lineCount

        local gridA, gridB
        for k, v in ipairs(gameData.CurGrids) do
            if v.X == x and v.Y == y then
                gridA = v
            end

            if v.X == dstX and v.Y == dstY then
                gridB = v
            end
        end

        gridA.X = dstX
        gridA.Y = dstY
        gridB.X = x
        gridB.Y = y

        local isEliminateAll = true
        local eliminateInfo = {}
        for k, v in ipairs(gameData.CurGrids) do

            --检测消除
            if result.EliminateGrids then
                for _, var in ipairs(result.EliminateGrids) do
                    if v.X == var.X and v.Y == var.Y then
                        v.State = var.State
                    end
                end
            end


            local grid = v
            local gridCfg = XEliminateGameConfig.GetEliminateGameGrid(grid.Id)
            if grid.State == XEliminateGameManager.EliminateGridState.Reward then
                local count = eliminateInfo[gridCfg.Type] or 0
                eliminateInfo[gridCfg.Type] = count + 1
            end

            if grid.State == XEliminateGameManager.EliminateGridState.Normal and gridCfg.Type ~= XEliminateGameManager.EliminateGameSpecialType.Space and gridCfg.Type ~= XEliminateGameManager.EliminateGameSpecialType.Obstacle then
                isEliminateAll = false
            end
        end

        gameData.EliminateInfo = eliminateInfo
        gameData.IsEliminateAll = isEliminateAll

    end

    -- 保存本地数据
    function XEliminateGameManager.SaveEliminateGamePrefs(value, id)
        if XPlayer.Id and id then
            local key = string.format("EliminateGame_%s_%s", tostring(XPlayer.Id), id)
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XEliminateGameManager.GetEliminateGamePrefs(id)
        if XPlayer.Id and id then
            local key = string.format("EliminateGame_%s_%s", tostring(XPlayer.Id), id)
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local value = CS.UnityEngine.PlayerPrefs.GetInt(key, 0)
                return value
            end
        end

        return 0
    end

    ----------------------------------------------------------------------------------
    --请求游戏数据
    function XEliminateGameManager.RequestEliminateGameData(id, cb)
        XNetwork.Call(Proto.RequestEliminateGameData, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEliminateGameManager.InitEliminateGameData(id, res)

            if cb then
                cb()
            end

        end)
    end


    --请求游戏翻牌
    function XEliminateGameManager.RequestEliminateGameFlip(id, x, y, cb)
        XNetwork.Call(Proto.RequestEliminateGameFlip, { Id = id, X = x, Y = y }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEliminateGameManager.OnFlip(id, x, y, res)

            if cb then
                cb(res.EliminateGrids)
            end

        end)
    end

    --请求交换位置
    function XEliminateGameManager.RequestEliminateGameMove(id, srcX, srcY, desX, desY, cb)
        XNetwork.Call(Proto.RequestEliminateGameMove, { Id = id, SrcX = srcX, SrcY = srcY, DesX = desX, DesY = desY }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEliminateGameManager.OnExchangeGrid(id, srcX, srcY, desX, desY, res)

            if cb then
                cb(res.EliminateGrids)
            end

        end)
    end

    --请求重置
    function XEliminateGameManager.RequestEliminateGameReset(id, cb)
        XNetwork.Call(Proto.RequestEliminateGameReset, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local gameData = EliminateGameData[id]

            if gameData then
                gameData.MoveCost = res.MoveCost
                gameData.CurGrids = res.CurGrids
            end

            if cb then
                cb()
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ELIMINATEGAME_RESET)

        end)
    end


    --请求奖励
    function XEliminateGameManager.RequestEliminateGameGetReward(gameId, id)
        XNetwork.Call(Proto.RequestEliminateGameGetReward, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local gameData = EliminateGameData[gameId]
            if gameData then
                table.insert(gameData.RewardIds, id)
            end

            if res.RewardGoods then
                XUiManager.OpenUiObtain(res.RewardGoods, CS.XTextManager.GetText("Award"))
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ELIMINATEGAME_GET_REWARD)
        end)
    end

    -----------------------------------------------------------------------------------
    return XEliminateGameManager
end
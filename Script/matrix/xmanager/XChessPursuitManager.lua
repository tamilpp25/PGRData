local XChessPursuitMapDb = require("XUi/XUiChessPursuit/XData/XChessPursuitMapDb")
local XChessPursuitMapBoss = require("XUi/XUiChessPursuit/XData/XChessPursuitMapBoss")
local XChessPursuitSyncActionQueue = require("XUi/XUiChessPursuit/XData/XChessPursuitSyncActionQueue")
local XChessPursuitRank = require("XUi/XUiChessPursuit/XData/XChessPursuitRank")
local XChessPursuitRankPlayer = require("XUi/XUiChessPursuit/XData/XChessPursuitRankPlayer")
local XChessPursuitRankGrid = require("XUi/XUiChessPursuit/XData/XChessPursuitRankGrid")
local XChessPursuitSyncAction = require("XUi/XUiChessPursuit/XData/XChessPursuitSyncAction")
local CSXTextManagerGetText = CS.XTextManager.GetText
local tableSort = table.sort

XChessPursuitManagerCreator = function()
    local XChessPursuitManager = {}

    local ChessPursuitRequest = {
        ChessPursuitEnterMapRequest = "ChessPursuitEnterMapRequest", -- 进入图请求
        ChessPursuitSetGridTeamRequest = "ChessPursuitSetGridTeamRequest", -- 布阵请求
        ChessPursuitBuyCardRequest = "ChessPursuitBuyCardRequest", -- 购买卡牌请求
        ChessPursuitEndRoundRequest = "ChessPursuitEndRoundRequest", -- 结束回合请求
        ChessPursuitAutoFightRequest = "ChessPursuitAutoFightRequest", -- 自动战斗请求
        ChessPursuitResetMapRequest = "ChessPursuitResetMapRequest", -- 重置地图
        ChessPursuitAutoClearRequest = "ChessPursuitAutoClearRequest", -- 扫荡
        ChessPursuitEndBattleRequest = "ChessPursuitEndBattleRequest", -- 确认战斗结果
        ChessPursuitGetRankRequest = "ChessPursuitGetRankRequest",  -- 请求排行榜数据
        ChessPursuitGetRankPlayerDetailRequest = "ChessPursuitGetRankPlayerDetailRequest",  --请求排行榜上单个玩家的详细数据
        ChessPursuitChangeTeamRequest = "ChessPursuitChangeTeamRequest",    --战斗前改变队伍
    }

    --面板上显示的位置 = 队伍中实际中的位置
    local TEAM_POS_DIC = {
        [1] = 2,
        [2] = 1,
        [3] = 3,
    }

    local ChessPursuitMapBossList = {}
    local ChessPursuitMapDbList = {}
    local ChessPursuitSyncActionQueue = XChessPursuitSyncActionQueue.New()
    local ChessPursuitTempTeamDic = {}  --缓存地图所有布阵格的队伍数据
    local CurrentMapId
    local CurrentEndTime
    local ChessPursuitRankDataList = {}
    local ChessPursuitMyRank = -1    -- 服务端下发的主角排名，表示有多少人排名在我的前面
    local ChessPursuitAllRank = -1   -- 所有玩家的排名数量
    local ChessPursuitMyScore = 0
    local ChessPursuitRankGridList = {} --排行榜单个玩家详情的布阵格列表
    local ChessPursuitStartStoryId = CS.XGame.ClientConfig:GetString("ChessPursuitStartStoryId")
    local ChessPursuitCoinItemData = {}
    local PlayerTeamTempData   --当前编队中的所有队伍缓存（只在编队界面中确定保存了，才会影响到ChessPursuitTempTeamDic）
    local IsRegisterEditBattleProxy = false
    local ChessPursuitRankDetailBossId = 0

    local mathMax = math.max
    local stringFormat = string.format

    XChessPursuitManager.ChessPursuitSyncActionType = {
        None = 0,
        --触发了卡牌效果
        CardEffect = 1,
        --更新卡牌有效性计数
        KeepCount = 2,
        --开始战斗
        BeginBattle = 3,
        --结束战斗
        EndBattle = 4,
        --确认结束，战斗对Boss造成伤害
        EndBattleHurt = 5,
        --结束回合
        EndRound = 6,
        --处于停顿移动
        StopMove = 7,
        --移动到新位置
        Move = 8,
    }

    local DefaultTeam = {
        CaptainPos = 1,
        FirstFightPos = 1,
        TeamData = { 0, 0, 0 },
    }

    -------本地接口 begin--------
    local function InitPlayerTeamTempData(teamGridIndex)
        if nil == PlayerTeamTempData then
            local mapId = CurrentMapId or -1
            PlayerTeamTempData = XTool.Clone(ChessPursuitTempTeamDic[mapId] or {})
        end

        if (teamGridIndex) and (not PlayerTeamTempData[teamGridIndex]) then
            PlayerTeamTempData[teamGridIndex] = XTool.Clone(DefaultTeam)
        end
    end

    local function GetPlayerTeamTempDataCharacterId(teamGridId, teamDataIndex)
        InitPlayerTeamTempData()
        local characterId = PlayerTeamTempData[teamGridId] and PlayerTeamTempData[teamGridId].TeamData and PlayerTeamTempData[teamGridId].TeamData[teamDataIndex]
        return characterId or 0
    end

    local function GetPlayerTeamTempDataByTeamGridId(teamGridId)
        InitPlayerTeamTempData()
        return PlayerTeamTempData[teamGridId] and PlayerTeamTempData[teamGridId].TeamData
    end

    local function GetPlayerTeamFirstFightPosByTeamGridId(teamGridId)
        InitPlayerTeamTempData()
        return PlayerTeamTempData[teamGridId] and PlayerTeamTempData[teamGridId].FirstFightPos
    end

    local function GetPlayerTeamCaptainPosByTeamGridId(teamGridId)
        InitPlayerTeamTempData()
        return PlayerTeamTempData[teamGridId] and PlayerTeamTempData[teamGridId].CaptainPos
    end

    --进入地图ChessPursuitTempTeamDic[mapId]为空 和 重置前缓存服务端的队伍数据
    local function BeforeResetSaveTeamTemp(mapId)
        local chessPursuitMapDb = ChessPursuitMapDbList[mapId]
        if not chessPursuitMapDb then
            XLog.Error("重置前缓存服务端的队伍数据失败", mapId, ChessPursuitMapDbList)
            return
        end

        local gridTeamDb = chessPursuitMapDb:GetGridTeamDb()
        if not ChessPursuitTempTeamDic[mapId] then
            ChessPursuitTempTeamDic[mapId] = {}
        end

        local teamDataClone
        for teamGridIndex, teamData in ipairs(gridTeamDb) do
            teamDataClone = XTool.Clone(DefaultTeam)
            teamDataClone.TeamData = chessPursuitMapDb:GetTeamCharacterIds(teamGridIndex, true)
            teamDataClone.CaptainPos = teamData.CaptainPos
            teamDataClone.FirstFightPos = teamData.FirstFightPos
            ChessPursuitTempTeamDic[mapId][teamGridIndex] = teamDataClone
        end
    end
    -------本地接口 end--------

    -- 退出追击玩法界面时要清理的数据
    function XChessPursuitManager.Clear()
        ChessPursuitSyncActionQueue = XChessPursuitSyncActionQueue.New()
        CurrentMapId = nil
        CurrentEndTime = nil
        XChessPursuitManager.ClearTempTeam()
    end

    function XChessPursuitManager.InitMapData(res, isReset)
        XChessPursuitManager.Clear(isReset)

        CurrentMapId = res.MapDb.Id
        CurrentEndTime = XChessPursuitConfig.GetActivityEndTime()

        local chessPursuitMapBoss = XChessPursuitMapBoss.New(res.MapBoss)
        local chessPursuitMapDb = XChessPursuitMapDb.New(res.MapDb)

        ChessPursuitMapDbList[chessPursuitMapDb:GetMapId()] = chessPursuitMapDb
        ChessPursuitMapBossList[chessPursuitMapBoss:GetId()] = chessPursuitMapBoss

        ChessPursuitSyncActionQueue = XChessPursuitSyncActionQueue.New()
        ChessPursuitSyncActionQueue:Push(res.Actions)

        XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_MAP_UPDATE)
    end

    function XChessPursuitManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.ChessPursuit,
        require("XUi/XUiChessPursuit/XUi/XUiChessPursuitNewRoomSingle"))
    end

    function XChessPursuitManager.GetChessPursuitMapBoss(bossId)
        return bossId and ChessPursuitMapBossList[bossId]
    end

    function XChessPursuitManager.GetChessPursuitSyncActionQueue()
        return ChessPursuitSyncActionQueue
    end

    function XChessPursuitManager.GetChessPursuitMapDb(mapId)
        if not mapId then
            return
        end
        if not ChessPursuitMapDbList[mapId] then
            ChessPursuitMapDbList[mapId] = XChessPursuitMapDb.New(mapId)
        end
        return ChessPursuitMapDbList[mapId]
    end

    function XChessPursuitManager.RequestChessPursuitEnterMapData(mapId, cb)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitEnterMapRequest, {
            MapId = mapId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                XLog.Error("进入追击地图失败，mapId:，", mapId)
                return
            end

            XChessPursuitManager.InitMapData(res)
            
            if XTool.IsTableEmpty(ChessPursuitTempTeamDic[mapId]) then
                BeforeResetSaveTeamTemp(mapId)
            end

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitSetGridTeamData(mapId, cb)
        local teamSet = {}
        if ChessPursuitTempTeamDic[mapId] then
            local config = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)
            for teamGridId, cubeIndex in ipairs(config.TeamGrid) do
                local curTeam = ChessPursuitTempTeamDic[mapId][teamGridId]
                if not curTeam then
                    return false, CSXTextManagerGetText("ChessPursuitBuZhenEnterFailed")
                elseif not XChessPursuitManager.IsCaptainCharacterIdInTempTeamData(mapId, teamGridId) then
                    return false, CSXTextManagerGetText("ChessPursuitNoCaptain", teamGridId)
                elseif not XChessPursuitManager.IsFirstFightCharacterIdInTempTeamData(mapId, teamGridId) then
                    return false, CSXTextManagerGetText("ChessPursuitNoFirst", teamGridId)
                else
                    local preFight = {}
                    preFight.CardIds = {}
                    preFight.CaptainPos = curTeam.CaptainPos
                    preFight.FirstFightPos = curTeam.FirstFightPos
                    preFight.RobotIds = {}
                    preFight.Id = config.TeamGrid[teamGridId]
                    preFight.HurtBoss = 0
                    for _, v in pairs(curTeam.TeamData or {}) do
                        if not XRobotManager.CheckIsRobotId(v) then
                            table.insert(preFight.CardIds, v)
                            table.insert(preFight.RobotIds, 0)
                        else
                            table.insert(preFight.CardIds, 0)
                            table.insert(preFight.RobotIds, v)
                        end
                    end
                    table.insert(teamSet, preFight)
                end
            end
        else
            return false, CSXTextManagerGetText("ChessPursuitBuZhenEnterFailed")
        end

        XMessagePack.MarkAsTable(teamSet)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitSetGridTeamRequest, {
            TeamSet = teamSet
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
            if chessPursuitMapDb then
                chessPursuitMapDb:SetGridTeamDb(res.TeamSet)
            end

            if cb then
                cb()
            end
        end)

        return true
    end

    function XChessPursuitManager.RequestChessPursuitEndBattleRequest(cb)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitEndBattleRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            ChessPursuitSyncActionQueue:Push(res.Actions)

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitBuyCardData(cardCfgIds, cb)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitBuyCardRequest, {CardCfgIds = cardCfgIds}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.TipText("ChessPursuitShopBuyCompleteTips")

            local chessPursuitMapDb = XChessPursuitManager.GetChessPursuitMapDb(CurrentMapId)
            chessPursuitMapDb:AddBuyedCards(res.CardIds)
            chessPursuitMapDb:AddBuyedCardId(res.CardIds)
            chessPursuitMapDb:SubCoin(res.SubCoin)

            XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_BUY_CARD)

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitEndRoundData(usedToGrid, usedToBoss, cb)
        local params = {
            UsedToGrid = usedToGrid or {},
            UsedToBoss = usedToBoss or {},
        }
        XMessagePack.MarkAsTable(params.UsedToGrid)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitEndRoundRequest, params, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local chessPursuitMapDb = ChessPursuitMapDbList[CurrentMapId]
            chessPursuitMapDb:RemoveCardsByUsedToGrid(res.UsedToGrid)
            chessPursuitMapDb:RemoveCardsByUesdToBoss(res.UesdToBoss)

            chessPursuitMapDb:AddGridCardDb(res.UsedToGrid)
            chessPursuitMapDb:AddBossCardDb(res.UesdToBoss)
            ChessPursuitSyncActionQueue:Push(res.Actions)

            if cb then
                cb(res.BossRandomStep)
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitAutoFightData(cb)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitAutoFightRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            ChessPursuitSyncActionQueue:Push(res.Actions)

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitResetMapData(cb, mapId)
        BeforeResetSaveTeamTemp(mapId)
        
        XNetwork.Call(ChessPursuitRequest.ChessPursuitResetMapRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XChessPursuitManager.InitMapData(res, true)

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitAutoClearData(cb)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitAutoClearRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chessPursuitMapDb = ChessPursuitMapDbList[CurrentMapId]
            chessPursuitMapDb:AddBossBattleCount(res.AddBattleCount)
            chessPursuitMapDb:SubBossHp(res.SubHp)
            ChessPursuitSyncActionQueue:Push(res.Actions)

            if cb then
                cb()
            end
        end)
    end

    function XChessPursuitManager.RequestChessPursuitChangeTeam(gridIndex)
        local teamTeamData = GetPlayerTeamTempDataByTeamGridId(gridIndex)
        local firstFightPos = GetPlayerTeamFirstFightPosByTeamGridId(gridIndex)
        local captainPos = GetPlayerTeamCaptainPosByTeamGridId(gridIndex)
        local cardIds, robotIds = XChessPursuitManager.ClientTeamDataChangeServer(teamTeamData)
        local params = {
            FirstFightPos = firstFightPos,
            CaptainPos = captainPos,
            CardIds = cardIds,
            RobotIds = robotIds
        }
        
        XNetwork.Call(ChessPursuitRequest.ChessPursuitChangeTeamRequest, params, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local chessPursuitMapDb = ChessPursuitMapDbList[CurrentMapId]
            chessPursuitMapDb:ChangeGridTeamDb(res)
            XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_SAVETEAM)
        end)
    end

    function XChessPursuitManager.ClientTeamDataChangeServer(teamData)
        local cardIds = {}
        local robotIds = {}
        for _, v in pairs(teamData or {}) do
            if not XRobotManager.CheckIsRobotId(v) then
                table.insert(cardIds, v)
                table.insert(robotIds, 0)
            else
                table.insert(cardIds, 0)
                table.insert(robotIds, v)
            end
        end
        return cardIds, robotIds
    end

    function XChessPursuitManager.ServerTeamDataChangeClient(cardIds, robotIds, isNotConverRobotId)
        local teamData = {}

        for i, characterId in ipairs(cardIds or {}) do
            -- 0即可能没有上阵或在RobotIds
            if characterId ~= 0 then
                teamData[i] = characterId
            else
                local robotId = robotIds and robotIds[i] or 0
                teamData[i] = isNotConverRobotId and robotId or XRobotManager.GetCharacterId(robotId)
            end
        end

        return teamData
    end

    function XChessPursuitManager.NotifyChessPursuitBossAction(data)
        ChessPursuitSyncActionQueue:Push(data.Actions)
    end

    function XChessPursuitManager.RefreshDataByAction(action)
        local chessPursuitMapDb = ChessPursuitMapDbList[CurrentMapId]
        if not chessPursuitMapDb then
            return
        end

        if action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.CardEffect then
            chessPursuitMapDb:SetBossMoveDirection(action:GetBossMoveDirection())
            chessPursuitMapDb:SetBossPos(action:GetBoosPos())
            chessPursuitMapDb:SetBossHp(action:GetBossHp())
            chessPursuitMapDb:AddBossCardDb(action:GetAddBossCard())
        elseif action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.KeepCount then
            chessPursuitMapDb:RefreshKeepCount(action:GetCardId(), action:GetKeepCount())
            chessPursuitMapDb:SetBossMoveDirection(action:GetBossMoveDirection())
        elseif action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.EndBattle then

        elseif action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.EndBattleHurt then
            local teamGridIndex = XChessPursuitConfig.GetTeamGridIndexByPos(CurrentMapId, action:GetBoosPos())
            chessPursuitMapDb:SetGridTeamDbHurtBoss(teamGridIndex, action:GetHurtBoss())
            chessPursuitMapDb:AddBossBattleCount(1)
            chessPursuitMapDb:SetBossHp(action:GetBossHp())
        elseif action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.Move then
            chessPursuitMapDb:SetBossPos(action:GetBoosPos())
            chessPursuitMapDb:SetBossMoveDirection(action:GetBossMoveDirection())
        elseif action:GetType() == XChessPursuitManager.ChessPursuitSyncActionType.EndRound then
            chessPursuitMapDb:SetCoin(action:GetCoin())
        end
    end

    function XChessPursuitManager.NotifyChessPursuitGroupInfo(data)
        for i,mapDb in ipairs(data.MapDBList) do
            local chessPursuitMapDb = XChessPursuitMapDb.New(mapDb)
            ChessPursuitMapDbList[chessPursuitMapDb:GetMapId()] = chessPursuitMapDb
        end


        for i,mapBoss in ipairs(data.MapBossList) do
            local chessPursuitMapBoss = XChessPursuitMapBoss.New(mapBoss)
            ChessPursuitMapBossList[chessPursuitMapBoss:GetId()] = chessPursuitMapBoss
        end

        XChessPursuitManager.RegisterEditBattleProxy()
        XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_MAP_UPDATE)
    end

    -- 从编队界面保存临时的队伍数据
    function XChessPursuitManager.SaveTempTeamData(mapId)
        InitPlayerTeamTempData()
        if not ChessPursuitTempTeamDic[mapId] then
            ChessPursuitTempTeamDic[mapId] = {}
        end

        local newTeamTemp = {}
        for teamGridIndex, team in pairs(PlayerTeamTempData) do
            newTeamTemp[teamGridIndex] = team
        end
        
        ChessPursuitTempTeamDic[mapId] = newTeamTemp
        XEventManager.DispatchEvent(XEventId.EVENT_CHESSPURSUIT_SAVETEAM)
        XChessPursuitManager.ClearTempTeam()
    end

    function XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        if ChessPursuitTempTeamDic[mapId] then
            return XTool.Clone(ChessPursuitTempTeamDic[mapId][teamGridIndex])
        end
    end

    function XChessPursuitManager.GetCaptainPosInTempTeamData(mapId, teamGridIndex)
        local tempTeamData = XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        return tempTeamData and tempTeamData.CaptainPos or 1
    end

    function XChessPursuitManager.GetFirstFightPosInTempTeamData(mapId, teamGridIndex)
        local tempTeamData = XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        return tempTeamData and tempTeamData.FirstFightPos or 1
    end

    function XChessPursuitManager.GetCharacterIdInTempTeamData(mapId, teamGridIndex, pos)
        local tempTeamData = XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        return tempTeamData and tempTeamData.TeamData[pos]
    end

    function XChessPursuitManager.IsCaptainCharacterIdInTempTeamData(mapId, teamGridIndex)
        local tempTeamData = XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        return tempTeamData and tempTeamData.TeamData and tempTeamData.TeamData[tempTeamData.CaptainPos] and 0 ~= tempTeamData.TeamData[tempTeamData.CaptainPos]
    end

    function XChessPursuitManager.IsFirstFightCharacterIdInTempTeamData(mapId, teamGridIndex)
        local tempTeamData = XChessPursuitManager.GetSaveTempTeamData(mapId, teamGridIndex)
        return tempTeamData and tempTeamData.TeamData and tempTeamData.TeamData[tempTeamData.FirstFightPos] and 0 ~= tempTeamData.TeamData[tempTeamData.FirstFightPos]
    end

    function XChessPursuitManager.TeamPosConvert(index)
        return TEAM_POS_DIC[index]
    end

    --缓存正在编队中的临时队伍
    function XChessPursuitManager.SetPlayerTeamData(curTeam, mapId, teamGridId, isUsePrefab)
        InitPlayerTeamTempData()
        --检查其他位置有没一样的角色；使用队伍预设空掉其他位置一样的角色，否则交换角色位置
        for i, characterId in ipairs(curTeam.TeamData) do
            local isInOtherTeam, teamGridIndex, teamDataIndex = XChessPursuitManager.CheckIsInChessPursuit(mapId, characterId, teamGridId)
            if isInOtherTeam and PlayerTeamTempData[teamGridIndex] and PlayerTeamTempData[teamGridIndex].TeamData then
                local oldCharacterId = isUsePrefab and 0 or GetPlayerTeamTempDataCharacterId(teamGridId, i)
                PlayerTeamTempData[teamGridIndex].TeamData[teamDataIndex] = oldCharacterId
            end
        end

        PlayerTeamTempData[teamGridId] = XTool.Clone(curTeam)
    end

    --快速编队界面，缓存的正在编队中的临时队伍
    function XChessPursuitManager.QuickDeploySetPlayerTeamData(teamDataList)
        PlayerTeamTempData = XTool.Clone(teamDataList)
    end

    function XChessPursuitManager.SetPlayerTeamDataFirstFightPos(firstFightPos, teamGridIndex)
        InitPlayerTeamTempData(teamGridIndex)
        if PlayerTeamTempData[teamGridIndex] then
            PlayerTeamTempData[teamGridIndex].FirstFightPos = firstFightPos
        end
    end

    function XChessPursuitManager.SetPlayerTeamDataCaptainPos(captainPos, teamGridIndex)
        InitPlayerTeamTempData(teamGridIndex)
        if PlayerTeamTempData[teamGridIndex] then
            PlayerTeamTempData[teamGridIndex].CaptainPos = captainPos
        end
    end

    --关闭编队界面时清理
    function XChessPursuitManager.ClearTempTeam()
        PlayerTeamTempData = nil
    end

    --检查角色是否在其他队伍中
    function XChessPursuitManager.CheckIsInChessPursuit(mapId, characterId, currTeamGridId)
        if 0 == characterId then
            return false
        end
        InitPlayerTeamTempData(mapId)

        if XTool.IsTableEmpty(PlayerTeamTempData) then
            return false
        end
        for teamGridIndex, v in pairs(PlayerTeamTempData) do
            if teamGridIndex ~= currTeamGridId then
                for i, cId in ipairs(v.TeamData) do
                    if cId == characterId then
                        return true, teamGridIndex, i
                    end
                end
            end
        end
        return false
    end

    --检查能否互相交换队伍中的角色
    function XChessPursuitManager.CheckIsSwapTeamPos(teamGridIdA, teamDataIndexA, teamGridIdB, teamDataIndexB)
        if teamGridIdA == teamGridIdB then
            return true
        end

        local teamDataA = GetPlayerTeamTempDataByTeamGridId(teamGridIdA)
        if not teamDataA then
            return true
        end

        local teamDataB = GetPlayerTeamTempDataByTeamGridId(teamGridIdB)
        if not teamDataB then
            return true
        end

        local characterIdA = GetPlayerTeamTempDataCharacterId(teamGridIdA, teamDataIndexA)
        characterIdA = XRobotManager.CheckIdToCharacterId(characterIdA)
        if 0 ~= characterIdA then
            for i, characterId in ipairs(teamDataB) do
                if i ~= teamDataIndexB then
                    characterId = XRobotManager.CheckIdToCharacterId(characterId)
                    if characterIdA == characterId then
                        return false
                    end
                end
            end
        end

        local characterIdB = GetPlayerTeamTempDataCharacterId(teamGridIdB, teamDataIndexB)
        characterIdB = XRobotManager.CheckIdToCharacterId(characterIdB)
        if 0 ~= characterIdB then
            for i, characterId in ipairs(teamDataA) do
                if i ~= teamDataIndexA then
                    characterId = XRobotManager.CheckIdToCharacterId(characterId)
                    if characterIdB == characterId then
                        return false
                    end
                end
            end
        end

        return true
    end

    function XChessPursuitManager.GetActivityChapters()
        local chapters = {}
        local config = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()

        if config then
            local tempChapter = {
                Type = XDataCenter.FubenManager.ChapterType.ChessPursuit,
                Id = config.Id,
            }

            chapters = {tempChapter}
        end
        return chapters
    end

    --@region FubenManager的引用函数（战斗）
    
    function XChessPursuitManager.InitStageInfo()
        for i,v in ipairs(XChessPursuitConfig.GetAllChessPursuitBossTemplate()) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.StageId)
            stageInfo.Type = XDataCenter.FubenManager.StageType.ChessPursuit
            stageInfo.ChapterName = v.Name
        end
    end

    function XChessPursuitManager.PushAction()
        local res = XDataCenter.FubenManager.FubenSettleResult
        if not res or not res.Settle then
            return
        end

        if res.Settle.ChessPursuitResult then
            ChessPursuitSyncActionQueue:Push(res.Settle.ChessPursuitResult)
        end
    end
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, XChessPursuitManager.PushAction, XChessPursuitManager)

    function XChessPursuitManager.FinishFight(settle)
        --当期活动已经结束
        local nowTime = XTime.GetServerNowTimestamp()
        if (nowTime and CurrentEndTime and nowTime >= CurrentEndTime) or not settle.ChessPursuitResult[1] then
            XDataCenter.FubenManager.ChallengeLose()
            return
        end
        
        local chessPursuitSyncAction = XChessPursuitSyncAction.New(settle.ChessPursuitResult[1])
        if chessPursuitSyncAction:GetIsForceExit() then
            XDataCenter.FubenManager.ChallengeLose()
        else
            local chessPursuitMapTemplate = XChessPursuitConfig.GetChessPursuitMapTemplate(CurrentMapId)
            local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(CurrentMapId)
            local bossPos = chessPursuitMapDb:GetBossPos()
            local teamGridIndex = XChessPursuitConfig.GetTeamGridIndexByPos(CurrentMapId, bossPos)

            XLuaUiManager.Open("UiChessPursuitFightResult", {
                MapId = CurrentMapId,
                ChessPursuitSyncAction = chessPursuitSyncAction,
                BossId = chessPursuitMapTemplate.BossId,
                TeamGridIndex = teamGridIndex,
            })
        end
    end

    --@endregion

    function XChessPursuitManager.GetCoinCount(chessPursuitMapId)
        local mapId = chessPursuitMapId or CurrentMapId
        if not mapId then
            return 0
        end
        local chessPursuitMapDb = XChessPursuitManager.GetChessPursuitMapDb(mapId)
        return chessPursuitMapDb:GetCoin()
    end

    --@region 排行榜
    local function UpdatePlayerRankList(playerRankList)
        ChessPursuitRankDataList = {}
        for i, v in ipairs(playerRankList) do
            if not ChessPursuitRankDataList[i] then
                ChessPursuitRankDataList[i] = XChessPursuitRankPlayer.New()
            end
            ChessPursuitRankDataList[i]:UpdateData(v)
        end
    end

    function XChessPursuitManager.ChessPursuitGetRankRequest(cb)
        local groupId = XChessPursuitConfig.GetCurrentGroupId()
        XNetwork.Call(ChessPursuitRequest.ChessPursuitGetRankRequest, {GroupId = groupId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdatePlayerRankList(res.PlayerRank)
            ChessPursuitMyRank = res.My --表示有多少人排名在我的前面，不等于我当前排第几名
            ChessPursuitAllRank = res.All
            ChessPursuitMyScore = res.MyScore
            if cb then
                cb(groupId)
            end
        end)
    end

    function XChessPursuitManager.GetRankDataList()
        return ChessPursuitRankDataList
    end

    function XChessPursuitManager.IsHasMyRank()
        if ChessPursuitMyRank <= -1 then
            return false
        end
        return true
    end

    function XChessPursuitManager.GetChessPursuitMyRank()
        local playerId = XPlayer.Id
        local myRank = XChessPursuitManager.GetPursuitRankIndex(playerId)
        return myRank
    end

    function XChessPursuitManager.GetChessPursuitMyRankPercent()
        if 0 == ChessPursuitAllRank or not XChessPursuitManager.IsHasMyRank() then
            return 0
        end
        --无人排在自己的前面返回1%
        if 0 == ChessPursuitMyRank then
            return 1
        end
        return math.floor(ChessPursuitMyRank / ChessPursuitAllRank * 100)
    end

    function XChessPursuitManager.GetChessPursuitAllRank()
        return ChessPursuitAllRank
    end

    function XChessPursuitManager.GetChessPursuitMyScore()
        return mathMax(ChessPursuitMyScore, 0)
    end

    function XChessPursuitManager.GetPursuitRankData(playerId)
        for _, chessPursuitRankPlayer in ipairs(ChessPursuitRankDataList) do
            if chessPursuitRankPlayer:IsCurPlayer(playerId) then
                return chessPursuitRankPlayer
            end
        end
    end

    function XChessPursuitManager.GetPursuitRankIndex(playerId)
        for index, chessPursuitRankPlayer in ipairs(ChessPursuitRankDataList) do
            if chessPursuitRankPlayer:IsCurPlayer(playerId) then
                return index
            end
        end
    end

    local function UpdateChessPursuitRankGridList(chessPursuitRankGridList)
        ChessPursuitRankGridList = {}
        for i, chessPursuitRankGridData in ipairs(chessPursuitRankGridList) do
            if not ChessPursuitRankGridList[i] then
                ChessPursuitRankGridList[i] = XChessPursuitRankGrid.New(chessPursuitRankGridData)
            end
        end
    end

    local function UpdateChessPursuitRankDetailBossId(bossId)
        if not bossId then return end
        ChessPursuitRankDetailBossId = bossId
    end

    function XChessPursuitManager.ChessPursuitGetRankPlayerDetailRequest(playerId, groupId)
        XNetwork.Call(ChessPursuitRequest.ChessPursuitGetRankPlayerDetailRequest, {PlayerId = playerId, GroupId = groupId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateChessPursuitRankGridList(res.Grids)
            UpdateChessPursuitRankDetailBossId(res.BossId)
            XLuaUiManager.Open("UiChessPursuitRankLineup", playerId, ChessPursuitRankGridList)
        end)
    end

    function XChessPursuitManager.GetChessPursuitRankDetailBossHp()
        local chessPursuitMapBoss = XChessPursuitManager.GetChessPursuitMapBoss(ChessPursuitRankDetailBossId)
        return chessPursuitMapBoss and chessPursuitMapBoss:GetInitHp() or 0
    end

    -- gridTeamIndex：第几号布阵格
    function XChessPursuitManager.IsRankCaptain(gridTeamIndex, characterId, playerId)
        local chessPursuitRankPlayer = XChessPursuitManager.GetPursuitRankData(playerId)
        if not chessPursuitRankPlayer then
            return false
        end
        if chessPursuitRankPlayer:IsCaptain(gridTeamIndex, characterId) then
            return true
        end
        return false
    end

    function XChessPursuitManager.GetRankDetailCharacterHeadInfo(index, characterId)
        local chessPursuitRankGrid = ChessPursuitRankGridList[index]
        if chessPursuitRankGrid then
            return chessPursuitRankGrid:GetCharacterHeadInfo(characterId)
        end
        return {}
    end
    --@endregion

    --@region 商店
    function XChessPursuitManager.GetShopCardIdList(chessPursuitMapId)
        local shopId = XChessPursuitConfig.GetChessPursuitMapShopCardId(chessPursuitMapId)
        local shopCardIdList = XChessPursuitConfig.GetShopCardIdList(shopId)
        local chessPursuitMapDb = XChessPursuitManager.GetChessPursuitMapDb(chessPursuitMapId)
        tableSort(shopCardIdList, function(cardIdA, cardIdB)
            local isBuyedCardA = chessPursuitMapDb:IsBuyedCard(cardIdA)
            local isBuyedCardB = chessPursuitMapDb:IsBuyedCard(cardIdB)
            if isBuyedCardA ~= isBuyedCardB then
                return isBuyedCardB
            end

            local cardQualityA = XChessPursuitConfig.GetCardQuality(cardIdA)
            local cardQualityB = XChessPursuitConfig.GetCardQuality(cardIdB)
            if cardQualityA ~= cardQualityB then
                return cardQualityA > cardQualityB
            end

            return cardIdA < cardIdB
        end)
        return shopCardIdList
    end

    function XChessPursuitManager.IsBuyedCard(chessPursuitMapId, cardId)
        local chessPursuitMapDb = XChessPursuitManager.GetChessPursuitMapDb(chessPursuitMapId)
        return chessPursuitMapDb:IsBuyedCard(cardId)
    end
    --@endregion

    function XChessPursuitManager.GetSumCoinCount()
        local groupId = XChessPursuitConfig.GetCurrentGroupId()
        if not groupId then
            return 0
        end

        local sum = 0
        local addCoinFunc = function(mapId)
            local mapDb = XChessPursuitManager.GetChessPursuitMapDb(mapId)
            if mapDb:IsKill() then
                return XChessPursuitConfig.GetChessPursuitMapFinishAddCoin(mapId)
            end
            return 0
        end

        local mapIdList = XChessPursuitConfig.GetMapIdListByGroupId(groupId)
        if XChessPursuitConfig.GetStageTypeByGroupId(groupId) == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE then
            for _, mapId in ipairs(mapIdList) do
                sum = sum + addCoinFunc(mapId)
            end
        else
            if mapIdList[1] then
                local initFunc = XChessPursuitConfig.GetChessPursuitMapInitFuncList(mapIdList[1])
                local mapId
                for _, funcId in ipairs(initFunc) do
                    if funcId > 0 and XChessPursuitConfig.IsMapInitFuncAddCoinType(funcId) then
                        mapId = XChessPursuitConfig.GetMapInitFuncMapId(funcId)
                        sum = sum + addCoinFunc(mapId)
                    end
                end
            end
        end
        return sum
    end

    function XChessPursuitManager.IsCanTakeReward()
        local groupId = XChessPursuitConfig.GetCurrentGroupId()
        local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)

        for _,cfg in ipairs(mapsCfg) do
            if ChessPursuitMapDbList[cfg.Id] then
                if ChessPursuitMapDbList[cfg.Id]:IsCanTakeReward() then
                    return true
                end
            end
        end
    end

    function XChessPursuitManager.CheckIsAutoPlayStory()
        if not XSaveTool.GetData(stringFormat("%d%s%s", XPlayer.Id, "ChessPursuitIsAutoPlayStory", ChessPursuitStartStoryId)) then
            XSaveTool.SaveData(stringFormat("%d%s%s", XPlayer.Id, "ChessPursuitIsAutoPlayStory", ChessPursuitStartStoryId), true)
            XDataCenter.MovieManager.PlayMovie(ChessPursuitStartStoryId, XChessPursuitManager.CheckIsAutoShowHelp)
        else
            XChessPursuitManager.CheckIsAutoShowHelp()
        end
    end

    function XChessPursuitManager.CheckIsAutoShowHelp()
        local config = XHelpCourseConfig.GetHelpCourseTemplateByFunction("ChessPursuit")
        if not config then return end

        local id = config.Id
        if not XSaveTool.GetData(stringFormat("%d%s%s", XPlayer.Id, "ChessPursuitIsAutoShowHelp", id)) then
            XSaveTool.SaveData(stringFormat("%d%s%s", XPlayer.Id, "ChessPursuitIsAutoShowHelp", id), true)
            XChessPursuitManager.OpenHelpTip()
        end
    end

    function XChessPursuitManager.OpenHelpTip()
        local csXChessPursuitCtrlCom = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
        if not csXChessPursuitCtrlCom then
            return
        end
        local chessPursuitDrawCamera = csXChessPursuitCtrlCom:GetChessPursuitDrawCamera()
        local currCameraState = chessPursuitDrawCamera:GetChessPursuitCameraState()
        chessPursuitDrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None)
        XUiManager.ShowHelpTip("ChessPursuit", function()
            chessPursuitDrawCamera:SwitchChessPursuitCameraState(currCameraState)
        end)
    end

    --活动简介界面的可挑战提醒
    function XChessPursuitManager.CheckIsCanFightTips()
        local groupId = XChessPursuitConfig.GetCurrentGroupId()
        local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)

        for _,cfg in ipairs(mapsCfg) do
            if XChessPursuitConfig.CheckChessPursuitMapIsOpen(cfg.Id) then
                local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(cfg.Id)
                if not chessPursuitMapDb:IsKill() then
                    return true
                end
            end
        end
    end

    function XChessPursuitManager.GetBossHurMax(mapId, teamGridIndex)
        local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
        local hurtBoss = chessPursuitMapDb:GetHurtBossByGridId(teamGridIndex)
        if hurtBoss and hurtBoss > 0 then
            local chessPursuitMapTemplate = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)
            local chessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(chessPursuitMapTemplate.BossId)
            local ration = hurtBoss / chessPursuitMapBoss:GetInitHp()
        
            return ration
        else
            return 0
        end
    end
    
    function XChessPursuitManager.OpenCoinTip()
        XLuaUiManager.Open("UiTip", ChessPursuitCoinItemData)
    end

    -- 是否开放斗争期炼狱模式
    function XChessPursuitManager.IsOpenFightHeard()
        local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD)
        return XChessPursuitConfig.CheckChessPursuitMapIsOpen(cfg.Id)
    end

    function XChessPursuitManager.SaveSaoDangIsAlreadyAutoOpen(mapId)
        local key = string.format("ChessPursuitSaoDangIsAlreadyAutoOpen_%s_%s", mapId, XPlayer.Id)
        XSaveTool.SaveData(key, true)
    end

    function XChessPursuitManager.IsSaoDangAlreadyAutoOpen(mapId)
        local key = string.format("ChessPursuitSaoDangIsAlreadyAutoOpen_%s_%s", mapId, XPlayer.Id)
        if XSaveTool.GetData(key) then
            return true
        end
        return false
    end

    function XChessPursuitManager.RemoveSaoDangIsAlreadyAutoOpen(mapId)
        local key = string.format("ChessPursuitSaoDangIsAlreadyAutoOpen_%s_%s", mapId, XPlayer.Id)
        if XSaveTool.GetData(key) then
            XSaveTool.RemoveData(key)
        end
    end

    local function InitChessPursuitCoinItemData()
        local itemId = XChessPursuitConfig.SHOP_COIN_ITEM_ID
        ChessPursuitCoinItemData = {
            TemplateId = itemId,
            IsTempItemData = true,
            Name = XDataCenter.ItemManager.GetItemName(itemId),
            Icon = XDataCenter.ItemManager.GetItemIcon(itemId),
            Description = XDataCenter.ItemManager.GetItemDescription(itemId),
            WorldDesc = XDataCenter.ItemManager.GetItemWorldDesc(itemId)
        }
    end

    local function Init()
        InitChessPursuitCoinItemData()
    end
    Init()

    return XChessPursuitManager
end

XRpc.NotifyChessPursuitBossAction = function(data)
    XDataCenter.ChessPursuitManager.NotifyChessPursuitBossAction(data)
end

XRpc.NotifyChessPursuitGroupInfo = function(data)
    XDataCenter.ChessPursuitManager.NotifyChessPursuitGroupInfo(data)
end
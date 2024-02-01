local XTRPGMaze = require("XEntity/XTRPG/XTRPGMaze")
local XTRPGBaseInfo = require("XEntity/XTRPG/XTRPGBaseInfo")
local XTRPGThirdAreaInfo = require("XEntity/XTRPG/XTRPGThirdAreaInfo")
local XTRPGRole = require("XEntity/XTRPG/XTRPGRole")
local XTRPGClientShopInfo = require("XEntity/XTRPG/XTRPGClientShopInfo")
local XTRPGBossInfo = require("XEntity/XTRPG/XTRPGBossInfo")
local XTRPGExamine = require("XEntity/XTRPG/XTRPGExamine")

XTRPGManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local tonumber = tonumber
    local mathFloor = math.floor
    local mathMax = math.max
    local mathCeil = math.ceil
    local pairs = pairs
    local CSXTextManagerGetText = CS.XTextManager.GetText
    local stringFormat = string.format

    local BaseInfo = XTRPGBaseInfo.New()
    local TargetList = {}           --已完成的目标
    local RewardList = {}           --已领取的奖励id
    local ThirdAreaInfos = {}
    local DEFUALT_thirdAreaId_FOR_STUPID_DESIGN = -1--数据不一致兼容
    local Roles = {}
    local ShopInfos = {}
    local MazeInfos = {}
    local MemoirList = {}
    local ItemList = {}
    local BossInfo = XTRPGBossInfo.New()
    local CurrTargetId = 0
    local CurrTargetLinkId = 0
    local AddItemMaxCountNum = 0
    local CurExmaine = XTRPGExamine.New() --当前检定信息
    local AlreadyOpenMazeList = {}      --已开启的迷宫列表
    local CurrAreaOpenNum = 0
    local OldCurrTargetId = 0
    local NewTargetTime = 0
    local IsCanCheckOpenNewMaze = false
    local IsNormalPage = false      --当前跑团页面模式，false是探索，true是常规主线
    local StagePassDic = {}            --已完成关卡记录

    local BagHideItemIdList = {
        [XDataCenter.ItemManager.ItemId.TRPGTalen] = 1,
        [XDataCenter.ItemManager.ItemId.TRPGMoney] = 1,
        [XDataCenter.ItemManager.ItemId.TRPGEXP] = 1,
        [XDataCenter.ItemManager.ItemId.TRPGEndurance] = 1,
    }

    ---------------------本地接口 begin------------------
    local function UpdateShopInfos(shopInfos)
        if not shopInfos then return end
        for _, v in pairs(shopInfos) do
            if not ShopInfos[v.Id] then
                ShopInfos[v.Id] = XTRPGClientShopInfo.New()
            end
            ShopInfos[v.Id]:UpdateData(v)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_SHOP_INFO_CHANGE)
    end

    local function UpdateShopExtraData(extraDatas)
        if not extraDatas then return end
        for _, v in ipairs(extraDatas) do
            if not ShopInfos[v.Id] then
                ShopInfos[v.Id] = XTRPGClientShopInfo.New()
            end
            ShopInfos[v.Id]:UpdateData(v)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_SHOP_INFO_CHANGE)
    end

    local function AddBuyTimes(shopId, itemId, count)
        if not ShopInfos[shopId] then
            XLog.Error("XTRPGManager AddBuyTimes Error: can not found shop, shopId is " .. shopId)
            return
        end
        ShopInfos[shopId]:AddItemBuyCount(itemId, count)
    end

    local function UpdateCurrTargetLinkId(currTargetLinkId, isNotPlayNewAnima)
        local currTargetLinkIsFinish, targetId = XDataCenter.TRPGManager.GetTargetLinkIsFinish(currTargetLinkId)
        if currTargetLinkIsFinish then
            CurrTargetLinkId, CurrTargetId = XDataCenter.TRPGManager.GetOneCanFindTarget()
        else
            CurrTargetLinkId, CurrTargetId = currTargetLinkId, targetId
        end
        XEventManager.DispatchEvent(XEventId.EVENT_TRPG_UPDATE_TARGET, isNotPlayNewAnima)
    end

    local function UpdateMemoirInfos(memoirList)
        for _, memoirId in pairs(memoirList) do
            MemoirList[memoirId] = 1
        end
    end

    local function UpdateBossInfo(bossInfo)
        if not bossInfo then return end
        BossInfo:UpdateBaseData(bossInfo)
    end

    local function UpdateBossHpInfo(hpInfo)
        if not hpInfo then return end
        BossInfo:UpdateHpData(hpInfo)
        XEventManager.DispatchEvent(XEventId.EVENT_TRPG_BOSS_HP_SYN)
    end

    local function UpdateBossPhasesRewardListInfo(PhasesRewardList)
        if not PhasesRewardList then return end
        BossInfo:UpdatePhasesRewardList(PhasesRewardList)
    end

    local function UpdateWorldBossChallengeCount(count)
        BossInfo:UpdateWorldBossChallengeCount(count)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_WORLDBOSS_SYNCDATA)
    end

    local function UpdateRewardList(rewardList)
        if not rewardList then return end
        for _, rewardId in pairs(rewardList) do
            RewardList[rewardId] = 1
        end
    end

    local function UpdateTargetList(targetList)
        if not targetList then return end
        for _, targetId in pairs(targetList) do
            if not TargetList[targetId] then
                TargetList[targetId] = 1
            end
        end
    end

    local function UpdateAlreadyOpenMaze(mazeId)
        AlreadyOpenMazeList[mazeId] = 1
    end

    local function IsOpenMaze(mazeId)
        return AlreadyOpenMazeList[mazeId]
    end

    local function InitAleardyOpenMazeList()
        local secondAreaIdToMazeIdDic = XTRPGConfigs.GetSecondAreaIdToMazeIdDic()
        local condition, ret
        for secondAreaId, mazeId in pairs(secondAreaIdToMazeIdDic) do
            condition = XTRPGConfigs.GetSecondAreaCondition(secondAreaId)
            ret = XConditionManager.CheckCondition(condition)
            if ret then
                UpdateAlreadyOpenMaze(mazeId)
            end
        end
    end

    local function UpdateOldCurrTargetId()
        OldCurrTargetId = XDataCenter.TRPGManager.GetCurrTargetId()
    end

    local function GetOldCurrTargetId()
        return OldCurrTargetId
    end

    local function SetIsCanCheckOpenNewMaze(isCanCheckOpenNewMaze)
        IsCanCheckOpenNewMaze = isCanCheckOpenNewMaze
    end

    local function SetIsNormalPage(isNormalPage)
        IsNormalPage = isNormalPage
    end

    local function UpdateStagePassDic(stageList)
        for _, stageId in ipairs(stageList or {}) do
            StagePassDic[stageId] = true
        end
    end
    ---------------------本地接口 end------------------
    local XTRPGManager = {}

    -----------------功能入口begin----------------
    function XTRPGManager.GetProgress()
        local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
        local curAreaPercent
        local totalPercent = 0
        for id = 1, areaMaxNum do
            curAreaPercent = XTRPGManager.GetAreaRewardPercent(id)
            curAreaPercent = curAreaPercent / areaMaxNum
            totalPercent = totalPercent + curAreaPercent
        end
        return mathFloor(totalPercent * 100)
    end

    function XTRPGManager.InitCurrAreaOpenNum()
        local currAreaOpenNum = XSaveTool.GetData("TRPGCurrAreaOpenNum_" .. XPlayer.Id)
        if currAreaOpenNum then
            XTRPGManager.SetCurrAreaOpenNum(currAreaOpenNum)
        end
    end

    function XTRPGManager.SetCurrAreaOpenNum(currAreaOpenNum)
        CurrAreaOpenNum = currAreaOpenNum
    end

    function XTRPGManager.UpdateCurrAreaOpenNum()
        local areaOpenNum = XTRPGManager.GetAreaOpenNum()
        XTRPGManager.SetCurrAreaOpenNum(areaOpenNum)
        XSaveTool.SaveData("TRPGCurrAreaOpenNum_" .. XPlayer.Id, areaOpenNum)
    end

    function XTRPGManager.IsActivityShowTag()
        local areaOpenNum = XTRPGManager.GetAreaOpenNum()
        return CurrAreaOpenNum ~= areaOpenNum
    end

    function XTRPGManager.IsTRPGClear()
        local progress = XTRPGManager.GetProgress()
        return progress == 100
    end
    -----------------功能入口end------------------
    -----------------迷宫begin----------------
    local __CurrentMazeId = 0

    local function GetMaze(mazeId)
        return MazeInfos[mazeId]
    end

    local function InitMazes()
        local mazeIds = XTRPGConfigs.GetMazeIds()
        for mazeId in pairs(mazeIds) do
            local maze = GetMaze(mazeId)
            if not maze then
                maze = XTRPGMaze.New(mazeId)
                MazeInfos[mazeId] = maze
            end
        end
    end

    local function UpdateMazeInfo(data)
        if not data then return end
        local mazeId = data.Id
        local maze = GetMaze(mazeId)
        maze:UpdateData(data)
    end

    local function UpdateMazeInfos(mazeInfos)
        if not mazeInfos then return end
        for _, data in pairs(mazeInfos) do
            UpdateMazeInfo(data)
        end
    end

    function XTRPGManager.EnterMaze(mazeId)
        __CurrentMazeId = mazeId

        local maze = GetMaze(mazeId)
        maze:Enter()

        XTRPGManager.UnlockSelectCard()

        XLuaUiManager.Open("UiTRPGMaze", mazeId)
    end

    function XTRPGManager.QuitMaze()
        if __CurrentMazeId == 0 then return end

        __CurrentMazeId = 0

        if XLuaUiManager.IsUiShow("UiTRPGMaze") then
            XLuaUiManager.Close("UiTRPGMaze")
        end
    end

    function XTRPGManager.TipQuitMaze(callBack)
        local title = CSXTextManagerGetText("TRPGMazeLeaveTipTitle")
        local content = CSXTextManagerGetText("TRPGMazeLeaveTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callBack)
    end

    function XTRPGManager.TipCurrentMaze()
        if __CurrentMazeId == 0 then return end

        local mazeId = __CurrentMazeId
        local mazeName = XTRPGConfigs.GetMazeName(mazeId)

        local layerId = XTRPGManager.GetMazeCurrentLayerId(mazeId)
        local layerName = XTRPGConfigs.GetMazeLayerName(layerId)

        local msg = CSXTextManagerGetText("TRPGMazeTipCurrentPos", mazeName, layerName)
        XUiManager.TipMsg(msg)
    end

    local function RestartCurrentMaze()
        if __CurrentMazeId == 0 then return end

        local maze = GetMaze(__CurrentMazeId)
        maze:RestartCurrentLayer()
    end

    local _ToRestartCurrentMaze
    function XTRPGManager.ReqMazeRestart()
        if __CurrentMazeId == 0 then return end

        RestartCurrentMaze()

        if XLuaUiManager.IsUiShow("UiTRPGMaze") then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_MAZE_RESTART)
        else
            _ToRestartCurrentMaze = true
        end
    end

    function XTRPGManager.IsMazeNeedRestart()
        return _ToRestartCurrentMaze or false
    end

    function XTRPGManager.ClearMazeNeedRestart()
        _ToRestartCurrentMaze = nil
    end

    function XTRPGManager.GetMazeCurrentLayerId(mazeId)
        local maze = GetMaze(mazeId)
        return maze:GetCurrentLayerId()
    end

    function XTRPGManager.GetMazeCurrentNodeId(mazeId)
        local maze = GetMaze(mazeId)
        return maze:GetCurrentNodeId()
    end

    function XTRPGManager.GetMazeCurrentStandNodeIndex(mazeId, layerId)
        local maze = GetMaze(mazeId)
        return maze:GetCurrentStandNodeIndex(layerId)
    end

    function XTRPGManager.GetMazeProgress(mazeId)
        local maze = GetMaze(mazeId)
        return maze:GetProgress()
    end

    function XTRPGManager.GetMazeNodeIdList(mazeId, layerId, notSort)
        local maze = GetMaze(mazeId)
        return maze:GetLayerNodeIdList(layerId, notSort)
    end

    function XTRPGManager.GetMazeCardBeginEndPos(mazeId, layerId, nodeId)
        local maze = GetMaze(mazeId)
        return maze:GetLayerCardBeginEndPos(layerId, nodeId)
    end

    function XTRPGManager.GetMazeCardNum(mazeId, layerId, nodeId)
        local maze = GetMaze(mazeId)
        return maze:GetLayerCardNum(layerId, nodeId)
    end

    function XTRPGManager.GetMazeCardId(mazeId, layerId, nodeId, cardIndex)
        local maze = GetMaze(mazeId)
        return maze:GetLayerCardId(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.GetMazeRecordGroupCardCount(mazeId, cardRecordGroupId)
        local maze = GetMaze(mazeId)
        return maze:GetRecordGroupCardCount(cardRecordGroupId)
    end

    function XTRPGManager.IsCurrentLayer(mazeId, layerId)
        local maze = GetMaze(mazeId)
        return layerId and layerId == maze:GetCurrentLayerId()
    end

    function XTRPGManager.IsNodeReachable(mazeId, layerId, nodeId)
        local maze = GetMaze(mazeId)
        return maze:IsNodeReachable(layerId, nodeId)
    end

    function XTRPGManager.IsCardReachable(mazeId, layerId, nodeId, cardIndex)
        local maze = GetMaze(mazeId)
        return maze:IsCardReachable(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.CheckCardCurrentType(layerId, nodeId, cardId, cardType)
        if __CurrentMazeId == 0 then return false end
        local maze = GetMaze(__CurrentMazeId)
        return maze:CheckCardCurrentType(layerId, nodeId, cardId, cardType)
    end

    function XTRPGManager.IsMazeCardFinished(mazeId, layerId, cardId)
        local maze = GetMaze(mazeId)
        if not maze then return false end
        return maze:IsCardFinished(layerId, cardId)
    end

    function XTRPGManager.IsMazeCardDisposeableForeverFinished(mazeId, layerId, cardId)
        local maze = GetMaze(mazeId)
        if not maze then return false end
        return maze:IsCardDisposeableForeverFinished(layerId, cardId)
    end

    function XTRPGManager.GetCardFinishedId(mazeId, layerId, nodeId, cardIndex)
        local maze = GetMaze(mazeId)
        return maze:GetCardFinishedId(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.IsCardAfterCurrentStand(mazeId, layerId, nodeId, cardIndex)
        local maze = GetMaze(mazeId)
        return maze:IsCardAfterCurrentStand(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.IsCardCurrentStand(mazeId, layerId, nodeId, cardIndex)
        local maze = GetMaze(mazeId)
        return maze:IsCardCurrentStand(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.GetMazeCardMoveDelta(cardIndex)
        if __CurrentMazeId == 0 then return end
        local maze = GetMaze(__CurrentMazeId)
        return maze:GetMoveDelta(cardIndex)
    end

    function XTRPGManager.CheckQuickFight(challengeLevel)
        return challengeLevel and XTRPGManager.GetExploreLevel() >= challengeLevel
    end

    --请求进入迷宫
    local EnterMazeCD = 2
    local LastEnterMazeTime = 0
    function XTRPGManager.TRPGEnterMazeRequest(mazeId, cb)
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime < LastEnterMazeTime + EnterMazeCD then
            return
        end
        LastEnterMazeTime = nowTime

        local req = { MazeId = mazeId }
        XNetwork.Call("TRPGEnterMazeRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local currentPos = res.CurrentPos
            UpdateMazeInfo(res.MazeInfo)

            XTRPGManager.EnterMaze(mazeId)

            if cb then cb() end
        end)
    end

    --请求迷宫位置整体移动:数据更新需在界面动画表现执行完毕之后，否则会增加冗余计算量
    local _ToMoveCardIndex, _ToPlayMovieId
    function XTRPGManager.ReqMazeMoveNext(cardIndex, movieId)
        if __CurrentMazeId == 0 then return end

        if XLuaUiManager.IsUiShow("UiTRPGMaze") then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_MAZE_MOVE_NEXT, cardIndex)
        else
            _ToMoveCardIndex = cardIndex
            _ToPlayMovieId = movieId
        end
    end

    function XTRPGManager.GetMazeNeedMoveNextCardIndex()
        return _ToMoveCardIndex, _ToPlayMovieId
    end

    function XTRPGManager.ClearMazeNeedMoveNextCardIndex()
        _ToMoveCardIndex = nil
        _ToPlayMovieId = nil
    end

    function XTRPGManager.MazeMoveNext(cardIndex)
        if __CurrentMazeId == 0 then return end

        local maze = GetMaze(__CurrentMazeId)
        maze:MoveNext(cardIndex)
    end

    function XTRPGManager.MazeMoveTo(layerId, nodeId, cardIndex)
        if __CurrentMazeId == 0 then return end
        local maze = GetMaze(__CurrentMazeId)
        maze:MoveTo(layerId, nodeId, cardIndex)
    end

    function XTRPGManager.SelectCard(cardIndex)
        if __CurrentMazeId == 0 then return end

        local maze = GetMaze(__CurrentMazeId)
        maze:SelectCard(cardIndex)
    end

    local _CurrentSelectCardLock--本次选择结果未处理之前不允许进行下一次选择操作
    function XTRPGManager.LockSelectCard()
        _CurrentSelectCardLock = true
    end

    function XTRPGManager.UnlockSelectCard()
        _CurrentSelectCardLock = nil
    end

    function XTRPGManager.IsSelectCardLock()
        return _CurrentSelectCardLock or false
    end

    --请求选择卡牌
    function XTRPGManager.TRPGMazeSelectCardRequest(cardIndex)

        if __CurrentMazeId == 0 then return end
        if XTRPGManager.IsSelectCardLock() then return end

        local selectPos = {
            LayerId = XTRPGManager.GetMazeCurrentLayerId(__CurrentMazeId),
            NodeId = XTRPGManager.GetMazeCurrentNodeId(__CurrentMazeId),
            Index = cardIndex,
        }
        local req = { SelectPos = selectPos }

        local cardId = XTRPGManager.GetMazeCardId(__CurrentMazeId, selectPos.LayerId, selectPos.NodeId, cardIndex)

        XTRPGManager.LockSelectCard()

        XNetwork.Call("TRPGMazeSelectCardRequest", req, function(res)

            XTRPGManager.UnlockSelectCard()

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local resultData = res.Result
            local maze = GetMaze(__CurrentMazeId)
            maze:OnCardResult(cardIndex, resultData)
        end)
    end

    function XTRPGManager.NotifyTRPGMazeSelectCardResult(data)
        local resultData = data.Result
        if XTool.IsTableEmpty(resultData) then return end
        if __CurrentMazeId == 0 then return end

        local maze = GetMaze(__CurrentMazeId)
        local cardIndex = resultData.CurPos.Index
        maze:OnCardResult(cardIndex, resultData)
    end

    function XTRPGManager.NotifyMazeRecordCardId(data)
        if XTool.IsTableEmpty(data) then return end

        local mazeId = data.Id
        local maze = GetMaze(mazeId)
        local cardIds = { data.RecordCardId }
        maze:UpdateRecordCards(cardIds)
    end

    --请求放弃挑战
    function XTRPGManager.TRPGMazeGiveUpChallengeRequest(cardIndex, cardId)
        if __CurrentMazeId == 0 then return end

        local layerId = XTRPGManager.GetMazeCurrentLayerId(__CurrentMazeId)
        local nodeId = XTRPGManager.GetMazeCurrentNodeId(__CurrentMazeId)
        local cardId = XTRPGManager.GetMazeCardId(__CurrentMazeId, layerId, nodeId, cardIndex)
        if not XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Fight)
        and not XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.Random) then--随机牌可能随出战斗牌
            return
        end

        local selectPos = {
            LayerId = layerId,
            NodeId = nodeId,
            Index = cardIndex,
        }
        local req = { Pos = selectPos }
        XNetwork.Call("TRPGMazeGiveUpChallengeRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local resultData = res.Result
            local maze = GetMaze(__CurrentMazeId)
            maze:OnCardResult(cardIndex, resultData)
        end)
    end

    --请求快速挑战
    function XTRPGManager.TRPGMazeQuickChallengeRequest(cardIndex)
        if __CurrentMazeId == 0 then return end

        local selectPos = {
            LayerId = XTRPGManager.GetMazeCurrentLayerId(__CurrentMazeId),
            NodeId = XTRPGManager.GetMazeCurrentNodeId(__CurrentMazeId),
            Index = cardIndex,
        }
        local req = { Pos = selectPos }
        XNetwork.Call("TRPGMazeQuickChallengeRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local resultData = res.Result
            local maze = GetMaze(__CurrentMazeId)
            maze:OnCardResult(cardIndex, resultData)
        end)
    end
    -----------------迷宫end------------------
    -----------------主界面begin------------------
    function XTRPGManager.GetAreaState(areaId)
        local openLastTimestamp = XTRPGConfigs.GetAreaOpenLastTimeStamp(areaId)
        if openLastTimestamp > 0 then
            return XTRPGConfigs.AreaStateType.NotOpen
        elseif XTRPGManager.IsAreaExplored(areaId) then
            return XTRPGConfigs.AreaStateType.Over
        end
        return XTRPGConfigs.AreaStateType.Open
    end

    function XTRPGManager.IsAreaExplored(areaId)
        local percent = XTRPGManager.GetMainLineTargetLinkPercentByAreaId(areaId)
        return percent == 1
    end

    function XTRPGManager.GetAreaOpenNum()
        local mainAreaTemplate = XTRPGConfigs.GetMainAreaTemplate()
        local currAreaOpenNum = 0
        local areaState
        for id in pairs(mainAreaTemplate) do
            areaState = XTRPGManager.GetAreaState(id)
            if areaState == XTRPGConfigs.AreaStateType.Open then
                currAreaOpenNum = currAreaOpenNum + 1
            end
        end
        return currAreaOpenNum
    end

    function XTRPGManager.IsNormalPage()
        return IsNormalPage
    end
    -----------------主界面end------------------
    -----------------商店begin----------------
    function XTRPGManager.GetShopItemAlreadyBuyCount(shopId, itemId)
        local shopInfo = ShopInfos[shopId]
        return shopInfo and shopInfo:GetItemCount(itemId) or 0
    end

    function XTRPGManager.GetShopItemAddBuyCount(shopId)
        local shopInfo = ShopInfos[shopId]
        return shopInfo and shopInfo:GetAddBuyCount() or 0
    end

    function XTRPGManager.GetShopItemCanBuyCount(shopId, shopItemId)
        local alreadyBuyCount = XTRPGManager.GetShopItemAlreadyBuyCount(shopId, shopItemId)
        local shopItemCount = XTRPGConfigs.GetShopItemCount(shopId, shopItemId)
        local addBuyCount = XTRPGManager.GetShopItemAddBuyCount(shopId)
        return mathMax(shopItemCount - alreadyBuyCount + addBuyCount, 0)
    end

    function XTRPGManager.GetShopItemConsumeCount(shopId, shopItemId)
        local shopInfo = ShopInfos[shopId]
        local disCount = shopInfo and shopInfo:GetDisCount()
        local consumeCount = XTRPGConfigs.GetShopItemConsumeCount(shopItemId)
        if disCount then
            consumeCount = consumeCount * (disCount / 100)
        end
        return mathCeil(consumeCount)
    end

    function XTRPGManager.GetShopItemIdList(shopId)
        local shopItemIdList = XTRPGConfigs.GetShopItemIdList(shopId)
        local list = {}
        local condition, ret
        local itemId, itemTemplate

        for _, shopItemId in ipairs(shopItemIdList) do
            condition = XTRPGConfigs.GetShopItemCondition(shopItemId)
            ret = XConditionManager.CheckCondition(condition)
            itemId = XTRPGConfigs.GetItemIdByShopItemId(shopItemId)
            itemTemplate = XDataCenter.ItemManager.GetItemTemplate(itemId)
            if ret and itemTemplate then
                tableInsert(list, shopItemId)
            end
        end

        tableSort(list, function(shopItemIdA, shopItemIdB)
            local shopItemLimitCountA = XTRPGConfigs.GetShopItemCount(shopId, shopItemIdA)
            local shopItemLimitCountB = XTRPGConfigs.GetShopItemCount(shopId, shopItemIdB)
            -- 是否卖光
            if (shopItemLimitCountA and shopItemLimitCountA > 0) or (shopItemLimitCountB and shopItemLimitCountB > 0) then
                local canBuyCountA = XDataCenter.TRPGManager.GetShopItemCanBuyCount(shopId, shopItemIdA)
                local canBuyCountB = XDataCenter.TRPGManager.GetShopItemCanBuyCount(shopId, shopItemIdB)
                -- 如果商品有次数限制，并且可购买的数量为0，则判断为售罄
                local isSellOutA = canBuyCountA == 0 and shopItemLimitCountA > 0
                local isSellOutB = canBuyCountB == 0 and shopItemLimitCountB > 0
                if isSellOutA ~= isSellOutB then
                    return isSellOutB
                end
            end
            return shopItemIdA < shopItemIdB
        end)
        return list
    end
    -----------------商店end------------------
    -----------------探索等级 begin----------------
    function XTRPGManager.GetExploreLevel()
        return BaseInfo:GetLevel()
    end

    function XTRPGManager.GetExploreCurExp()
        return BaseInfo:GetExp()
    end

    function XTRPGManager.GetExploreMaxExp()
        return BaseInfo:GetMaxExp()
    end

    function XTRPGManager.GetExploreCurEndurance()
        return BaseInfo:GetEndurance()
    end

    function XTRPGManager.GetExploreMaxEndurance()
        return BaseInfo:GetMaxEndurance()
    end

    function XTRPGManager.GetMaxTalentPoint()
        return BaseInfo:GetMaxTalentPoint()
    end

    function XTRPGManager.CheckSaveIsAlreadyOpenPanelLevel()
        if not XTRPGManager.IsAlreadyLevelUp() then
            return
        end
        if not XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenPanelLevel")) then
            XSaveTool.SaveData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenPanelLevel"), true)
        end
    end

    function XTRPGManager.CheckIsAlreadyOpenPanelLevel()
        return XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenPanelLevel")) or false
    end

    function XTRPGManager.SaveExploreRedPointLevel(level)
        if not XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "ExploreRedPointLevel")) then
            XSaveTool.SaveData(stringFormat("%d%s", XPlayer.Id, "ExploreRedPointLevel"), level)
        end
    end

    function XTRPGManager.GetExploreRedPointLevel()
        return XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "ExploreRedPointLevel"))
    end

    function XTRPGManager.IsAlreadyLevelUp()
        local redPointLevel = BaseInfo:GetRedPointLevel()
        local exploreLevel = XTRPGManager.GetExploreLevel()
        if exploreLevel and redPointLevel then
            return exploreLevel > redPointLevel
        end
        return false
    end

    --第1次升级后显示蓝点，打开说明弹窗后隐藏蓝点
    function XTRPGManager.IsShowExploreRedPointLevel()
        local isAlreadyLevelUp = XTRPGManager.IsAlreadyLevelUp()
        local isAlreadyOpen = XTRPGManager.CheckIsAlreadyOpenPanelLevel()
        return not isAlreadyOpen and isAlreadyLevelUp
    end
    -----------------探索等级 end------------------
    -----------------调查员 begin----------------
    local function GetRole(roleId)
        return Roles[roleId]
    end

    local function UpdateRole(data, checkNew)
        if not data then return end

        local roleId = data.Id
        local newRoleId

        local role = GetRole(roleId)
        if not role then
            role = XTRPGRole.New(roleId)
            Roles[roleId] = role
            newRoleId = checkNew and roleId
        end

        role:UpdateData(data)

        if newRoleId and XTRPGConfigs.GetRoleIsShowTip(newRoleId) then
            XLuaUiManager.Open("UiTRPGNewCharacter", newRoleId)
        end
    end

    local function UpdateRoles(datas, checkNew)
        if not datas then return end
        for _, data in pairs(datas) do
            UpdateRole(data, checkNew)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_ROLES_DATA_CHANGE)
        XEventManager.DispatchEvent(XEventId.EVENT_TRPG_ROLES_DATA_CHANGE)
    end

    function XTRPGManager.GetOwnRoleIds()
        local roleIdList = {}
        for roleId in pairs(Roles) do
            tableInsert(roleIdList, roleId)
        end
        return roleIdList
    end

    function XTRPGManager.GetSortedAllRoleIds()
        return XTRPGConfigs.GetAllRoleIds()
    end

    function XTRPGManager.IsRolesEmpty()
        return XTool.IsTableEmpty(Roles)
    end

    function XTRPGManager.IsRoleOwn(roleId)
        return GetRole(roleId) and true or false
    end

    function XTRPGManager.IsRoleHaveBuffUp(roleId)
        local role = GetRole(roleId)
        return role:IsHaveBuffUp()
    end

    function XTRPGManager.IsRoleHaveBuffDown(roleId)
        local role = GetRole(roleId)
        return role:IsHaveBuffDown()
    end

    function XTRPGManager.GetRoleBuffIds(roleId)
        local role = GetRole(roleId)
        return role:GetBuffIds()
    end

    function XTRPGManager.GetRoleAttributes(roleId)
        local role = GetRole(roleId)
        return role:GetAttributes()
    end

    function XTRPGManager.GetRoleCommonTalentIds(roleId)
        local role = GetRole(roleId)
        return role:GetCommonTalentIds()
    end

    function XTRPGManager.GetRoleTalentIds(roleId)
        local role = GetRole(roleId)
        return role:GetTalentIds()
    end

    function XTRPGManager.GetRoleUsedTalentPoints(roleId)
        local role = GetRole(roleId)
        if not role then return 0 end
        return role:GetUsedTalentPoint()
    end

    function XTRPGManager.GetTotalUsedTalentPoints()
        local totalPoints = 0
        for _, role in pairs(Roles) do
            totalPoints = totalPoints + role:GetUsedTalentPoint()
        end
        return totalPoints
    end

    function XTRPGManager.GetRoleHaveTalentPoints()
        local maxPoints = XTRPGManager.GetMaxTalentPoint()
        local totalUsedPoints = XTRPGManager.GetTotalUsedTalentPoints()
        return maxPoints - totalUsedPoints
    end

    function XTRPGManager.GetActiveTalentCostPoint(roleId, talentId)
        local role = GetRole(roleId)
        return role:GetTalentCostPoint(talentId)
    end

    function XTRPGManager.IsActiveTalentCostEnough(roleId, talentId)
        local havePoints = XTRPGManager.GetRoleHaveTalentPoints()
        local costPoints = XTRPGManager.GetActiveTalentCostPoint(roleId, talentId)
        return havePoints >= costPoints
    end

    function XTRPGManager.IsTalentResetCostEnough()
        local costItemId = XTRPGConfigs.GetTalentResetCostItemId()
        local costItemCount = XTRPGConfigs.GetTalentResetCostItemCount()
        return XDataCenter.ItemManager.CheckItemCountById(costItemId, costItemCount)
    end

    function XTRPGManager.IsRoleAnyTalentActive(roleId)
        local role = GetRole(roleId)
        return role:IsAnyTalentActive()
    end

    function XTRPGManager.IsRoleTalentActive(roleId, talentId)
        local role = GetRole(roleId)
        return role:IsTalentActive(talentId)
    end

    function XTRPGManager.IsRoleTalentCanActive(roleId, talentId)
        local role = GetRole(roleId)
        return role:CanActiveTalent(talentId)
    end

    function XTRPGManager.CheckRoleTalentRedPoint()
        if not XTRPGConfigs.CheckButtonCondition(XTRPGConfigs.ButtonConditionId.Talent) then
            return false
        end

        for _, role in pairs(Roles) do
            if role:CanActiveAnyTalent() then
                return true
            end
        end

        return false
    end

    function XTRPGManager.GetRoleAttributeMinRollValue(roleId, attributeType)
        local role = GetRole(roleId)
        return role:GetAttributeMinRollValue(attributeType)
    end

    function XTRPGManager.GetRoleAttributeMaxRollValue(roleId, attributeType)
        local role = GetRole(roleId)
        return role:GetAttributeMaxRollValue(attributeType)
    end

    function XTRPGManager.GetRolesTotalCanRollValue(attributeType)
        local totalMinValue, totalMaxValue = 0, 0
        for roleId in pairs(Roles) do
            totalMinValue = totalMinValue + XTRPGManager.GetRoleAttributeMinRollValue(roleId, attributeType)
            totalMaxValue = totalMaxValue + XTRPGManager.GetRoleAttributeMaxRollValue(roleId, attributeType)
        end
        return totalMinValue, totalMaxValue
    end

    --请求激活天赋
    function XTRPGManager.TRPGActivateTalentRequest(roleId, talentId, cb)
        local req = { CharacterId = roleId, TalentId = talentId }
        XNetwork.Call("TRPGActivateTalentRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    --请求重置天赋
    function XTRPGManager.TRPGResetTalentRequest(roleId, cb)
        local req = { CharacterId = roleId }
        XNetwork.Call("TRPGResetTalentRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    function XTRPGManager.GetTalentPointTipsData()
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(XDataCenter.ItemManager.ItemId.TRPGTalen)
        local data = {
            Name = goodsShowParams.Name,
            Count = XTRPGManager.GetRoleHaveTalentPoints(),
            Icon = goodsShowParams.BigIcon or goodsShowParams.Icon,
            Quality = goodsShowParams.Quality,
            WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(XDataCenter.ItemManager.ItemId.TRPGTalen),
            Description = XGoodsCommonManager.GetGoodsDescription(XDataCenter.ItemManager.ItemId.TRPGTalen),
            IsTempItemData = true
        }
        return data
    end
    -----------------调查员 end----------------
    -----------------背包begin----------------
    local function UpdateCapacity(capacity)
        AddItemMaxCountNum = capacity or 0
    end

    function XTRPGManager.GetItemMaxCount(itemId)
        local maxCount = XTRPGConfigs.GetItemMaxCount(itemId)
        maxCount = maxCount + AddItemMaxCountNum
        return maxCount
    end

    function XTRPGManager.IsItemMaxCount(itemId)
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)
        local maxCount = XTRPGManager.GetItemMaxCount(itemId)
        return haveCount >= maxCount
    end

    function XTRPGManager.GetItemListByType(itemType)
        local itemList = XDataCenter.ItemManager.GetItemsByType(XItemConfigs.ItemType.TRPGItem)
        local itemTypeCfg
        local list = {}
        for _, v in ipairs(itemList) do
            if not XTRPGManager.IsBagHideItem(v.Id) then
                itemTypeCfg = XTRPGConfigs.GetItemType(v.Id)
                if itemType == itemTypeCfg then
                    table.insert(list, v)
                end
            end
        end

        tableSort(list, function(itemA, itemB)
            return itemA.Id < itemB.Id
        end)

        return list
    end

    function XTRPGManager.IsBagHideItem(id)
        return BagHideItemIdList[id]
    end
    -----------------背包end------------------
    -----------------奖励begin------------------
    function XTRPGManager.IsReceiveReward(id)
        return RewardList[id]
    end

    function XTRPGManager.CheckRewardCondition(trpgRewardId, secondMainId)
        local conditionList = XTRPGConfigs.GetRewardCondition(trpgRewardId)
        local conditionId = secondMainId and conditionList[2] or conditionList[1]   --常规模式领取条件用2，探索模式用1
        if not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId) then
            return true
        end
        return false
    end

    function XTRPGManager.GetAreaRewardPercent(areaId)
        local areaState = XTRPGManager.GetAreaState(areaId)
        if areaState == XTRPGConfigs.AreaStateType.NotOpen then
            return 0
        end

        local areaRewardIdList = XTRPGConfigs.GetAreaRewardIdList(areaId)
        local maxNum = #areaRewardIdList
        local ret
        local num = 0
        for _, trpgRewardId in pairs(areaRewardIdList) do
            ret = XTRPGManager.CheckRewardCondition(trpgRewardId)
            if ret then
                num = num + 1
            end
        end
        return maxNum > 0 and num / maxNum or 0
    end

    function XTRPGManager.GetSecondMainStagePercent(secondMainId)
        local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(secondMainId)
        local secondMainStageFinishNum = 0
        local allSecondMainStageCount = #secondMainStageIdList
        local stageId

        for _, secondMainStageId in ipairs(secondMainStageIdList) do
            stageId = XTRPGConfigs.GetSecondMainStageStageId(secondMainStageId)
            if XTRPGManager.IsStagePass(stageId) then
                secondMainStageFinishNum = secondMainStageFinishNum + 1
            end
        end
        return allSecondMainStageCount > 0 and secondMainStageFinishNum / allSecondMainStageCount or 0
    end

    function XTRPGManager.CheckAreaRewardByAreaId(areaId)
        local areaState = XDataCenter.TRPGManager.GetAreaState(areaId)
        if areaState == XTRPGConfigs.AreaStateType.NotOpen then
            return false
        end

        local areaRewardIdList = XTRPGConfigs.GetAreaRewardIdList(areaId)
        local condition, ret
        local isReceiveReward
        for _, trpgRewardId in pairs(areaRewardIdList) do
            ret = XTRPGManager.CheckRewardCondition(trpgRewardId)
            isReceiveReward = XDataCenter.TRPGManager.IsReceiveReward(trpgRewardId)
            if ret and not isReceiveReward then
                return true
            end
        end
        return false
    end

    function XTRPGManager.CheckAllAreaReward()
        local mainAreaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
        for areaId = 1, mainAreaMaxNum do
            if XTRPGManager.CheckAreaRewardByAreaId(areaId) then
                return true
            end
        end
        return false
    end
    -----------------奖励end------------------
    -----------------任务目标begin-----------------
    function XTRPGManager.GetCurrTargetLinkId()
        return CurrTargetLinkId
    end

    function XTRPGManager.GetCurrTargetId()
        return CurrTargetId
    end

    function XTRPGManager.GetCurrTargetDesc()
        local currTargetId = XTRPGManager.GetCurrTargetId()
        return XTRPGConfigs.GetTargetDesc(currTargetId)
    end

    function XTRPGManager.IsTargetFinish(target)
        local notPreTargetId = XTRPGConfigs.GetNotPreTargetId()
        if type(target) == "string" then        --目标类型string的是前置目标
            local preTargetList = string.Split(target, "|")
            local preTargetId
            local isFinish
            for _, preTargetIdStr in ipairs(preTargetList) do
                isFinish = false
                preTargetId = tonumber(preTargetIdStr)
                if preTargetId == notPreTargetId then
                    return true
                end
                if TargetList[preTargetId] then
                    isFinish = true
                end
                if not isFinish then
                    break
                end
            end
            return isFinish
        else
            if target == notPreTargetId then
                return true
            end
            return TargetList[target]
        end
    end

    --return 目标链是否完成，未完成的目标id
    function XTRPGManager.GetTargetLinkIsFinish(targetLinkId)
        if not targetLinkId or targetLinkId == 0 then
            return true, 0
        end

        local targetIsFinish
        local preTargetIsFinish
        local preTarget
        local targetIdList = XTRPGConfigs.GetTargetIdList(targetLinkId)

        for _, targetId in pairs(targetIdList) do
            targetIsFinish = XTRPGManager.IsTargetFinish(targetId)
            preTarget = XTRPGConfigs.GetPreTargetByTargetId(targetId)
            preTargetIsFinish = XTRPGManager.IsTargetFinish(preTarget)
            if not targetIsFinish and preTargetIsFinish then
                return false, targetId
            end
        end
        return true, 0
    end

    function XTRPGManager.GetAllCanFindTargetLink()
        local targetLinkTemplate = XTRPGConfigs.GetTargetLinkTemplate()
        local allCanFindTarget = {
            [XTRPGConfigs.MissionType.MainLine] = {},
        }
        local targetMissionType
        local targetIsFinish
        local preTargetIsFinish

        for _, v in pairs(targetLinkTemplate) do
            local isInsert = false
            for index, targetId in ipairs(v.TargetId) do
                targetIsFinish = XTRPGManager.IsTargetFinish(targetId)
                preTargetIsFinish = XTRPGManager.IsTargetFinish(v.PreTarget[index])
                if v.TargetMissionType == XTRPGConfigs.MissionType.SubLine and index == 1 and preTargetIsFinish then
                    isInsert = true
                end
                if not targetIsFinish and preTargetIsFinish then
                    local targetTable = { TargetLinkId = v.Id, TargetId = targetId }
                    targetMissionType = XTRPGConfigs.GetTargetLinkMissionType(v.Id)
                    if not allCanFindTarget[targetMissionType] then
                        allCanFindTarget[targetMissionType] = {}
                    end
                    tableInsert(allCanFindTarget[targetMissionType], targetTable)
                    isInsert = false
                    break
                end
            end

            if isInsert then
                if not allCanFindTarget[XTRPGConfigs.MissionType.SubLine] then
                    allCanFindTarget[XTRPGConfigs.MissionType.SubLine] = {}
                end
                tableInsert(allCanFindTarget[XTRPGConfigs.MissionType.SubLine], { TargetLinkId = v.Id, TargetId = 0 })
            end
        end
        return allCanFindTarget
    end

    function XTRPGManager.GetOneCanFindTarget()
        local targetLinkTemplate = XTRPGConfigs.GetTargetLinkTemplate()
        local targetId
        local targetLinkIsFinish
        for _, v in pairs(targetLinkTemplate) do
            targetLinkIsFinish, targetId = XTRPGManager.GetTargetLinkIsFinish(v.Id)
            if not targetLinkIsFinish then
                return v.Id, targetId
            end
        end
        return 0, 0
    end

    function XTRPGManager.IsTargetAllFinish()
        local targetTotalNum = XTRPGConfigs.GetTargetTotalNum()
        local finishTargetNum = 0
        for _ in pairs(TargetList) do
            finishTargetNum = finishTargetNum + 1
        end
        return targetTotalNum == finishTargetNum
    end

    function XTRPGManager.GetTargetLinkPercent(targetLinkId)
        local targetIdList = XTRPGConfigs.GetTargetIdList(targetLinkId)
        local finishNum = 0
        local totalNum = #targetIdList
        for _, targetId in pairs(targetIdList) do
            if XTRPGManager.IsTargetFinish(targetId) then
                finishNum = finishNum + 1
            end
        end
        return totalNum == 0 and 0 or finishNum / totalNum
    end

    function XTRPGManager.GetMainLineTargetLinkPercentByAreaId(areaId)
        local targetLinkIdList = XTRPGConfigs.GetTargetLinkIdList(areaId)
        for _, targetLinkId in pairs(targetLinkIdList) do
            local msiionType = XTRPGConfigs.GetTargetLinkMissionType(targetLinkId)
            if msiionType == XTRPGConfigs.MissionType.MainLine then
                return XTRPGManager.GetTargetLinkPercent(targetLinkId)
            end
        end
        return 0
    end

    function XTRPGManager.IsMovieTargetFinish(movieId)
        local targetId = XTRPGConfigs.GetMovieTargetId(movieId)
        if not targetId or targetId == 0 then
            return false
        end

        return XTRPGManager.IsTargetFinish(targetId)
    end

    function XTRPGManager.CheckRequestTargetLink(currTargetLinkId)
        local notTargetLinkDefaultId = XTRPGConfigs.NotTargetLinkDefaultId
        if notTargetLinkDefaultId == currTargetLinkId and notTargetLinkDefaultId ~= CurrTargetLinkId then
            XDataCenter.TRPGManager.RequestSelectTargetLinkSend(CurrTargetLinkId, true)
        end
    end

    function XTRPGManager.CheckOpenNewMazeTips()
        if not IsCanCheckOpenNewMaze then return end

        SetIsCanCheckOpenNewMaze(false)
        local secondAreaIdToMazeIdDic = XTRPGConfigs.GetSecondAreaIdToMazeIdDic()
        local condition, ret
        local name
        local msg
        for secondAreaId, mazeId in pairs(secondAreaIdToMazeIdDic) do
            if not IsOpenMaze(mazeId) then
                condition = XTRPGConfigs.GetSecondAreaCondition(secondAreaId)
                ret = XConditionManager.CheckCondition(condition)
                if ret then
                    UpdateAlreadyOpenMaze(mazeId)
                    name = XTRPGConfigs.GetSecondAreaName(secondAreaId)
                    msg = CSXTextManagerGetText("TRPGAreaAleardyOpen", name)
                    XUiManager.TipMsgEnqueue(msg)
                end
            end
        end
    end

    function XTRPGManager.GetTaskPanelNewShowTime()
        local oldCurrTargetId = GetOldCurrTargetId()
        local currTargetId = XTRPGManager.GetCurrTargetId()
        if oldCurrTargetId ~= currTargetId then
            UpdateOldCurrTargetId()
            local serverTimestamp = XTime.GetServerNowTimestamp()
            local taskPanelNewShowTimeCfg = XTRPGConfigs.GetTaskPanelNewShowTime()
            return serverTimestamp + taskPanelNewShowTimeCfg
        end
        return 0
    end

    function XTRPGManager.SetNewTargetTime(newTargetTime)
        NewTargetTime = newTargetTime
    end

    function XTRPGManager.GetNewTargetTime()
        return NewTargetTime
    end

    function XTRPGManager.ClearNewTargetTime()
        NewTargetTime = 0
    end
    -----------------任务目标end------------------
    -----------------求真之路begin------------------
    function XTRPGManager.GetTruthRoadPercent(truthRoadGroupId)
        local truthRoadIdList = XTRPGConfigs.GetTruthRoadIdList(truthRoadGroupId)
        local truthRoadFinishNum = 0
        for _, truthRoadId in pairs(truthRoadIdList) do
            local condition = XTRPGConfigs.GetTruthRoadCondition(truthRoadId)
            local ret = XConditionManager.CheckCondition(condition)
            if ret then
                truthRoadFinishNum = truthRoadFinishNum + 1
            end
        end
        return #truthRoadIdList > 0 and truthRoadFinishNum / #truthRoadIdList or 0
    end

    function XTRPGManager.IsTruthRoadOpenArea(areaId)
        local truthRoadGroupIdList = XTRPGConfigs.GetTruthRoadGroupIdList(areaId)
        local condition
        local ret
        for i, truthRoadGroupId in ipairs(truthRoadGroupIdList) do
            condition = XTRPGConfigs.GetTruthRoadGroupCondition(truthRoadGroupId)
            ret = XConditionManager.CheckCondition(condition)
            if ret then
                return true, i
            end
        end
        return false
    end

    function XTRPGManager.IsTruthRoadGroupConditionFinish(areaId, index)
        local truthRoadGroupId = XTRPGConfigs.GetTruthRoadGroupId(areaId, index)
        local condition = XTRPGConfigs.GetTruthRoadGroupCondition(truthRoadGroupId)
        local ret, desc = XConditionManager.CheckCondition(condition)
        return ret, desc
    end

    function XTRPGManager.CheckTruthRoadReward(truthRoadGroupId)
        local rewardIdList = XTRPGConfigs.GetTruthRoadRewardIdList(truthRoadGroupId)
        local conditionId, ret
        local isReceiveReward
        for _, trpgRewardId in ipairs(rewardIdList) do
            ret = XTRPGManager.CheckRewardCondition(trpgRewardId)
            isReceiveReward = XTRPGManager.IsReceiveReward(trpgRewardId)
            if ret and not isReceiveReward then
                return true
            end
        end
        return false
    end

    function XTRPGManager.CheckTruthRoadAreaReward(areaId)
        local truthRoadGroupIdList = XTRPGConfigs.GetTruthRoadGroupIdList(areaId)
        for _, truthRoadGroupId in ipairs(truthRoadGroupIdList) do
            if XTRPGManager.CheckTruthRoadReward(truthRoadGroupId) then
                return true
            end
        end
        return false
    end

    function XTRPGManager.CheckTruthRoadAllReward()
        local mainAreaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
        for i = 1, mainAreaMaxNum do
            if XTRPGManager.CheckTruthRoadAreaReward(i) then
                return true
            end
        end
        return false
    end

    function XTRPGManager.SaveIsAlreadyOpenTruthRoad()
        if not XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenTruthRoad")) then
            XSaveTool.SaveData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenTruthRoad"), true)
            XEventManager.DispatchEvent("EVENT_TRPG_FIRST_OPEN_TRUTH_ROAD")
        end
    end

    function XTRPGManager.CheckIsAlreadyOpenTruthRoad()
        return XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenTruthRoad")) or false
    end
    -----------------求真之路end--------------------
    ---------------------珍藏-回忆begin-------------------------
    function XTRPGManager.IsPlayedMemoir(id)
        return MemoirList[id]
    end

    function XTRPGManager.IsCanPlayMemoir(id)
        local itemId = XTRPGConfigs.GetMemoireStoryUnlockItemId(id)
        local ownCount = XDataCenter.ItemManager.GetCount(itemId)
        local maxCount = XTRPGConfigs.GetMemoireStoryUnlockItemCount(id)
        return ownCount >= maxCount
    end

    function XTRPGManager.CheckFirstPlayMemoirStoryById(id)
        local isCanPlay = XTRPGManager.IsCanPlayMemoir(id)
        local isPlayed = XTRPGManager.IsPlayedMemoir(id)
        return isCanPlay and not isPlayed
    end

    function XTRPGManager.CheckFirstPlayMemoirStory()
        local maxNum = XTRPGConfigs.GetMemoirStoryMaxNum()
        for i = 1, maxNum do
            if XTRPGManager.CheckFirstPlayMemoirStoryById(i) then
                return true
            end
        end
        return false
    end

    function XTRPGManager.SaveIsAlreadyOpenCollection()
        if not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "IsAlreadyOpenCollection")) then
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "IsAlreadyOpenCollection"), true)
            XEventManager.DispatchEvent("EVENT_TRPG_FIRST_OPEN_COLLECTION")
        end
    end

    function XTRPGManager.CheckIsAlreadyOpenCollection()
        return XSaveTool.GetData(stringFormat("%d%s", XPlayer.Id, "IsAlreadyOpenCollection")) or false
    end
    ---------------------珍藏-回忆end---------------------------
    ---------------------第三区域 begin-------------------------
    local function SetThirdAreaFunctionFinish(thirdAreaId, functionId)
        thirdAreaId = DEFUALT_thirdAreaId_FOR_STUPID_DESIGN or thirdAreaId

        if not ThirdAreaInfos[thirdAreaId] then
            ThirdAreaInfos[thirdAreaId] = XTRPGThirdAreaInfo.New()
        end
        ThirdAreaInfos[thirdAreaId]:SetFunctionFinished(functionId)
    end

    local function UpdateThirdAreaInfos(thirdAreaInfos)
        if not thirdAreaInfos then return end

        if DEFUALT_thirdAreaId_FOR_STUPID_DESIGN then
            local thirdAreaId = DEFUALT_thirdAreaId_FOR_STUPID_DESIGN
            for _, functionId in pairs(thirdAreaInfos) do
                SetThirdAreaFunctionFinish(thirdAreaId, functionId)
            end

            return
        end

        for thirdAreaId, functionIds in pairs(thirdAreaInfos) do
            for _, functionId in pairs(functionIds) do
                SetThirdAreaFunctionFinish(thirdAreaId, functionId)
            end
        end
    end

    local function GetThirdAreaInfo(thirdAreaId)
        thirdAreaId = DEFUALT_thirdAreaId_FOR_STUPID_DESIGN or thirdAreaId
        return ThirdAreaInfos[thirdAreaId]
    end

    function XTRPGManager.IsFunctionGroupConditionFinish(functionGroupId)
        local condition = XTRPGConfigs.GetFunctionGroupConditionId(functionGroupId)
        local ret, desc = XConditionManager.CheckCondition(condition)
        return ret, desc
    end

    function XTRPGManager.IsThirdAreaFunctionFinish(thirdAreaId, functionId)
        local areaInfo = GetThirdAreaInfo(thirdAreaId)
        return areaInfo and areaInfo:IsFunctionFinished(functionId)
    end

    function XTRPGManager.IsThirdAreaFunctionAllFinish(thirdAreaId)
        return #XTRPGManager.GetUnFinishedFunctionIdList(thirdAreaId) == 0
    end

    function XTRPGManager.GetUnFinishedFunctionIdList(thirdAreaId)
        local functionIdList = {}

        local functionGroupIds = XTRPGConfigs.GetThirdAreaFunctionGroupIds(thirdAreaId)
        for _, functionGroupId in ipairs(functionGroupIds) do
            if XTRPGManager.IsFunctionGroupConditionFinish(functionGroupId) then

                local functionIds = XTRPGConfigs.GetFunctionGroupFunctionIds(functionGroupId)
                for _, functionId in ipairs(functionIds) do
                    if not XTRPGManager.IsThirdAreaFunctionFinish(thirdAreaId, functionId) then
                        tableInsert(functionIdList, functionId)
                        break
                    end
                end

            end
        end

        return functionIdList
    end

    local __ToFinishFightFunctionId = 0 --战斗胜利后请求完成的FunctionId
    function XTRPGManager.EnterFunctionFight(functionId)
        if not XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.FinishStage) then
            return
        end

        __ToFinishFightFunctionId = functionId

        local params = XTRPGConfigs.GetFunctionParams(functionId)
        local stageId = tonumber(params[1])
        XLuaUiManager.Open("UiBattleRoleRoom", stageId)
    end

    function XTRPGManager.ReqFinishFunctionAfterFight(thirdAreaId)
        local functionId = __ToFinishFightFunctionId
        if not functionId or functionId == 0 then return end

        XDataCenter.TRPGManager.RequestFunctionFinishSend(thirdAreaId, functionId)
    end

    --请求完成功能id
    function XTRPGManager.RequestFunctionFinishSend(thirdAreaId, functionId)
        if not XTRPGConfigs.CheckFunctionNeedSave(functionId) then return end

        local req = { FunctionId = functionId }
        XNetwork.Call("TRPGFunctionFinishRequest", req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.CommitItem) then
                local params = XTRPGConfigs.GetFunctionParams(functionId)
                local itemId = tonumber(params[1])
                XLuaUiManager.Open("UiTRPGCommitItem", itemId)
            end

            XTRPGManager.OnGetReward(res.RewardList)

            SetThirdAreaFunctionFinish(thirdAreaId, functionId)

            XEventManager.DispatchEvent(XEventId.EVENT_TRPG_FUNCTION_FINISH_SYN)
        end)
    end

    function XTRPGManager.OnGetReward(rewardList, closeCb)
        if XTool.IsTableEmpty(rewardList) then return end

        local reward = rewardList[1]
        local itemId = reward.TemplateId
        local itemCount = reward.Count
        XLuaUiManager.Open("UiTRPGObtain", itemId, itemCount, closeCb)
    end
    ---------------------第三区域 end---------------------------
    ---------------------世界BOSS begin--------------------
    function XTRPGManager.GetWorldBossLoseHp()
        return BossInfo:GetLoseHp()
    end

    function XTRPGManager.GetWorldBossTotalHp()
        return BossInfo:GetTotalHp()
    end

    function XTRPGManager.GetWorldBossCurHpPercer()
        local loseHp = XDataCenter.TRPGManager.GetWorldBossLoseHp()
        local totalHp = XDataCenter.TRPGManager.GetWorldBossTotalHp()
        return totalHp > 0 and (totalHp - loseHp) / totalHp or 0
    end

    function XTRPGManager.IsWorldBossAleardyReceiveReward(id)
        return BossInfo:IsReceiveReward(id)
    end

    function XTRPGManager.IsWorldBossCanReceiveReward(id)
        local curPercent = XTRPGManager.GetWorldBossCurHpPercer()
        local percentCfg = XTRPGConfigs.GetBossPhasesRewardPercent(id)
        percentCfg = percentCfg * 0.01
        return curPercent <= percentCfg
    end

    function XTRPGManager.GetWorldBossChallengeCount()
        return BossInfo:GetChallengeCount()
    end

    function XTRPGManager.GetWorldBossOpenState()
        local nowTime = XTime.GetServerNowTimestamp()
        local timeId = XTRPGConfigs.GetBossTimeId()
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
        if nowTime < startTime then
            return XTRPGConfigs.AreaStateType.NotOpen, startTime - nowTime
        elseif nowTime >= startTime and nowTime < endTime then
            return XTRPGConfigs.AreaStateType.Open, endTime - nowTime
        else
            return XTRPGConfigs.AreaStateType.Over, 0
        end
    end

    function XTRPGManager.CheckWorldBossReward()
        local openState = XTRPGManager.GetWorldBossOpenState()
        if openState ~= XTRPGConfigs.AreaStateType.Open then
            return false
        end

        local isAleardyReceive
        local isCanReceive
        local bossPhasesRewardTemplate = XTRPGConfigs.GetBossPhasesRewardTemplate()
        for _, v in pairs(bossPhasesRewardTemplate) do
            isCanReceive = XDataCenter.TRPGManager.IsWorldBossCanReceiveReward(v.Id)
            isAleardyReceive = XDataCenter.TRPGManager.IsWorldBossAleardyReceiveReward(v.Id)
            if isCanReceive and not isAleardyReceive then
                return true
            end
        end
        return false
    end
    ---------------------世界BOSS end---------------------
    ---------------------检定相关 begin---------------------------
    function XTRPGManager.GetExamineActionDifficult(actionId)
        --道具检定无难度
        if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
            return XTRPGConfigs.TRPGExamineActionDifficult.Default
        end

        local needValue = XTRPGConfigs.GetExamineActionNeedValue(actionId)
        local _, totalMaxValue = XTRPGManager.GetExamineActionTotalCallRollValue(actionId)
        local delta = totalMaxValue - needValue
        return XTRPGConfigs.GetExamineActionDifficultByDelta(delta)
    end

    --return 所有角色单属性所有轮次可摇点最小值,最大值
    function XTRPGManager.GetExamineActionTotalCallRollValue(actionId)
        local attributeType = XTRPGConfigs.GetExamineActionNeedAttrType(actionId)
        local totalMinValue, totalMaxValue = XTRPGManager.GetRolesTotalCanRollValue(attributeType)
        local round = XTRPGConfigs.GetExamineActionRound(actionId)
        return round * totalMinValue, round * totalMaxValue
    end

    function XTRPGManager.CheckExamineCostEnduranceEnough(examineId)
        local costEndurance = XTRPGConfigs.GetExamineCostEndurance(examineId)
        local curEndurance = XTRPGManager.GetExploreCurEndurance()
        return curEndurance >= costEndurance
    end

    function XTRPGManager.EnterExamine(examineId)
        local enterFunc = function()
            XLuaUiManager.Open("UiTRPGTestDetailsTips", examineId)
        end
        local endCallBack = function()
            XDataCenter.TRPGManager.CheckOpenNewMazeTips()
        end

        local movieId = XTRPGConfigs.GetExamineStartMovieId(examineId)
        if not string.IsNilOrEmpty(movieId) then
            local yieldCb = enterFunc
            local hideSkipBtn = true
            XDataCenter.MovieManager.PlayMovie(movieId, endCallBack, yieldCb, hideSkipBtn)
        else
            XLuaUiManager.Open("UiTRPGTestDetailsTips", examineId)
        end
    end

    function XTRPGManager.StartExamine(examineId, actionId)
        CurExmaine:Start(examineId, actionId)
        XLuaUiManager.Open("UiTRPGTest")
    end

    function XTRPGManager.FinishExamine()
        CurExmaine:Clear()
    end

    function XTRPGManager.EnterExaminePunish()
        CurExmaine:EnterPunish()
    end

    function XTRPGManager.GetCurExamineId()
        return CurExmaine:GetId()
    end

    function XTRPGManager.GetCurExamineActionId()
        return CurExmaine:GetActionId()
    end

    function XTRPGManager.GetCurExamineCurAndReqScore()
        return CurExmaine:GetScores()
    end

    function XTRPGManager.GetCurExamineCurRound()
        return CurExmaine:GetCurRound()
    end

    function XTRPGManager.GetCurExamineRoleScore(roleId)
        return CurExmaine:GetRoleScore(roleId)
    end

    function XTRPGManager.CheckExamineStatus(examineStatus)
        return CurExmaine:CheckStatus(examineStatus)
    end

    function XTRPGManager.IsExaminePassed()
        return CurExmaine:IsPassed()
    end

    function XTRPGManager.IsExamineCanEnterNextRound()
        return CurExmaine:IsCanEnternNextRound()
    end

    function XTRPGManager.IsExamineRoleAlreadyRolled(roleId)
        return CurExmaine:IsRoleAlreadyRolled(roleId)
    end

    function XTRPGManager.IsExamineLastRound()
        return CurExmaine:IsLastRound()
    end

    function XTRPGManager.GetCurExaminePunishId()
        return CurExmaine:GetPunishId()
    end

    local function UpdateCurExmaineResult(data)
        if XTool.IsTableEmpty(data) then return end
        CurExmaine:UpdateResult(data)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_EXAMINE_RESULT_SYN)
    end

    local function UpdateCurExmaineScore(data)
        if XTool.IsTableEmpty(data) then return end
        CurExmaine:UpdateScore(data)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_EXAMINE_DATA_CHANGE)
    end

    --请求检定
    local ExamineAsynLock
    function XTRPGManager.RequestExamineSend(examineId, actionId, cb)
        if ExamineAsynLock then return end
        ExamineAsynLock = true

        local req = { Id = examineId, ActionId = actionId }
        XNetwork.Call("TRPGExamineRequest", req, function(res)
            ExamineAsynLock = nil
            
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then cb() end

            XTRPGManager.StartExamine(examineId, actionId)
        end)
    end

    --请求检定单个角色
    function XTRPGManager.RequestExamineCharacterSend(examineId, actionId, roleId, useItemId)
        local curRound = XTRPGManager.GetCurExamineCurRound()
        if XTRPGConfigs.CheckDefaultEffectItemId(useItemId) then
            useItemId = nil
        end

        local req = { Id = examineId, ActionId = actionId, Round = curRound, CharacterId = roleId, UseItemId = useItemId }
        XNetwork.Call("TRPGExamineCharacterRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local data = {
                RoleId = roleId,
                Score = res.Score,
            }
            UpdateCurExmaineScore(data)
        end)
    end

    --确定检定结果
    function XTRPGManager.RequestExamineResult(examineId)
        local req = { Id = examineId }
        XNetwork.Call("TRPGExamineResultRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateCurExmaineResult(res)
        end)
    end

    --重置检定
    function XTRPGManager.TRPGExamineCharacterResetRequest(roleId)
        local req = { CharacterId = roleId }
        XNetwork.Call("TRPGExamineCharacterResetRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local data = {
                RoleId = roleId,
                Score = 0,
            }
            UpdateCurExmaineScore(data)
        end)
    end

    --进入下一轮检定
    function XTRPGManager.TRPGExamineChangeRoundRequest()
        XNetwork.Call("TRPGExamineChangeRoundRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CurExmaine:EnterNextRound()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_EXAMINE_ROUND_CHANGE)
        end)
    end
    ---------------------检定相关 end---------------------------
    ---------------------protocol begin------------------
    --商店购买
    function XTRPGManager.RequestShopBuyItemSend(shopId, itemId, itemCount, cb)
        local req = { ShopId = shopId, ItemId = itemId, ItemCount = itemCount }
        XNetwork.Call("TRPGShopBuyItemRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            AddBuyTimes(shopId, itemId, itemCount)
            XUiManager.OpenUiObtain(res.RewardList)
            if cb then
                cb()
            end
        end)
    end

    --更新探索员信息
    function XTRPGManager.NotifyTRPGCharacterData(data)
        local checkNew = true
        UpdateRoles(data.Characters, checkNew)
    end

    --更新已完成目标（增量更新）
    function XTRPGManager.NotifyTRPGTargetFinish(data)
        local tempCurrTargetLinkId = CurrTargetLinkId
        UpdateTargetList(data.TargetList)
        UpdateCurrTargetLinkId(CurrTargetLinkId)

        SetIsCanCheckOpenNewMaze(true)

        if tempCurrTargetLinkId ~= CurrTargetLinkId then
            XTRPGManager.CheckRequestTargetLink(XTRPGConfigs.NotTargetLinkDefaultId)
        end
    end

    function XTRPGManager.NotifyTRPGFunctionFinish(data)
    end

    --更新商店打折和购买上限
    function XTRPGManager.NotifyTRPGShopExtraData(data)
        UpdateShopExtraData(data.ExtraDatas)
    end

    --更新商店信息
    function XTRPGManager.NotifyTRPGClientShopInfo(data)
        UpdateShopInfos(data.ShopInfos)
    end

    --重置数据
    function XTRPGManager.NotifyTRPGDailyResetData(data)
        BaseInfo:UpdateEndurance(data.Endurance)
        UpdateCapacity(data.ItemCapacityAdd)
        UpdateRoles(data.Characters)
        UpdateWorldBossChallengeCount(data.BossChallengeCount)
        UpdateShopInfos(data.ShopInfos)
    end

    function XTRPGManager.RequestSelectTargetLinkSend(targetLinkid, isHideTip, isNotPlayNewAnima)
        local req = { Id = targetLinkid }
        XNetwork.Call("TRPGSelectTargetLinkRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateCurrTargetLinkId(targetLinkid, isNotPlayNewAnima)
            if not isHideTip then
                XUiManager.TipText("TRPGSwitchTargetComplete")
            end
        end)
    end

    function XTRPGManager.NotifyTRPGItemCapacityChange(data)
        UpdateCapacity(data.ItemCapacityAdd)
    end

    function XTRPGManager.NotifyTRPGBaseInfo(data)
        BaseInfo:UpdateData(data.BaseInfo)
    end

    function XTRPGManager.NotifyTRPGData(data)
        UpdateBossInfo(data.BossInfo)
        UpdateTargetList(data.TargetList)
        UpdateCurrTargetLinkId(data.CurTargetLink)
        UpdateRewardList(data.RewardList)
        UpdateRoles(data.Characters)
        UpdateShopInfos(data.ShopInfos)
        UpdateMazeInfos(data.MazeInfos)
        UpdateMemoirInfos(data.MemoirList)
        UpdateCapacity(data.ItemCapacityAdd)
        BaseInfo:UpdateData(data.BaseInfo)
        -- UpdateThirdAreaInfos(data.ThirdAreaInfos)--数据预期不一致兼容
        UpdateThirdAreaInfos(data.FuncList)
        SetIsNormalPage(data.IsNormalPage)
        UpdateStagePassDic(data.StageList)

        InitAleardyOpenMazeList()
        UpdateOldCurrTargetId()
        XTRPGManager.CheckRequestTargetLink(data.CurTargetLink)
        XTRPGManager.RequestTRPGBossDetailSend()
    end

    --使用道具
    function XTRPGManager.RequestUseItemRequestSend(itemId, itemCount, characterId, cb)
        local req = { ItemId = itemId, ItemCount = itemCount, CharacterId = characterId }
        XNetwork.Call("TRPGUseItemRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("TRPGUseItemComplete")
            if cb then
                cb()
            end
        end)
    end

    --请求领取奖励
    function XTRPGManager.RequestRewardSend(id, cb)
        local req = { Id = id }
        XNetwork.Call("TRPGRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateRewardList({ id })
            XUiManager.OpenUiObtain(res.RewardList)
            if cb then
                cb()
            end
            XEventManager.DispatchEvent("EVENT_TRPG_GET_REWARD")
        end)
    end

    --请求播放记忆剧情
    function XTRPGManager.RequestTRPGOpenMemoirSend(id, cb)
        local req = { Id = id }
        XNetwork.Call("TRPGOpenMemoirRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateMemoirInfos({ req.Id })
            if cb then
                cb()
            end
            XEventManager.DispatchEvent("EVENT_TRPG_GET_MEMOIR_REWARD")
        end)
    end

    --请求boss血量
    function XTRPGManager.RequestTRPGBossDetailSend(cb)
        local openState = XTRPGManager.GetWorldBossOpenState()
        if openState ~= XTRPGConfigs.AreaStateType.Open then
            return
        end

        XNetwork.Call("TRPGBossDetailRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateBossHpInfo(res)
            if cb then
                cb()
            end
        end)
    end

    --请求boss阶段奖励
    function XTRPGManager.RequestTRPGBossPhasesRewardSend(id, cb)
        local req = { Id = id }
        XNetwork.Call("TRPGBossPhasesRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateBossPhasesRewardListInfo({ req.Id })
            XUiManager.OpenUiObtain(res.RewardList)
            if cb then
                cb()
            end
        end)
    end

    --世界BOSS信息发生改变
    function XTRPGManager.NotifyTRPGClientBossData(data)
        UpdateBossInfo(data.BaseInfo)
    end

    --请求改变模式
    function XTRPGManager.RequestTRPGChangePageStatus(status)
        local req = {Status = status}
        XNetwork.Call("TRPGChangePageStatusRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SetIsNormalPage(status)
        end)
    end
    ---------------------protocol end------------------
    ---------------------FubenManager begin------------------
    local function InitStageType(stageId)
        stageId = tonumber(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.TRPG
        end
    end

    function XTRPGManager.InitStageInfo()
        local stageId = XTRPGConfigs.GetBossStageId()
        InitStageType(stageId)

        local stageIds = XTRPGConfigs.GetFunctionStageIds()
        for _, stageId in pairs(stageIds) do
            InitStageType(stageId)
        end

        local secondMainIdList = XTRPGConfigs.GetSecondMainIdList()
        for _, secondMainId in ipairs(secondMainIdList) do
            local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(secondMainId)
            for _, secondMainStageId in ipairs(secondMainStageIdList) do
                local stageId = XTRPGConfigs.GetSecondMainStageStageId(secondMainStageId)
                InitStageType(stageId)
            end
        end
    end

    function XTRPGManager.ShowReward(winData)
        if XTRPGConfigs.IsBossStage(winData.StageId) then
            XLuaUiManager.Open("UiTRPGWinWorldBoss", winData)
        else
            XTRPGManager.ReqFinishFunctionAfterFight()
            XDataCenter.FubenManager.ShowReward(winData)
        end
        XTRPGManager.SetStagePass(winData.StageId)
    end
    ---------------------FubenManager end------------------
    function XTRPGManager.Init()
        InitMazes()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
            XDataCenter.TRPGManager.InitCurrAreaOpenNum()
        end)
    end

    --------------------首次播放剧情 begin------------------------
    function XTRPGManager.MarkStoryID(Id, key)
        if not XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, key, Id)) then
            XSaveTool.SaveData(string.format("%d%s%s", XPlayer.Id, key, Id), Id)
        end
    end

    function XTRPGManager.CheckIsNewStoryID(Id, key)
        if XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, key, Id)) then
            return false
        end
        return true
    end
    --------------------首次播放剧情 end--------------------------
    --------------------跳转 start--------------------------
    function XTRPGManager.SkipTRPGMain()
        if XDataCenter.FubenMainLineManager.IsMainLineActivityOpen() then
            local chapterId = XDataCenter.FubenMainLineManager.TRPGChapterId
            local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
            if ret then
                XTRPGManager.PlayStartStory(XTRPGManager.UpdateCurrAreaOpenNum)
            else
                XUiManager.TipError(desc)
            end
        elseif XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MainLineTRPG) then
            XTRPGManager.PlayStartStory(XTRPGManager.UpdateCurrAreaOpenNum)
        end
    end

    function XTRPGManager.GetMainName()
        local isNormalPage = XTRPGManager.IsNormalPage()
        return isNormalPage and "UiTRPGSecondMain" or "UiTRPGMain"
    end
    --------------------跳转 end--------------------------
    --------------------抢先体验 begin---------------------
    function XTRPGManager.CheckActivityEnd()
        if not XDataCenter.FubenMainLineManager.IsMainLineActivityOpen() and not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MainLineTRPG) then
            XTRPGManager.OnActivityEnd()
        end
    end

    function XTRPGManager.OnActivityMainLineStateChange(chapterIds)
        if not chapterIds then
            return
        end
        for _, chapterId in pairs(chapterIds) do
            if chapterId == XDataCenter.FubenMainLineManager.TRPGChapterId then
                XTRPGManager.OnActivityEnd()
                return
            end
        end
    end

    function XTRPGManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
    --------------------抢先体验 end---------------------
    --------------------区域（城市和迷宫）地图 start---------------------
    function XTRPGManager.SaveIsAlreadyOpenExploreChapter(secondAreaId, mainAreaId)
        if not XSaveTool.GetData(stringFormat("%d%s%s%s", XPlayer.Id, "IsAlreadyOpenExploreChapter", secondAreaId, mainAreaId)) then
            XSaveTool.SaveData(stringFormat("%d%s%s%s", XPlayer.Id, "IsAlreadyOpenExploreChapter", secondAreaId, mainAreaId), true)
        end
    end

    function XTRPGManager.CheckIsAlreadyOpenExploreChapter(secondAreaId, mainAreaId)
        return XSaveTool.GetData(stringFormat("%d%s%s%s", XPlayer.Id, "IsAlreadyOpenExploreChapter", secondAreaId, mainAreaId)) or false
    end

    function XTRPGManager.SaveIsAlreadyEnterMaze(mazeId)
        if not XSaveTool.GetData(stringFormat("%d%s%s", XPlayer.Id, "IsAlreadyEnterMaze", mazeId)) then
            XSaveTool.SaveData(stringFormat("%d%s%s", XPlayer.Id, "IsAlreadyEnterMaze", mazeId), true)
        end
    end

    function XTRPGManager.CheckIsAlreadyEnterMaze(mazeId)
        local mazeProgress = XTRPGManager.GetMazeProgress(mazeId)
        if mazeProgress > 0 or XSaveTool.GetData(stringFormat("%d%s%s", XPlayer.Id, "IsAlreadyEnterMaze", mazeId)) then
            return true
        end
        return false
    end
    --------------------区域（城市和迷宫）地图 end---------------------
    --------------------常规主线 start---------------------
    --是否有可领取的奖励
    function XTRPGManager.IsSecondMainCanReward(secondMainId)
        local ret = XTRPGManager.CheckSecondMainCondition(secondMainId)
        if not ret then
            return false
        end

        local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(secondMainId)
        local trpgRewardId
        local isReceiveReward
        for _, secondMainStageId in ipairs(secondMainStageIdList) do
            trpgRewardId = XTRPGConfigs.GetSecondMainStageRewardId(secondMainStageId)
            if not XTool.IsNumberValid(trpgRewardId) then
                goto continue
            end

            ret = XTRPGManager.CheckRewardCondition(trpgRewardId, secondMainId)
            isReceiveReward = XDataCenter.TRPGManager.IsReceiveReward(trpgRewardId)
            if ret and not isReceiveReward then
                return true
            end
            :: continue ::
        end
        return false
    end

    function XTRPGManager.CheckSecondMainCondition(secondMainId)
        local conditionList = XTRPGConfigs.GetSecondMainCondition(secondMainId)
        local ret
        local desc = ""
        for i, condition in ipairs(conditionList) do
            ret, desc = XConditionManager.CheckCondition(condition)
            if ret then
                return true
            end
        end
        return false, desc
    end

    function XTRPGManager.CheckSecondMainStageCondition(secondMainStageId)
        local conditionList = XTRPGConfigs.GetSecondMainStageCondition(secondMainStageId)
        local ret
        local desc = ""
        for i, condition in ipairs(conditionList) do
            ret, desc = XConditionManager.CheckCondition(condition)
            if ret then
                return true
            end
        end
        return false, desc
    end

    function XTRPGManager.SetStagePass(stageId)
        StagePassDic[stageId] = true
    end

    function XTRPGManager.IsStagePass(stageId)
        return StagePassDic[stageId] or false
    end

    function XTRPGManager.IsSecondMainReward()
        local secondMainIdList = XTRPGConfigs.GetSecondMainIdList()
        for i, secondMainId in ipairs(secondMainIdList) do
            if XDataCenter.TRPGManager.IsSecondMainCanReward(secondMainId) then
                return true
            end
        end
        return false
    end
    
    -- 首次进入播放剧情
    function XTRPGManager.PlayStartStory(callback)
        local OpenMainUi = function(uiName)
            if uiName == nil then
                uiName = XTRPGManager.GetMainName()
            end
            XLuaUiManager.OpenWithCallback(uiName, callback)
        end
        
        local TRPGFirstOpenFunctionGroupId = CS.XGame.ClientConfig:GetInt("TRPGFirstOpenFunctionGroupId")
        if not XTRPGManager.IsFunctionGroupConditionFinish(TRPGFirstOpenFunctionGroupId) then
            OpenMainUi()
            return
        end

        local functionIds = XTRPGConfigs.GetFunctionGroupFunctionIds(TRPGFirstOpenFunctionGroupId)
        for _, functionId in ipairs(functionIds) do
            if not XTRPGManager.IsThirdAreaFunctionFinish(nil, functionId) then
                if XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Story) then
                    local params = XTRPGConfigs.GetFunctionParams(functionId)
                    local movieId = params[1]
                    local cb = function()
                        XTRPGManager.RequestFunctionFinishSend(nil, functionId)
                        -- 第一次打开常规模式
                        if not XTRPGManager.IsNormalPage() then
                            XTRPGManager.RequestTRPGChangePageStatus(true)
                        end
                        OpenMainUi("UiTRPGSecondMain")
                    end
                    XDataCenter.MovieManager.PlayMovie(movieId, cb, nil, nil, false)
                    return
                end
            end
        end

        OpenMainUi()
    end
    --------------------常规主线 start---------------------
    XTRPGManager.Init()

    return XTRPGManager
end
---------------------(服务器推送)begin------------------
XRpc.NotifyTRPGCharacterData = function(data)
    XDataCenter.TRPGManager.NotifyTRPGCharacterData(data)
end

XRpc.NotifyTRPGTargetFinish = function(data)
    XDataCenter.TRPGManager.NotifyTRPGTargetFinish(data)
end

XRpc.NotifyTRPGData = function(data)
    XDataCenter.TRPGManager.NotifyTRPGData(data)
end

XRpc.NotifyTRPGFunctionFinish = function(data)
    XDataCenter.TRPGManager.NotifyTRPGFunctionFinish(data)
end

XRpc.NotifyTRPGShopExtraData = function(data)
    XDataCenter.TRPGManager.NotifyTRPGShopExtraData(data)
end

XRpc.NotifyTRPGItemCapacityChange = function(data)
    XDataCenter.TRPGManager.NotifyTRPGItemCapacityChange(data)
end

XRpc.NotifyTRPGClientShopInfo = function(data)
    XDataCenter.TRPGManager.NotifyTRPGClientShopInfo(data)
end

XRpc.NotifyTRPGDailyResetData = function(data)
    XDataCenter.TRPGManager.NotifyTRPGDailyResetData(data)
end

XRpc.NotifyTRPGBaseInfo = function(data)
    XDataCenter.TRPGManager.NotifyTRPGBaseInfo(data)
end

XRpc.NotifyTRPGMazeSelectCardResult = function(data)
    XDataCenter.TRPGManager.NotifyTRPGMazeSelectCardResult(data)
end

XRpc.NotifyMazeRecordCardId = function(data)
    XDataCenter.TRPGManager.NotifyMazeRecordCardId(data)
end

XRpc.NotifyTRPGClientBossData = function(data)
    XDataCenter.TRPGManager.NotifyTRPGClientBossData(data)
end
---------------------(服务器推送)end------------------    
---@class XGoldenMinerControl : XControl
---@field private _Model XGoldenMinerModel
local XGoldenMinerControl = XClass(XControl, "XGoldenMinerControl")
local METHOD_NAME = {
    GoldenMinerFinishStageRequest = "GoldenMinerFinishStageRequest",
    GoldenMinerEnterGameRequest = "GoldenMinerEnterGameRequest",
    GoldenMinerShipUpgradeRequest = "GoldenMinerShipUpgradeRequest",
    GoldenMinerShopBuyRequest = "GoldenMinerShopBuyRequest",
    GoldenMinerRankingRequest = "GoldenMinerRankingRequest",
    GoldenMinerExitGameRequest = "GoldenMinerExitGameRequest",
    GoldenMinerEnterStageRequest = "GoldenMinerEnterStageRequest",
    GoldenMinerSellPriceRequest = "GoldenMinerSellPriceRequest",
    GoldenMinerHexSelectRequest = "GoldenMinerHexSelectRequest",
}

function XGoldenMinerControl:OnInit()
    ---@type number[][]
    self._HideTaskMapDrawGroupDir = nil
    ---@type number[][]
    self._FaceGroupDic = nil
    ---@type table<string, number>
    self._ReqCdDir = {}
    
    self._NextUseItemTime = 0
end

function XGoldenMinerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XGoldenMinerControl:RemoveAgencyEvent()
    
end

function XGoldenMinerControl:OnRelease()
    self._HideTaskMapDrawGroupDir = nil
    self._FaceGroupDic = nil
    self._ReqCdDir = nil
end

--region Client - Record 埋点
---@param uiType number XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI
function XGoldenMinerControl:RecordSaveStage(uiType)
    if not self:CheckIsHaveGameStage() then
        return
    end
    local dataDb = self._Model:GetMineDb()
    local stageId, _ = uiType == XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI.UI_STAGE and dataDb:GetCurStageId() or dataDb:GetLastFinishStageId()
    local useCharacterId = self:GetUseCharacterId()
    self:_ClientRecord(uiType, XEnumConst.GOLDEN_MINER.CLIENT_RECORD_ACTION.SAVE_STAGE, useCharacterId, stageId)
end

---@param uiType number XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI
---@param actionType number XEnumConst.GOLDEN_MINER.CLIENT_RECORD_ACTION
function XGoldenMinerControl:RecordPreviewStage(uiType, actionType)
    if not self:CheckIsHaveGameStage() then
        return
    end
    local dataDb = self._Model:GetMineDb()
    local stageId, _ = dataDb:GetLastFinishStageId()
    local useCharacterId = self:GetUseCharacterId()
    local previewStageId = dataDb:GetCurStageId()
    self:_ClientRecord(uiType, actionType, useCharacterId, stageId, previewStageId)
end

---@param uiType number XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI
---@param actionType number XEnumConst.GOLDEN_MINER.CLIENT_RECORD_ACTION
function XGoldenMinerControl:_ClientRecord(uiType, actionType, useChar, stageId, previewStageId)
    local dir = {}
    dir["ui_type"] = uiType
    dir["action_type"] = actionType
    dir["use_char"] = useChar
    dir["stage_id"] = stageId
    dir["preview_stage_id"] = previewStageId or 0
    CS.XRecord.Record(dir, "900001", "GoldenMinerClientRecord")
end
--endregion

--region Game
function XGoldenMinerControl:GetGameControl()
    if not self._GameControl then
        ---@type XGoldenMinerGameControl
        self._GameControl = self:AddSubControl(require("XModule/XGoldenMiner/Game/XGoldenMinerGame"))
    end
    return self._GameControl
end
--endregion

--region Server - Request
local CSTimeManager = CS.XTimerManager
local TicksPerSecond = 10000000
local CDTime = 0.2
---防止PC鼠标多键同按
function XGoldenMinerControl:_CheckIsRecordRequestCD(request, time)
    time = time or CDTime
    if self._ReqCdDir[request] then
        if CSTimeManager.Ticks - self._ReqCdDir[request] < (time * TicksPerSecond) then
            return true
        end
    end
    self._ReqCdDir[request] = CSTimeManager.Ticks
    return false
end

---完成关卡
---@param settlementInfo XGoldenMinerSettlementInfo
function XGoldenMinerControl:RequestGoldenMinerFinishStage(id, settlementInfo, curMapScore, cb, isWin)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerFinishStageRequest) then
        return
    end
    local stageScore = settlementInfo:GetScores()
    local req = {
        Id = id,    --关卡id
        SettlementInfo = settlementInfo:GetReqServerData() --结算后的数据
    }

    XNetwork.Call(METHOD_NAME.GoldenMinerFinishStageRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        if res.Code ~= XCode.Success and res.Code ~= XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)

            --超过限定分数
            if res.Code == XCode.GoldenMinerStageScoresIsMax then
                dataDb:UpdateCurrentPlayStage(0)
                dataDb:CoverItemColumns()
                if dataDb:GetCurStageIsFirst() then
                    dataDb:ResetData()
                end
            end

            if cb then
                cb(false)
            end
            return
        end
        if res.Code == XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)
        end

        dataDb:UpdateCurrentPlayStage(res.MinerDataDb.CurrentPlayStage)
        dataDb:UpdateStageScores(stageScore)
        local nextStageId = dataDb:GetCurrentPlayStage()
        if not XTool.IsNumberValid(nextStageId) then
            dataDb:UpdateCurClearData(curMapScore, isWin)
        end

        dataDb:UpdateData(res.MinerDataDb)

        -- 隐藏关
        if XTool.IsNumberValid(res.NextHideMap) then
            local curStageId, curStageIndex = dataDb:GetCurStageId()
            local stageMapInfo = dataDb:GetStageMapInfo(curStageIndex)
            local data = {}
            data.StageId = curStageId
            data.MapId = res.NextHideMap
            stageMapInfo:UpdateData(data)
        end

        -- 保存当前道具备份
        dataDb:BackupsItemColumns()

        if cb then
            cb(true, XTool.IsNumberValid(res.NextHideMap))
        end
    end)
end

---选择角色进入游戏
function XGoldenMinerControl:RequestGoldenMinerEnterGame(useCharacter, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerEnterGameRequest) then
        return
    end
    local req = {
        UseCharacter = useCharacter,
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerEnterGameRequest, req, function(res)
        self:_SetCharacterUsed(useCharacter)
        self._Model:GetMineDb():UpdateData(res.MinerDataDb)
        if cb then
            cb()
        end
    end)
end

---飞船升级
function XGoldenMinerControl:RequestGoldenMinerShipUpgrade(id, levelIndex, cb)
    local req = {
        Id = id,    --UpgradeId
        LevelIndex = levelIndex, --等级下标（从0开始）
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerShipUpgradeRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        dataDb:UpdateStageScores(res.Scores)    --剩余的积分
        dataDb:UpdateUpgradeStrengthenLevel(id, levelIndex)
        dataDb:UpdateUpgradeStrengthenAlreadyBuy(id, levelIndex)
        if cb then
            cb()
        end
        local type = self:GetCfgUpgradeType(id)
        if type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_REPLACE then
            XUiManager.TipText("GoldenMinerHookReplaceSuccess")
        else
            XUiManager.TipText("UpLevelSuccess")
        end
    end)
end

---商店购买
function XGoldenMinerControl:RequestGoldenMinerShopBuy(shopIndex, itemIndex, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerShopBuyRequest) then
        return
    end
    local req = {
        ShopIndex = shopIndex - 1, --MinerShopDbs的下标
        ItemIndex = itemIndex, --放置的道具栏下标
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerShopBuyRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        dataDb:UpdateStageScores(res.Scores)    --剩余的积分

        local goldenMinerCommodityDb = dataDb:GetMinerShopDbByIndex(shopIndex)
        local itemId = goldenMinerCommodityDb:GetGoldItemId()
        if itemIndex then
            dataDb:UpdateItemColumn(itemId, itemIndex)
        else
            dataDb:UpdateBuffColumn(itemId)
        end
        goldenMinerCommodityDb:UpdateBuyStatus(1)

        if cb then
            cb()
        end
        XUiManager.TipText("BuySuccess")
    end)
end

--请求排行榜数据
function XGoldenMinerControl:RequestGoldenMinerRanking(cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerRankingRequest) then
        return
    end
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerRankingRequest, nil, function(res)
        self:GetRankDb():UpdateData(res, self:GetMainDb())
        if cb then
            cb()
        end
    end)
end

---退出关卡
---@param settlementInfo XGoldenMinerSettlementInfo
function XGoldenMinerControl:RequestGoldenMinerExitGame(stageId, cb, settlementInfo, curMapScore, beforeScore)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerExitGameRequest) then
        return
    end
    local settlementInfoReq
    if not settlementInfo then
        settlementInfoReq = {}
        settlementInfoReq.Scores = curMapScore
        settlementInfoReq.LaunchingClawCount = 0
        settlementInfoReq.CostTime = 0
        settlementInfoReq.MoveCount = 0
        settlementInfoReq.SettlementItems = {}
        settlementInfoReq.GrabDataInfos = {}
        settlementInfoReq.UpdateTaskInfo = {}
    else
        settlementInfoReq = settlementInfo:GetReqServerData()
    end
    local req = {
        StageId = stageId,   --退出的关卡id,关卡外结算传0
        SettlementInfo = settlementInfoReq, --结算后的数据
    }
    local score = curMapScore
    XNetwork.Call(METHOD_NAME.GoldenMinerExitGameRequest, req, function(res)
        if res.Code ~= XCode.Success and res.Code ~= XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)
            score = beforeScore
        end
        if res.Code == XCode.GoldenMinerSaveRankError then
            XUiManager.TipCode(res.Code)
        end

        local dataDb = self._Model:GetMineDb()
        dataDb:UpdateCurClearData(score)
        dataDb:ResetData()
        dataDb:UpdateTotalMaxScores(res.TotalMaxScores)
        dataDb:UpdateTotalMaxScoresHexes(res.TotalMaxScoresHexes)
        dataDb:UpdateTotalMaxScoresCharacter(res.CharacterId)
        if cb then
            cb()
        end
    end)
end

---进入关卡
function XGoldenMinerControl:RequestGoldenMinerEnterStage(stageId, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerEnterStageRequest) then
        return
    end
    local req = {
        StageId = stageId   --进入的关卡id
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerEnterStageRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        dataDb:BackupsItemColumns()
        if cb then
            cb()
        end
    end)
end

function XGoldenMinerControl:RequestGoldenMinerSaveStage(curPlayStageId)
    local dataDb = self._Model:GetMineDb()
    dataDb:ResetCurClearData()
    dataDb:UpdateCurrentPlayStage(curPlayStageId)
    XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
end

---出售道具
function XGoldenMinerControl:RequestGoldenMinerSell(index, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerSellPriceRequest) then
        return
    end
    local req = {
        Index = index   --出售的道具格子Id
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerSellPriceRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        dataDb:UpdateStageScores(res.AfterScore)    --剩余的积分
        dataDb:UseItem(index)
        dataDb:BackupsItemColumns()

        if cb then
            cb()
        end
        XUiManager.TipText("GoldenMinerSellSuccess")
    end)
end

---选择海克斯
function XGoldenMinerControl:RequestGoldenMinerSelectHex(hexId, cb)
    if self:_CheckIsRecordRequestCD(METHOD_NAME.GoldenMinerRankingRequest) then
        return
    end
    local req = {
        Hex = hexId   --出售的道具格子Id
    }
    XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GoldenMinerHexSelectRequest, req, function(res)
        local dataDb = self._Model:GetMineDb()
        dataDb:ClearHexSelects()        --清空可选择海克斯
        dataDb:AddHexRecords(hexId)     --记录已选海克斯
        if cb then
            cb()
        end
    end)
end
--endregion

--region Ui - Control
function XGoldenMinerControl:GetRectSize()
    return self._Model:GetRectSize()
end

function XGoldenMinerControl:SetRectSize(value)
    self._Model:SetRectSize(value)
end

function XGoldenMinerControl:OpenGiveUpGameDialog(title, desc, closeCb, sureCb, specialCloseCb, specialIsSure)
    local XGoldenMinerDialogExData = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerDialogExData")
    ---@type XGoldenMinerDialogExData
    local exData = XGoldenMinerDialogExData.New()
    exData.IsSettleGame = true
    exData.IsCanShowClose = not self._Model:GetMineDb():GetCurStageIsFirst()
    exData.TxtClose = XUiHelper.GetText("GoldenMinerExitBtnName")
    exData.TxtSure = XUiHelper.GetText("GoldenMinerSaveBtnName")
    exData.FuncSpecial = specialCloseCb
    exData.FuncSpecialIsSure = specialIsSure
    XLuaUiManager.Open("UiGoldenMinerDialog", title, desc, closeCb, sureCb, exData)
end

function XGoldenMinerControl:OpenGameUi()
    local dataDb = self:GetMainDb()
    local curStageId = dataDb:GetCurStageId()

    if dataDb:CheckIsBeSelectHex() then
        XLuaUiManager.PopThenOpen("UiGoldenMinerHexSelect")
        return
    end

    if not XTool.IsTableEmpty(dataDb:GetMinerShopDbs()) then
        XLuaUiManager.PopThenOpen("UiGoldenMinerShop")
        return
    end

    self:RequestGoldenMinerEnterStage(curStageId, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
    end)
end

---打开放弃挑战的提示
function XGoldenMinerControl:OpenGiveUpGameTip(isShop)
    local SettleGame = function() self:_GiveUpGame() end
    local SaveGame = function()
        if isShop then
            self:RecordSaveStage(XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI.UI_SHOP)
        end
        self:RequestGoldenMinerSaveStage(0)
    end
    self:OpenGiveUpGameDialog(XUiHelper.GetText("GoldenMinerGiveUpGameTitle"),
            XUiHelper.GetText("GoldenMinerGiveUpGameContent"),
            nil,
            SaveGame,
            SettleGame,
            false)
end

function XGoldenMinerControl:_GiveUpGame()
    self:RequestGoldenMinerExitGame(0, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
    end, nil, self:GetMainDb():GetStageScores(), self:GetMainDb():GetStageScores())
end

function XGoldenMinerControl:ContinueGame()
    local dataDb = self:GetMainDb()

    dataDb:CoverItemColumns()
    if XTool.IsNumberValid(dataDb:GetCurrentPlayStage()) then
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
        return
    end

    self:OpenGameUi()
end

function XGoldenMinerControl:HandleActivityEndTime()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
end

function XGoldenMinerControl:CheckIsHaveGameStage()
    local dataDb = self._Model:GetMineDb()
    return dataDb:CheckIsInStage()
end
--endregion

--region Ui - RedPoint
function XGoldenMinerControl:CheckHaveNewRole()
    local characterList = self._Model:GetCharacterCfgList()
    for _, character in ipairs(characterList) do
        if self:_CheckIsNewRole(character.Id) then
            return true
        end
    end
    return false
end

function XGoldenMinerControl:_CheckIsNewRole(characterId)
    local isNewRole = self._Model:GetCacheData("IsNewRole"..characterId)
    return self:IsCharacterUnLock(characterId) and not isNewRole
end

function XGoldenMinerControl:ClearAllNewRoleTag()
    local characterList = self._Model:GetCharacterCfgList()
    for _, character in ipairs(characterList) do
        self:ClearNewRoleTag(character.Id)
    end
end

function XGoldenMinerControl:ClearNewRoleTag(characterId)
    if not self:_CheckIsNewRole(characterId) then
        return
    end
    self._Model:SetCacheData("IsNewRole"..characterId, true)
end
--endregion

--region Data - Cache
---当检测到玩家有因为游戏进程退出，导致未完成的游玩挑战时，再次打开主界面会弹出提示框（每次登录只会主动弹出一次）
function XGoldenMinerControl:CheckIsAutoInGameTips()
    if not self._Model:GetIsCheckAutoInGameTips() then
        return false
    end
    return self:CheckIsHaveGameStage()
end

function XGoldenMinerControl:SetIsAutoInGameTips(isCheck)
    self._Model:SetIsCheckAutoInGameTips(isCheck)
end

function XGoldenMinerControl:CatchCurCharacterId(characterId)
    self._Model:SetCacheData("_CurCharacterId", characterId)
end

function XGoldenMinerControl:CheckFirstOpenHelp()
    local key = "FirstOpenHelp"
    local value = self._Model:GetCacheData(key)
    if not value then
        self._Model:SetCacheData(key, true)
        return true
    end
    return false
end
--endregion

--region Data - Activity
function XGoldenMinerControl:GetMainDb()
    return self._Model:GetMineDb()
end

function XGoldenMinerControl:GetCurActivityEndTime()
    return self._Model:GetCurActivityEndTime()
end

function XGoldenMinerControl:GetCurActivityMaxItemColumnCount()
    local id = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(id) then
        return self:GetCfgActivityMaxItemColumnCount(id)
    end
    return 0
end
--endregion

--region Data - Character
---角色是否解锁
function XGoldenMinerControl:IsCharacterUnLock(characterId)
    local condition = self._Model:GetCharacterCfgCondition(characterId)
    if not XTool.IsNumberValid(condition) then
        return true
    end
    return self._Model:GetMineDb():IsCharacterUnlock(characterId)
end

function XGoldenMinerControl:GetCharacterIdList()
    local useCharacterId = self:GetUseCharacterId()
    local characterIdList = {}
    for _, cfg in ipairs(self._Model:GetCharacterCfgList()) do
        table.insert(characterIdList, cfg.Id)
    end
    table.sort(characterIdList, function(idA, idB)
        --当前选择的角色Id
        if idA == useCharacterId then
            return true
        end
        if idB == useCharacterId then
            return false
        end

        --已解锁
        local isUnlockA = self:IsCharacterUnLock(idA)
        local isUnlockB = self:IsCharacterUnLock(idB)
        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end

        --已使用
        local isUsedA = self:IsCharacterUsed(idA)
        local isUsedB = self:IsCharacterUsed(idB)
        if isUsedA ~= isUsedB then
            return isUsedB
        end

        return idA < idB
    end)

    return characterIdList
end

function XGoldenMinerControl:CatchCurCharacterId(characterId)
    self._Model:SetCacheData("_CurCharacterId", characterId)
end

function XGoldenMinerControl:GetUseCharacterId()
    local characterId = self._Model:GetMineDb():GetCurPlayCharacterId()
    if XTool.IsNumberValid(characterId) and self:IsCharacterUnLock(characterId) then
        return characterId
    end

    characterId = self._Model:GetCacheData("_CurCharacterId")
    if XTool.IsNumberValid(characterId) and self:IsCharacterUnLock(characterId) then
        return characterId
    end

    local characterConfig = self._Model:GetCharacterCfgList()
    for _, cfg in pairs(characterConfig) do
        if self:IsCharacterUnLock(cfg.Id) then
            characterId = cfg.Id
            break
        end
    end
    self:CatchCurCharacterId(characterId)

    return characterId
end

function XGoldenMinerControl:IsCharacterUsed(characterId)
    if not self:IsCharacterUnLock(characterId) then
        return true
    end
    return self._Model:GetCacheData("IsCharacterUsed"..characterId)
end

function XGoldenMinerControl:_SetCharacterUsed(characterId)
    if self:IsCharacterUsed(characterId) then
        return
    end
    self._Model:SetCacheData("IsCharacterUsed"..characterId, true)
end
--endregion

--region Data - Task
function XGoldenMinerControl:GetTaskDataList(taskGroupId)
    return self._Model:GetTaskDataList(taskGroupId)
end

function XGoldenMinerControl:CheckHaveTaskCanRecv()
    return self._Model:CheckHaveTaskCanRecv()
end

function XGoldenMinerControl:CheckTaskCanRecvByTaskId(taskGroupId)
    return self._Model:CheckTaskCanRecvByTaskId(taskGroupId)
end
--endregion

--region Data - Rank
function XGoldenMinerControl:GetRankDb()
    return self._Model:GetRankDb()
end
--endregion

--region Data - Score
function XGoldenMinerControl:GetTimeScore(time)
    local score = 0
    local countTime = math.ceil(time)
    if countTime <= 0 then
        return score
    end
    local timeScoreCfgList = self._Model:GetTimeScoreCfgList()
    for index, timeScore in ipairs(timeScoreCfgList) do
        if countTime <= 0 then
            return score
        end
        local countMaxTime = timeScore.LastTimeMax
        local countPerPoint = timeScore.Point
        if index <= 1 then
            if countTime > countMaxTime then
                score = score + countPerPoint * countMaxTime
            else
                score = score + countPerPoint * countTime
            end
            countTime = countTime - countMaxTime
        else
            local needCountTime = countMaxTime - timeScoreCfgList[index-1].LastTimeMax
            if countTime > needCountTime then
                score = score + countPerPoint * needCountTime
            else
                score = score + countPerPoint * countTime
            end
            countTime = countTime - needCountTime
        end
    end
    return score
end
--endregion

--region Data - Buff
---获得当前拥有的所有buffId
function XGoldenMinerControl:GetShowOwnBuffIdList()
    local ownBuffIdList = {}
    local dataDb = self._Model:GetMineDb()
    local upgradeList = dataDb:GetAllUpgradeStrengthenList()
    local hexList = dataDb:GetSelectedHexList()
    local buffIdList
    local buffId

    --角色自带buff
    local curSelectCharacterId = dataDb:GetCurPlayCharacterId()
    if XTool.IsNumberValid(curSelectCharacterId) then
        buffIdList = self:GetCfgCharacterBuffIds(curSelectCharacterId)
        for _, Id in ipairs(buffIdList) do
            self:_InsertBuffListByCheck(ownBuffIdList, Id)
        end
    end

    --海克斯
    for _, hexId in ipairs(hexList) do
        for _, hexBuffId in ipairs(self:GetCfgHexBuffId(hexId)) do
            self:_InsertBuffListByCheck(ownBuffIdList, hexBuffId)
        end
    end
    
    --强化升级项
    for _, strengthenDb in ipairs(upgradeList) do
        buffId = strengthenDb:GetBuffId()
        self:_InsertBuffListByCheck(ownBuffIdList, buffId)
    end

    --购买的道具类型为2的buff
    local buffColumns = dataDb:GetBuffColumns()
    for _, buffColumn in pairs(buffColumns) do
        self:_InsertBuffListByCheck(ownBuffIdList, buffColumn:GetBuffId())
    end

    return ownBuffIdList
end

---获得当前拥有的所有buff，叠加相同类型的buff
function XGoldenMinerControl:GetCurInitBuffIdList()
    local dataDb = self._Model:GetMineDb()
    local upgradeList = dataDb:GetAllUpgradeStrengthenList()
    local buffIdList = {}

    --强化升级项
    for _, strengthenDb in ipairs(upgradeList) do
        buffIdList[#buffIdList + 1] = strengthenDb:GetBuffId()
    end

    --角色自带buff
    local curSelectCharacterId = dataDb:GetCurPlayCharacterId()
    if XTool.IsNumberValid(curSelectCharacterId) then
        local characterBuffIdList = self:GetCfgCharacterBuffIds(curSelectCharacterId)
        for _, buffId in ipairs(characterBuffIdList) do
            buffIdList[#buffIdList + 1] = buffId
        end
    end

    --购买的道具类型为2的buff
    local buffColumns = dataDb:GetBuffColumns()
    for _, buffColumn in pairs(buffColumns) do
        buffIdList[#buffIdList + 1] = buffColumn:GetBuffId()
    end
    
    --海克斯
    local hexList = dataDb:GetSelectedHexList()
    for _, hexId in pairs(hexList) do
        for _, hexBuffId in ipairs(self:GetCfgHexBuffId(hexId)) do
            buffIdList[#buffIdList + 1] = hexBuffId
        end
    end
    
    --Debug
    if not XTool.IsTableEmpty(self._Model.DebugInitBuffList) then
        if not XMain.IsWindowsEditor then
            return
        end
        for _, buffId in pairs(self._Model.DebugInitBuffList) do
            buffIdList[#buffIdList + 1] = buffId
        end
        XLog.Warning("黄金矿工Debug:Debug下添加初始化Buff:", self._Model.DebugInitBuffList)
        XLog.Warning("若不需要请矿工Debug状态doLua XMVCA.XGoldenMiner:DebugInitBuff({})")
    end

    return buffIdList
end

--获得当前拥有的所有buff，叠加相同类型的buff
function XGoldenMinerControl:GetOwnBuffDic()
    local ownBuffDic = {}
    local dataDb = self._Model:GetMineDb()
    local upgradeList = dataDb:GetAllUpgradeStrengthenList()
    local hexList = dataDb:GetSelectedHexList()
    local buffIdList
    local buffId

    --强化升级项
    for _, strengthenDb in ipairs(upgradeList) do
        buffId = strengthenDb:GetBuffId()
        self:_AddBuff(ownBuffDic, buffId)
    end

    --角色自带buff
    local curSelectCharacterId = dataDb:GetCurPlayCharacterId()
    if XTool.IsNumberValid(curSelectCharacterId) then
        buffIdList = self:GetCfgCharacterBuffIds(curSelectCharacterId)
        for _, Id in ipairs(buffIdList) do
            self:_AddBuff(ownBuffDic, Id)
        end
    end

    --海克斯
    for _, hexId in ipairs(hexList) do
        for _, hexBuffId in ipairs(self:GetCfgHexBuffId(hexId)) do
            self:_AddBuff(ownBuffDic, hexBuffId)
        end
    end

    --购买的道具类型为2的buff
    local buffColumns = dataDb:GetBuffColumns()
    for _, buffColumn in pairs(buffColumns) do
        self:_AddBuff(ownBuffDic, buffColumn:GetBuffId())
    end

    return ownBuffDic
end

function XGoldenMinerControl:_AddBuff(ownBuffDic, buffId)
    if not XTool.IsNumberValid(buffId) then
        return
    end

    local buffType = self:GetCfgBuffType(buffId)
    if buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.INIT_ITEM or
            buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.INIT_SCORES
    then
        return
    end

    local paramsTemp = {}
    local params = self:GetCfgBuffParams(buffId)
    --不同类型的抓取物分数提升叠加buff
    if buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.STONE_SCORE then
        if not ownBuffDic[buffType] then
            ownBuffDic[buffType] = {}
        end

        local goldenMinerStoneType = params[1]
        if not ownBuffDic[buffType][goldenMinerStoneType] then
            ownBuffDic[buffType][goldenMinerStoneType] = params
            return
        end

        for i, param in ipairs(ownBuffDic[buffType][goldenMinerStoneType]) do
            --参数1是GoldenMinerStoneType
            if i ~= 1 then
                paramsTemp[i] = param + (params[i] or 0)
            end
        end
        ownBuffDic[buffType][goldenMinerStoneType] = paramsTemp
        return
    end

    if buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.CORD_MODE
            or buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.ROLE_HOOK
    then
        ownBuffDic[buffType] = params
        return
    end

    if not ownBuffDic[buffType] then
        ownBuffDic[buffType] = params
        return
    end
    for i, param in ipairs(ownBuffDic[buffType]) do
        paramsTemp[i] = param + (params[i] or 0)
    end
    ownBuffDic[buffType] = paramsTemp
end

function XGoldenMinerControl:_InsertBuffListByCheck(buffIdList, buffId)
    local buffIcon = XTool.IsNumberValid(buffId) and self:GetCfgBuffIcon(buffId)
    if not string.IsNilOrEmpty(buffIcon) and not table.indexof(buffIdList, buffId) then
        table.insert(buffIdList, buffId)
    end
end
--endregion

--region Data - BuffDisplay
---@class XGoldenMinerDisplayData
---@field Icon string
---@field Desc string

function XGoldenMinerControl:_GetDisplayData(icon, desc)
    ---@type XGoldenMinerDisplayData
    local displayData = {}
    displayData.Icon = icon
    displayData.Desc = desc
    return displayData
end

---@return number[], XGoldenMinerDisplayData
function XGoldenMinerControl:GetDisplayShipList()
    local result = {}
    local characterId = self:GetMainDb():GetCurPlayCharacterId()
    local buffList = self:GetCfgCharacterBuffIds(characterId)
    local buffIcon = buffList[1] and self:GetCfgBuffIcon(buffList[1])
    local characterDisplayData = self:_GetDisplayData(buffIcon, self:GetCfgCharacterSkillDesc(characterId))

    local displayUpgradeList = self:GetMainDb():GetUpgradeStrengthens()
    for _, upgradeData in pairs(displayUpgradeList) do
        local buffId = self:GetCfgUpgradeCfgBuffId(upgradeData:GetStrengthenId(), upgradeData:GetClientLevelIndex())
        if self:_CheckIsDisplayBuff(buffId, XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.SHIP) then
            result[#result + 1] = buffId
        end
    end

    local displayHexList = self:GetMainDb():GetSelectedHexList()
    for _, hexId in ipairs(displayHexList) do
        for _, hexBuffId in ipairs(self:GetCfgHexBuffId(hexId)) do
            if self:_CheckIsDisplayBuff(hexBuffId, XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.SHIP) then
                result[#result + 1] = hexBuffId
            end
        end
    end
    return self:_SortDisplayBuff(result), characterDisplayData
end

---@return XGoldenMinerDisplayData[]
function XGoldenMinerControl:GetDisplayItemList()
    local result = {}
    local displayItemList = self:GetMainDb():GetItemColumns()
    for _, item in pairs(displayItemList) do
        if self:_CheckIsDisplayBuff(item:GetBuffId(), XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.ITEM) then
            result[#result + 1] = self:_GetDisplayData(self:GetCfgItemIcon(item:GetItemId()), self:GetCfgBuffDesc(item:GetBuffId()))
        end
    end
    return result
end

---@return number[]
function XGoldenMinerControl:GetDisplayBuffList()
    local result = {}
    local displayBuffList = self:GetMainDb():GetBuffColumns()
    for _, buff in pairs(displayBuffList) do
        if self:_CheckIsDisplayBuff(buff:GetBuffId(), XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.BUFF) then
            result[#result + 1] = buff:GetBuffId()
        end
    end
    return self:_SortDisplayBuff(result)
end

function XGoldenMinerControl:_SortDisplayBuff(result)
    if XTool.IsTableEmpty(result) then
        return result
    end
    table.sort(result, function(buffIdA, buffIdB)
        local priorityA = self:GetCfgBuffDisplayPriority(buffIdA)
        local priorityB = self:GetCfgBuffDisplayPriority(buffIdB)
        return priorityA < priorityB
    end)
    return result
end

function XGoldenMinerControl:_CheckIsDisplayBuff(buffId, displayType)
    return XTool.IsNumberValid(buffId)
            and not string.IsNilOrEmpty(self:GetCfgBuffIcon(buffId))
            and self:GetCfgBuffDisplayType(buffId) == displayType
end
--endregion

--region Data - Shop
---获得当前临时buff
function XGoldenMinerControl:GetShowTempBuffIdList()
    local ownBuffIdList = {}
    local dataDb = self._Model:GetMineDb()

    --购买的道具类型为2的buff
    local buffColumns = dataDb:GetBuffColumns()
    for _, buffColumn in pairs(buffColumns) do
        self:_InsertBuffListByCheck(ownBuffIdList, buffColumn:GetBuffId())
    end

    return ownBuffIdList
end

---获得当前飞船拥有的所有buffId
function XGoldenMinerControl:GetShowShipBuffIdList()
    local shipBuffIdList = {}
    local dataDb = self._Model:GetMineDb()
    local upgradeList = dataDb:GetAllUpgradeStrengthenList()
    local buffIdList
    local buffId

    --角色自带buff
    local curSelectCharacterId = dataDb:GetCurPlayCharacterId()
    if XTool.IsNumberValid(curSelectCharacterId) then
        buffIdList = self:GetCfgCharacterBuffIds(curSelectCharacterId)
        for _, id in ipairs(buffIdList) do
            self:_InsertBuffListByCheck(shipBuffIdList, id)
        end
    end

    --强化升级项
    local shipBuffList = {}
    for _, strengthenDb in ipairs(upgradeList) do
        buffId = strengthenDb:GetBuffId()
        shipBuffList[#shipBuffList + 1] = buffId
    end
    table.sort(shipBuffList, function(a, b)
        local priorityA = self:GetCfgBuffDisplayPriority(a)
        local priorityB = self:GetCfgBuffDisplayPriority(b)
        return priorityA < priorityB
    end)
    for _, id in ipairs(shipBuffList) do
        self:_InsertBuffListByCheck(shipBuffIdList, id)
    end

    return shipBuffIdList
end
--endregion

--region Data - Item
function XGoldenMinerControl:CheckUseItemIsInCD(itemIndex)
    if self._NextUseItemTime > XTime.GetServerNowTimestamp() then
        -- XUiManager.TipErrorWithKey("GoldenMinerUseItemCd") --2.0不提示冷却
        return true
    end

    local dataDb = self._Model:GetMineDb()
    if not dataDb:IsUseItem(itemIndex) then
        return true
    end

    self._NextUseItemTime = XTime.GetServerNowTimestamp() + self:GetClientUseItemCd()
    return false
end
--endregion

--region Cfg - ClientParam
function XGoldenMinerControl:GetClientHelpKey()
    return self._Model:GetClientCfgValue("HelpKey", 1)
end

function XGoldenMinerControl:GetClientScoreIcon()
    return self._Model:GetClientCfgValue("ScoreIcon", 1)
end

function XGoldenMinerControl:GetClientUnlockRoleItemId()
    return self._Model:GetClientCfgNumberValue("UnlockRoleItemId", 1)
end

function XGoldenMinerControl:GetClientUseItemCd()
    return self._Model:GetClientCfgNumberValue("UseItemCd", 1)
end

---临近结束的时间（单位：秒）
function XGoldenMinerControl:GetClientGameNearEndTime()
    return self._Model:GetClientCfgNumberValue("GameNearEndTime", 1)
end

function XGoldenMinerControl:GetClientGameStopCountdown()
    return self._Model:GetClientCfgNumberValue("GameStopCountdown", 1)
end

function XGoldenMinerControl:GetClientRoleGrapSuccessTime()
    return self._Model:GetClientCfgNumberValue("RoleGrapSuccessTime", 1)
end

function XGoldenMinerControl:GetClientUseItemSpeed()
    return self._Model:GetClientCfgNumberValue("UseItemSpeed", 1)
end

function XGoldenMinerControl:GetClientAddScoreSound()
    return self._Model:GetClientCfgNumberValue("AddScoreSound", 1)
end

function XGoldenMinerControl:GetClientStretchSound()
    return self._Model:GetClientCfgNumberValue("StretchSound", 1)
end

function XGoldenMinerControl:GetClientShortenSound()
    return self._Model:GetClientCfgNumberValue("ShortenSound", 1)
end

function XGoldenMinerControl:GetClientTipAnimTime()
    return self._Model:GetClientCfgNumberValue("TipAnimTime", 1)
end

function XGoldenMinerControl:GetClientTipAnimMoveLength()
    return self._Model:GetClientCfgNumberValue("TipAnimMoveLength", 1)
end

function XGoldenMinerControl:GetClientFaceEmojiShowTime()
    return self._Model:GetClientCfgNumberValue("FaceEmojiShowTime", 1)
end

---@return UnityEngine.Color
function XGoldenMinerControl:GetClientShopScoreChangeColor(isAdd)
    local colorHexCode = self._Model:GetClientCfgValue("ShopScoreChangeColorCode", isAdd and 1 or 2)
    return XUiHelper.Hexcolor2Color(colorHexCode)
end

---@return UnityEngine.Color
function XGoldenMinerControl:GetClientShopItemPriceColor(isCanBuy)
    local colorHexCode = self._Model:GetClientCfgValue("ShopItemPriceColor", isCanBuy and 1 or 2)
    return XUiHelper.Hexcolor2Color(colorHexCode)
end

function XGoldenMinerControl:GetClientMouseGrabOffset()
    return self._Model:GetClientCfgNumberValue("MouseGrabOffset", 1)
end

function XGoldenMinerControl:GetClientNewMaxScoreSettleEmoji()
    return self._Model:GetClientCfgValue("NewMaxScoreSettleEmoji", 1)
end

function XGoldenMinerControl:GetClientSettleEmoji(isWin)
    return self._Model:GetClientCfgValue("SettleEmoji", isWin and 1 or 2)
end

function XGoldenMinerControl:GetClientTxtDisplayMainTitle(sortType)
    return self._Model:GetClientCfgValue("TxtDisplayMainTitle", sortType)
end

function XGoldenMinerControl:GetClientTxtDisplaySecondTitle(sortType)
    return self._Model:GetClientCfgValue("TxtDisplaySecondTitle", sortType)
end

function XGoldenMinerControl:GetClientGameScoreColorCode(isWin)
    return self._Model:GetClientCfgValue("GameScoreColorCode", isWin and 2 or 1)
end

---@return UnityEngine.Color
function XGoldenMinerControl:GetClientNewMaxScoreColor()
    local colorHexCode = self._Model:GetClientCfgValue("NewMaxScoreColor", 1)
    return XUiHelper.Hexcolor2Color(colorHexCode)
end

function XGoldenMinerControl:GetClientNewMaxScoreSettleBg(index)
    return self._Model:GetClientCfgValue("NewMaxScoreSettleBg", index)
end

function XGoldenMinerControl:GetClientShopUpgradeBuyTxt(isReplace)
    return self._Model:GetClientCfgValue("ShopUpgradeBuyTxt", isReplace and 2 or 1)
end

function XGoldenMinerControl:GetClientGameItemBgIcon(isHaveItem)
    return self._Model:GetClientCfgValue("GameItemBgIcon", isHaveItem and 2 or 1)
end

function XGoldenMinerControl:GetClientEffectCreateRecord()
    return self._Model:GetClientCfgValue("EffectCreateRecord", 1)
end

function XGoldenMinerControl:GetClientReportShowHideTaskCount()
    return self._Model:GetClientCfgNumberValue("ReportShowHideTaskCount", 1)
end

function XGoldenMinerControl:GetClientBtnShootIconUrl(isQte)
    return self._Model:GetClientCfgValue("BtnShootIconUrl", isQte and 2 or 1)
end

function XGoldenMinerControl:GetClientGameWallExAreaValue(isWidth)
    return self._Model:GetClientCfgNumberValue("GameWallExArea", isWidth and 1 or 2)
end

function XGoldenMinerControl:GetClientMainShowCharByIndex(index)
    return self._Model:GetClientCfgNumberValue("MainShowCharList", index)
end

function XGoldenMinerControl:GetClientScanLineProgressImgByPro(progress)
    return self._Model:GetClientCfgValue("ScanLineProgressImg", progress + 1)
end
--endregion

--region Cfg - Activity
function XGoldenMinerControl:GetCfgActivityMaxItemColumnCount(id)
    local cfg = self._Model:GetActivityCfg(id)
    return cfg and cfg.MaxItemColumnCount
end
--endregion

--region Cfg - Task
function XGoldenMinerControl:GetCfgTaskGroupList()
    return self._Model:GetTaskGroupCfgList()
end
--endregion

--region Cfg - Character
function XGoldenMinerControl:GetCfgCharacterHeadIcon(characterId)
    local cfg = self._Model:GetCharacterCfg(characterId)
    return cfg and cfg.HeadPath
end

function XGoldenMinerControl:GetCfgCharacterCondition(characterId)
    local cfg = self._Model:GetCharacterCfg(characterId)
    return cfg and cfg.Condition
end

function XGoldenMinerControl:GetCfgCharacterBuffIds(characterId)
    local cfg = self._Model:GetCharacterCfg(characterId)
    return cfg and cfg.BuffIds
end

function XGoldenMinerControl:GetCfgCharacterName(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.Name
end

function XGoldenMinerControl:GetCfgCharacterModelId(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.ModelId
end

function XGoldenMinerControl:GetCfgCharacterInfo(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.Info
end

function XGoldenMinerControl:GetCfgCharacterSkillName(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.SkillName
end

function XGoldenMinerControl:GetCfgCharacterSkillDesc(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.SkillDesc
end

function XGoldenMinerControl:GetCfgCharacterEnName(id)
    local cfg = self._Model:GetCharacterCfg(id)
    return cfg and cfg.EnName
end
--endregion

--region Cfg - Item
function XGoldenMinerControl:GetCfgItemName(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.Name
end

function XGoldenMinerControl:GetCfgItemDescribe(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.Describe
end

function XGoldenMinerControl:GetCfgItemType(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.ItemType
end

function XGoldenMinerControl:GetCfgItemIcon(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.Icon
end

function XGoldenMinerControl:GetCfgItemBuffId(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.BuffId
end

function XGoldenMinerControl:GetCfgItemUseSoundId(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.UseSoundId
end

function XGoldenMinerControl:GetCfgItemUseFaceId(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.UseFaceId
end

function XGoldenMinerControl:GetCfgItemSellPrice(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.SellPrice
end

function XGoldenMinerControl:GetCfgItemTipsType(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.TipsType
end

function XGoldenMinerControl:GetCfgItemTipsTxt(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.TipsTxt
end
--endregion

--region Cfg - Map
function XGoldenMinerControl:GetCfgMapTime(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.Time
end

function XGoldenMinerControl:GetCfgMapTargetScore(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.TargetScore
end

function XGoldenMinerControl:GetCfgMapPreviewPic(id)
    local cfg = self._Model:GetMapCfg(id)
    return cfg and cfg.PreviewPic
end
--endregion

--region Cfg - Buff
function XGoldenMinerControl:GetCfgBuffType(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.BuffType
end

function XGoldenMinerControl:GetCfgBuffParams(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.Params
end

function XGoldenMinerControl:GetCfgBuffTimeType(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.TimeType
end

function XGoldenMinerControl:GetCfgBuffTimeTypeParam(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.TimeTypeParam
end

function XGoldenMinerControl:GetCfgBuffName(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.Name
end

function XGoldenMinerControl:GetCfgBuffIcon(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.Icon
end

function XGoldenMinerControl:GetCfgBuffDesc(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.Desc
end

function XGoldenMinerControl:GetCfgBuffDisplayType(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.DisplayType
end

function XGoldenMinerControl:GetCfgBuffDisplayPriority(id)
    local cfg = self._Model:GetBuffCfg(id)
    return cfg and cfg.DisplayPriority
end
--endregion

--region Cfg - Upgrade
function XGoldenMinerControl:GetCfgUpgradeType(upgradeId)
    local cfg = self._Model:GetUpgradeCfg(upgradeId)
    return cfg and cfg.Type
end

function XGoldenMinerControl:_GetCfgUpgradeLocalIds(upgradeId)
    local cfg = self._Model:GetUpgradeCfg(upgradeId)
    return cfg and cfg.LocalIds
end

function XGoldenMinerControl:GetCfgUpgradeLocalIdIndex(id, localId)
    local upgradeLocalIdList = self:_GetCfgUpgradeLocalIds(id)
    for i, upgradeLocalId in ipairs(upgradeLocalIdList) do
        if upgradeLocalId == localId then
            return i
        end
    end
end

function XGoldenMinerControl:_GetCfgUpgradeIsOpen(id)
    local cfg = self._Model:GetUpgradeCfg(id)
    return cfg and XTool.IsNumberValid(cfg.IsOpen)
end

function XGoldenMinerControl:GetCfgUpgradeCfgCosts(id, index)
    return self._Model:GetUpgradeCfgCosts(id, index)
end

function XGoldenMinerControl:GetCfgUpgradeCfgBuffId(id, index)
    return self._Model:GetUpgradeCfgBuffId(id, index)
end

---获取升级数据字典(拆分钩子和其他)
function XGoldenMinerControl:GetUpgradeShowDataDir()
    local configs = self._Model:GetUpgradeCfgList()
    local hookDir = {}
    local upDir = {}
    for _, config in pairs(configs) do
        if XTool.IsNumberValid(config.IsOpen) then
            for index, id in ipairs(config.LocalIds) do
                if XTool.IsNumberValid(config.Conditions[index])
                        and not XConditionManager.CheckCondition(config.Conditions[index]) then
                    goto continue
                end
                if config.Type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.LEVEL then
                    upDir[#upDir + 1] = id
                else
                    hookDir[#hookDir + 1] = id
                end
                ::continue::
            end
        end
    end
    return hookDir, upDir
end
--endregion

--region Cfg - UpgradeLocal
function XGoldenMinerControl:GetCfgUpgradeIdByLocalId(upgradeLocalId)
    if not XTool.IsNumberValid(upgradeLocalId) then
        return
    end

    for _, upgrade in pairs(self._Model:GetUpgradeCfgList()) do
        if self:_GetCfgUpgradeIsOpen(upgrade.Id) then
            local upgradeLocalIds = self:_GetCfgUpgradeLocalIds(upgrade.Id)
            for _, upgradeLocalIdTemp in ipairs(upgradeLocalIds) do
                if upgradeLocalIdTemp == upgradeLocalId then
                    return upgrade.Id
                end
            end
        end
    end
end

function XGoldenMinerControl:GetCfgUpgradeLocalName(id)
    local cfg = self._Model:GetUpgradeLocalCfg(id)
    return cfg and cfg.Name
end

function XGoldenMinerControl:GetCfgUpgradeLocalDescribe(id)
    local cfg = self._Model:GetUpgradeLocalCfg(id)
    return cfg and cfg.Describe
end

function XGoldenMinerControl:GetCfgUpgradeLocalIcon(id)
    local cfg = self._Model:GetUpgradeLocalCfg(id)
    return cfg and cfg.Icon
end
--endregion

--region Cfg - HookType
function XGoldenMinerControl:GetCfgHookButtonTip(type)
    local cfg = self._Model:GetHookCfg(type)
    return cfg and cfg.ButtonTip
end

function XGoldenMinerControl:GetCfgHookShipTip(type)
    local cfg = self._Model:GetHookCfg(type)
    return cfg and cfg.ShipTip
end
--endregion

--region Cfg - StoneType
function XGoldenMinerControl:GetCfgStoneTypeIcon(type)
    local cfg = self._Model:GetStoneTypeCfg(type)
    return cfg and cfg.Icon
end

function XGoldenMinerControl:GetCfgStoneTypeGrabFaceId(type)
    local cfg = self._Model:GetStoneTypeCfg(type)
    return cfg and cfg.GrabFaceId
end
--endregion

--region Cfg - Face
function XGoldenMinerControl:_InitFaceGroupDic()
    self._FaceGroupDic = {}
    local configs = self._Model:GetFaceCfgList()
    for id, v in pairs(configs) do
        local faceGroup = v.FaceGroup
        if XTool.IsNumberValid(faceGroup) then
            if not self._FaceGroupDic [faceGroup] then
                self._FaceGroupDic [faceGroup] = {}
            end
            table.insert(self._FaceGroupDic [faceGroup], id)
        end
    end

    for _, idList in pairs(self._FaceGroupDic) do
        table.sort(idList, function(idA, idB)
            local weightA = self:_GetCfgFaceWeight(idA)
            local weightB = self:_GetCfgFaceWeight(idB)
            if weightA ~= weightB then
                return weightA > weightB
            end

            local scoreA = self:_GetCfgFaceScore(idA)
            local scoreB = self:_GetCfgFaceScore(idB)
            if scoreA ~= scoreB then
                return scoreA > scoreB
            end
            return idA < idB
        end)
    end
end

function XGoldenMinerControl:GetFaceIdByScore(faceId, score)
    local faceGroupId = self:GetCfgFaceGroup(faceId)
    if not XTool.IsNumberValid(faceGroupId) then
        return faceId
    end
    return self:GetFaceIdByGroup(faceGroupId, score)
end

---获得表情图片
---@param value number groupId为1时传重量；groupId为2、3时传得分
function XGoldenMinerControl:GetFaceIdByGroup(groupId, value)
    if not self._FaceGroupDic then
        self:_InitFaceGroupDic()
    end
    local faceIdList = self._FaceGroupDic[groupId]
    local weight
    local score
    for _, faceId in ipairs(faceIdList) do
        weight = self:_GetCfgFaceWeight(faceId)
        score = self:_GetCfgFaceScore(faceId)
        if (XTool.IsNumberValid(weight) and value >= weight) or
                (XTool.IsNumberValid(score) and value >= score) then
            return faceId
        end
    end

    return faceIdList[#faceIdList]
end

function XGoldenMinerControl:GetCfgFaceImage(id)
    local cfg = self._Model:GetFaceCfg(id)
    return cfg and cfg.FaceImage
end

function XGoldenMinerControl:GetCfgFaceGroup(id)
    local cfg = self._Model:GetFaceCfg(id)
    return cfg and cfg.FaceGroup
end

function XGoldenMinerControl:_GetCfgFaceWeight(id)
    local cfg = self._Model:GetFaceCfg(id)
    return cfg and cfg.Weight
end

function XGoldenMinerControl:_GetCfgFaceScore(id)
    local cfg = self._Model:GetFaceCfg(id)
    return cfg and cfg.Score
end
--endregion

--region Cfg - HideTask
function XGoldenMinerControl:GetCfgHideTaskMapDrawGroup(mapId)
    if XTool.IsTableEmpty(self._HideTaskMapDrawGroupDir) then
        self._HideTaskMapDrawGroupDir = {}
        for _, cfg in ipairs(self._Model:GetHideTaskMapDrawGroupCfgList()) do
            if not self._HideTaskMapDrawGroupDir[cfg.MapId] then
                self._HideTaskMapDrawGroupDir[cfg.MapId] = {}
            end
            self._HideTaskMapDrawGroupDir[cfg.MapId][#self._HideTaskMapDrawGroupDir[cfg.MapId] + 1] = cfg.Id
        end
    end
    return self._HideTaskMapDrawGroupDir[mapId]
end

function XGoldenMinerControl:GetCfgHideTaskMapDrawGroupStoneIdIndex(id)
    local cfg = self._Model:GetHideTaskMapDrawGroupCfg(id)
    return cfg and cfg.StoneIdIndex
end

---@return boolean
function XGoldenMinerControl:GetCfgHideTaskMapDrawGroupIsStay(id)
    local cfg = self._Model:GetHideTaskMapDrawGroupCfg(id)
    return cfg and XTool.IsNumberValid(cfg.IsStay)
end
--endregion

--region Cfg - Hex
function XGoldenMinerControl:GetCfgHexName(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.Name
end

function XGoldenMinerControl:GetCfgHexIcon(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.Icon
end

function XGoldenMinerControl:GetCfgHexDesc(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.Desc
end

function XGoldenMinerControl:GetCfgHexBuffId(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.BuffId
end
--endregion

return XGoldenMinerControl
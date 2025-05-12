local XGoldenMinerItemData = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerItemData")
local XGoldenMinerStrengthenData = require("XModule/XGoldenMiner/Data/Server/XGoldenMinerStrengthenData")
local XGoldenMinerShopItemData = require("XModule/XGoldenMiner/Data/Server/XGoldenMinerShopItemData")
local XGoldenMinerStageMapInfo = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerStageMapInfo")
local XGoldenMinerHideTaskInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerHideTaskInfo")

--黄金矿工数据
---@class XGoldenMinerDataDb
local XGoldenMinerDataDb = XClass(nil, "XGoldenMinerDataDb")

function XGoldenMinerDataDb:Ctor()
    self._ActivityId = 0                --当前活动id
    self._TotalPlayCount = 0            --游玩的次数
    self._TotalMaxScores = 0            --历史最高分
    self._TotalMaxScoresCharacter = 0   --历史最高分使用角色
    self._TotalMaxScoresHexes = {}      --历史最高分使用海克斯
    self._RedEnvelopeProgress = {}      --红包进度（Dictionary<int/*NpcId*/, int/*累计获得数*/>）
    
    self._CurPlayCharacterId = 0        --当前关卡选择的角色id
    self._CharacterDbs = {}             --已经解锁的角色
    
    self._StageScores = 0               --当前关卡内的积分
    self._CurPlayStage = 0              --正在进行中的关卡
    self._FinishStageIdDir = {}         --已完成的stageId
    ---@type XGoldenMinerStageMapInfo[]
    self._StageMapInfos = {}            --随机到的关卡信息
    ---@type XGoldenMinerStageMapInfo[]
    self._StageMapInfoDic = {}          --关卡Id作为key的字典
    self._LastFinishStageId = 0         --通关的关卡列表中最后一个的关卡Id

    ---@type XGoldenMinerStrengthenData[]
    self._UpgradeStrengthens = {}       --飞碟可升级物品项目

    ---@type XGoldenMinerItemData[]
    self._ItemColumns = {}              --道具栏位置，下标从0开始的字典
    self._ItemBuyRecord = {}            --商品购买记录
    ---@type XGoldenMinerItemData[]
    self._ItemColumnsBackups = {}       --备份道具栏

    ---@type XGoldenMinerItemData[]
    self._BuffColumns = {}              --购买的buff道具栏位置
    
    ---@type XGoldenMinerShopItemData[]
    self._MinerShopDbs = {}             --商店刷新商品
    
    ---@type XGoldenMinerHideTaskInfo[]
    self._HideTaskInfo = {}             --隐藏任务信息
    self._HideStageCount = 0            --隐藏关卡数量
    
    self._HexSelects = {}               --可选海克斯列表
    self._HexRecords = {}               --已选海克斯列表
    
    self:ResetCurClearData()
end

function XGoldenMinerDataDb:ResetData()
    self._CurPlayCharacterId = 0
    self._CurPlayStage = 0
    self._StageScores = 0
    self._FinishStageIdDir = {}
    self._ItemBuyRecord = {}
    self._ItemColumns = {}
    self._UpgradeStrengthens = {}
    self._MinerShopDbs = {}
    self._StageMapInfos = {}
    self._BuffColumns = {}
    self._ItemColumnsBackups = {}
    self._HideTaskInfo = {}

    for _, strengthenDb in pairs(self._UpgradeStrengthens) do
        strengthenDb:UpdateLevelIndex(-1)
    end
end

function XGoldenMinerDataDb:UpdateData(data)
    self._ActivityId = data.ActivityId
    self._CurPlayCharacterId = data.CharacterId
    self._ItemBuyRecord = data.ItemBuyRecord
    self:UpdateTotalPlayCount(data.TotalPlayCount)
    self:UpdateCurrentPlayStage(data.CurrentPlayStage)
    self:UpdateTotalMaxScores(data.TotalMaxScores)
    self:UpdateTotalMaxScoresCharacter(data.TotalMaxScoresCharacter)
    self:UpdateTotalMaxScoresHexes(data.TotalMaxScoresHexes)
    self:UpdateItemColumns(data.ItemColumns)
    self:UpdateBuffColumns(data.BuffColumns)
    self:UpdateUpgradeStrengthens(data.UpgradeStrengthens)
    self:UpdateMinerShopDbs(data.MinerShopDbs)
    self:UpdateStageMapInfos(data.StageMapInfos)
    self:UpdateStageScores(data.StageScores)
    self:UpdateNewCharacter(data.CharacterDbs)
    self:UpdateFinishStageIds(data.FinishStageId)
    self:UpdateRedEnvelopeProgress(data.RedEnvelopeProgress)
    self:UpdateHideTaskInfo(data.HideTaskInfo)
    self:UpdateHideStageCount(data.HideStageCount)
    self:UpdateHexSelects(data.HexSelects)
    self:UpdateHexRecords(data.HexRecords)
end

--region Activity
function XGoldenMinerDataDb:GetActivityId()
    return self._ActivityId
end
--endregion

--region Character
function XGoldenMinerDataDb:UpdateNewCharacter(unlockCharacters)
    for _, characterId in pairs(unlockCharacters) do
        self._CharacterDbs[characterId] = true
    end
end

function XGoldenMinerDataDb:GetCurPlayCharacterId()
    return self._CurPlayCharacterId
end

function XGoldenMinerDataDb:IsCharacterUnlock(characterId)
    return self._CharacterDbs[characterId] or false
end
--endregion

--region Shop
function XGoldenMinerDataDb:UpdateMinerShopDbs(minerShopDbs)
    self:ClearShopDb()
    for i, v in ipairs(minerShopDbs) do
        local minerShopDb = XGoldenMinerShopItemData.New(v.ItemId)
        minerShopDb:UpdateData(v)
        self._MinerShopDbs[i] = minerShopDb
    end
end

function XGoldenMinerDataDb:ClearShopDb()
    self._MinerShopDbs = {}
end

function XGoldenMinerDataDb:GetMinerShopDbs(isCheckLockItem)
    if not isCheckLockItem then
        return self._MinerShopDbs
    end

    --检查是否返回上锁的商店道具
    local stageId = self:GetLastFinishStageId()
    if not XTool.IsNumberValid(stageId) then
        return self._MinerShopDbs
    end

    local shopGridCount = XMVCA.XGoldenMiner:GetCfgStageShopGridCount(stageId)
    local lockCount = XMVCA.XGoldenMiner:GetShopGridLockCount()
    local totalCount = shopGridCount + lockCount
    if totalCount <= #self._MinerShopDbs then
        return self._MinerShopDbs
    end

    local dataCopy = XTool.Clone(self._MinerShopDbs)
    for i = 1, totalCount - #dataCopy do
        table.insert(dataCopy, {})
    end
    return dataCopy
end

function XGoldenMinerDataDb:GetMinerShopDbByIndex(index)
    return self._MinerShopDbs[index]
end

function XGoldenMinerDataDb:IsItemAlreadyBuy(index)
    local shopDb = self._MinerShopDbs[index]
    if not shopDb then
        XLog.Error("判断道具是否已购买错误，不存在的道具下标：", index, self._MinerShopDbs)
        return false
    end
    return XTool.IsNumberValid(shopDb:GetBuyStatus())
end
--endregion

--region Item
function XGoldenMinerDataDb:UpdateItemColumns(itemColumns)
    self._ItemColumns = {}
    for i, v in pairs(itemColumns) do
        local itemData = XGoldenMinerItemData.New(v.ItemId)
        itemData:SetGridIndex(i)
        itemData:UpdateData(v)
        self._ItemColumns[i] = itemData
    end
end

---备份道具栏，用于通关不通过时回溯（后端不会下发回溯数据）
function XGoldenMinerDataDb:BackupsItemColumns()
    self._ItemColumnsBackups = XTool.Clone(self._ItemColumns)
end

---用备份的道具栏覆盖
function XGoldenMinerDataDb:CoverItemColumns()
    self._ItemColumns = XTool.Clone(self._ItemColumnsBackups)
end

---@param gridIndex number 格子下标,从0开始
function XGoldenMinerDataDb:UpdateItemColumn(itemId, gridIndex)
    local itemColumn = self:GetItemColumnByIndex(gridIndex)
    if not itemColumn then
        itemColumn = XGoldenMinerItemData.New(itemId)
        itemColumn:SetGridIndex(gridIndex)
        self._ItemColumns[gridIndex] = itemColumn
    end
    itemColumn:SetItemId(itemId)
    itemColumn:SetClientItemId(itemId)
    itemColumn:SetStatus(XEnumConst.GOLDEN_MINER.ITEM_CHANGE_TYPE.ON_GET)
end

---道具是否可使用
function XGoldenMinerDataDb:IsUseItem(useItemIndex)
    local itemColumn = self:GetItemColumnByIndex(useItemIndex)
    if not itemColumn then
        return false
    end

    if itemColumn:GetStatus() == XEnumConst.GOLDEN_MINER.ITEM_CHANGE_TYPE.ON_USE then
        return false
    end

    local itemId = itemColumn:GetClientItemId()
    if XMVCA.XGoldenMiner:GetCfgItemType(itemId) ~= XEnumConst.GOLDEN_MINER.ITEM_TYPE.NORMAL_ITEM then
        return false
    end

    return true
end

---使用道具
function XGoldenMinerDataDb:UseItem(useItemIndex)
    local itemColumn = self:GetItemColumnByIndex(useItemIndex)
    if not itemColumn then
        XLog.Error("黄金矿工使用的道具不存在，道具所在的下标为：", useItemIndex)
        return false
    end
    -- 去除道具避免占位
    self._ItemColumns[useItemIndex] = nil
end

---获得未放置道具的道具栏下标
function XGoldenMinerDataDb:GetEmptyItemIndex()
    local maxGridCount = XMVCA.XGoldenMiner:GetCurActivityMaxItemColumnCount()
    for i = 0, maxGridCount - 1 do
        if not self._ItemColumns[i] then
            return i
        end
    end
end

---@return XGoldenMinerItemData[]
function XGoldenMinerDataDb:GetItemColumns()
    return self._ItemColumns
end

function XGoldenMinerDataDb:GetItemColumnByIndex(itemIndex)
    return self._ItemColumns[itemIndex]
end
--endregion

--region Buff
function XGoldenMinerDataDb:UpdateBuffColumns(buffColumns)
    self._BuffColumns = {}
    for i, v in pairs(buffColumns or {}) do
        local itemData = XGoldenMinerItemData.New(v.ItemId)
        itemData:UpdateData(v)
        table.insert(self._BuffColumns, itemData)
    end
end

function XGoldenMinerDataDb:UpdateBuffColumn(itemId)
    local itemData = XGoldenMinerItemData.New(itemId)
    table.insert(self._BuffColumns, itemData)
end

function XGoldenMinerDataDb:GetBuffColumns()
    return self._BuffColumns
end
--endregion

--region Stage
function XGoldenMinerDataDb:UpdateCurrentPlayStage(currentPlayStage)
    self._CurPlayStage = currentPlayStage
end

function XGoldenMinerDataDb:UpdateFinishStageIds(finishStageIds)
    self._FinishStageIdDir = {}
    for i, stageId in ipairs(finishStageIds) do
        self._FinishStageIdDir[stageId] = true
    end
    self._LastFinishStageId = finishStageIds[#finishStageIds]
end

function XGoldenMinerDataDb:UpdateStageScores(scores)
    self._StageScores = scores
end

function XGoldenMinerDataDb:UpdateStageMapInfos(stageMapInfos)
    self._StageMapInfos = {}
    self._StageMapInfoDic = {}
    for i, v in ipairs(stageMapInfos) do
        local stageMapInfo = XGoldenMinerStageMapInfo.New()
        stageMapInfo:UpdateData(v)
        self._StageMapInfos[i] = stageMapInfo
        self._StageMapInfoDic[v.StageId] = stageMapInfo
    end
    --self:_UpdateHexMap() -- 2.17海克斯对应地图不止一个，依赖服务器随机出的地图
end

function XGoldenMinerDataDb:GetCurStageId()
    local stageMapInfos = self:GetStageMapInfos()
    local stageId
    for index, stageMapInfo in ipairs(stageMapInfos) do
        stageId = stageMapInfo:GetStageId()
        if not self:IsStageFinish(stageId) then
            return stageId, index
        end
    end
end

function XGoldenMinerDataDb:CheckIsInStage()
    return XTool.IsNumberValid(self:GetCurStageId())
end

---在主界面显示的
function XGoldenMinerDataDb:GetCurShowStageIndex()
    local stageMapInfos = self:GetStageMapInfos()
    local stageId, curIndex
    local stageCount = 0
    for index, stageMapInfo in ipairs(stageMapInfos) do
        stageId = stageMapInfo:GetStageId()
        stageCount = stageCount + 1
        if not self:IsStageFinish(stageId) then
            curIndex = index
            break
        end
    end
    if not curIndex then
        curIndex = stageCount
    end
    if XTool.IsNumberValid(self._CurPlayStage) then
        return curIndex
    else
        return math.max(1, curIndex - 1)
    end
end

function XGoldenMinerDataDb:GetCurStageIsFirst()
    local curStageId, curStageIndex = self:GetCurStageId()
    return curStageIndex == 1
end

function XGoldenMinerDataDb:GetStageScores()
    return self._StageScores
end

function XGoldenMinerDataDb:GetCurrentStageId()
    return self._CurrentStageId
end

function XGoldenMinerDataDb:IsStageFinish(stageId)
    return self._FinishStageIdDir[stageId] or false
end

function XGoldenMinerDataDb:GetLastFinishStageId()
    return self._LastFinishStageId
end

---@return XGoldenMinerStageMapInfo[]
function XGoldenMinerDataDb:GetStageMapInfos()
    return self._StageMapInfos
end

---@return XGoldenMinerStageMapInfo
function XGoldenMinerDataDb:GetStageMapInfo(stageId)
    return self._StageMapInfos[stageId]
end

function XGoldenMinerDataDb:GetStageMapId(stageId)
    local stageMapInfo = self._StageMapInfoDic[stageId]
    return stageMapInfo:GetMapId()
end

function XGoldenMinerDataDb:GetCurrentPlayStage()
    return self._CurPlayStage
end

function XGoldenMinerDataDb:GetFinishStageCount()
    local finishStageCount = 0
    for _ in pairs(self._FinishStageIdDir) do
        finishStageCount = finishStageCount + 1
    end
    return finishStageCount
end

--获得当前关卡的目标得分
function XGoldenMinerDataDb:GetCurStageTargetScore()
    local targetScore = 0
    for stageId in pairs(self._FinishStageIdDir) do
        targetScore = targetScore + XMVCA.XGoldenMiner:GetCfgStageTargetScore(stageId)
    end

    local curStageId = self:GetCurStageId()
    if XTool.IsNumberValid(curStageId) then
        targetScore = targetScore + XMVCA.XGoldenMiner:GetCfgStageTargetScore(curStageId)
    end
    return targetScore
end
--endregion

--region Strengthen
function XGoldenMinerDataDb:UpdateUpgradeStrengthens(upgradeStrengthens)
    self._UpgradeStrengthens = {}
    for i, v in ipairs(upgradeStrengthens) do
        local strengthenDb = XGoldenMinerStrengthenData.New()
        strengthenDb:UpdateData(v)
        self._UpgradeStrengthens[v.StrengthenId] = strengthenDb
    end
end

function XGoldenMinerDataDb:UpdateUpgradeStrengthenLevel(strengthenId, levelIndex)
    local strengthenDb = self:GetUpgradeStrengthen(strengthenId)
    if not strengthenDb then
        XLog.Error("黄金矿工更新飞碟等级错误，找不到数据，strengthenId：", strengthenId)
        return
    end
    strengthenDb:UpdateLevelIndex(levelIndex)
end

function XGoldenMinerDataDb:UpdateUpgradeStrengthenAlreadyBuy(strengthenId, serverLevelIndex)
    local strengthenDb = self:GetUpgradeStrengthen(strengthenId)
    if not strengthenDb then
        XLog.Error("黄金矿工更新飞碟等级错误，找不到数据，strengthenId：", strengthenId)
        return
    end
    strengthenDb:AddAlreadyBuys(serverLevelIndex)
end

--获得所有等级不为0的强化属性
---@return XGoldenMinerStrengthenData[]
function XGoldenMinerDataDb:GetAllUpgradeStrengthenList()
    local upgradeStrengthenList = {}
    for _, v in pairs(self._UpgradeStrengthens) do
        if XTool.IsNumberValid(v:GetClientLevelIndex()) then
            table.insert(upgradeStrengthenList, v)
        end
    end

    return upgradeStrengthenList
end

function XGoldenMinerDataDb:GetUpgradeStrengthen(upgradeId)
    if not self._UpgradeStrengthens[upgradeId] then
        self._UpgradeStrengthens[upgradeId] = XGoldenMinerStrengthenData.New(upgradeId)
    end
    return self._UpgradeStrengthens[upgradeId]
end

function XGoldenMinerDataDb:GetUpgradeStrengthens()
    return self._UpgradeStrengthens
end
--endregion

--region Record
function XGoldenMinerDataDb:UpdateTotalMaxScores(totalMaxScores)
    self._TotalMaxScores = totalMaxScores
end

function XGoldenMinerDataDb:UpdateTotalPlayCount(totalPlayCount)
    self._TotalPlayCount = totalPlayCount
end

function XGoldenMinerDataDb:UpdateTotalMaxScoresCharacter(totalMaxScoresCharacter)
    self._TotalMaxScoresCharacter = totalMaxScoresCharacter or self._TotalMaxScoresCharacter
end

function XGoldenMinerDataDb:UpdateTotalMaxScoresHexes(totalMaxScoresHexes)
    --if XTool.IsTableEmpty(totalMaxScoresHexes) then
    --    return
    --end
    self._TotalMaxScoresHexes = totalMaxScoresHexes
end

function XGoldenMinerDataDb:UpdateRedEnvelopeProgress(redEnvelopeProgress)
    self._RedEnvelopeProgress = redEnvelopeProgress
end

function XGoldenMinerDataDb:GetTotalMaxScores()
    return self._TotalMaxScores
end

function XGoldenMinerDataDb:GeTotalPlayCount()
    return self._TotalPlayCount
end

function XGoldenMinerDataDb:GetTotalMaxScoresCharacter()
    return self._TotalMaxScoresCharacter
end

function XGoldenMinerDataDb:GetTotalMaxScoresHexes()
    return self._TotalMaxScoresHexes
end

function XGoldenMinerDataDb:GetRedEnvelopeProgress(redEnvelopeNpcId)
    return self._RedEnvelopeProgress[redEnvelopeNpcId] or 0
end
--endregion

--region HideTask
function XGoldenMinerDataDb:UpdateHideTaskInfo(hideTaskInfoList)
    self._HideTaskInfo = {}
    if XTool.IsTableEmpty(hideTaskInfoList) then
        return
    end
    for _, data in ipairs(hideTaskInfoList) do
        ---@type XGoldenMinerHideTaskInfo
        local hideTaskInfo = XGoldenMinerHideTaskInfo.New(data.Id)
        hideTaskInfo:SetCurProgress(data.Progress)
        self._HideTaskInfo[#self._HideTaskInfo + 1] = hideTaskInfo
    end
end

function XGoldenMinerDataDb:UpdateHideStageCount(hideStageCount)
    self._HideStageCount = hideStageCount
end

---@return XGoldenMinerHideTaskInfo[]
function XGoldenMinerDataDb:GetHideTaskInfo()
    return self._HideTaskInfo
end

function XGoldenMinerDataDb:GetFinishHideTaskCount()
    local result = 0
    if XTool.IsTableEmpty(self._HideTaskInfo) then
        return result
    end
    for _, hideTaskInfo in ipairs(self._HideTaskInfo) do
        if hideTaskInfo:IsFinish() then
            result = result + 1
        end
    end
    return result
end

function XGoldenMinerDataDb:GetHideStageCount()
    return self._HideStageCount
end
--endregion

--region Hex
function XGoldenMinerDataDb:UpdateHexSelects(data)
    if XTool.IsTableEmpty(data) then
        self:ClearHexSelects()
    else
        self._HexSelects = data
    end
end

function XGoldenMinerDataDb:UpdateHexRecords(data)
    if XTool.IsTableEmpty(data) then
        self._HexRecords = {}
    else
        self._HexRecords = data
    end
end

function XGoldenMinerDataDb:ClearHexSelects()
    self._HexSelects = {}
end

function XGoldenMinerDataDb:GetBeSelectHexList()
    return self._HexSelects
end

function XGoldenMinerDataDb:GetSelectedHexList()
    return self._HexRecords
end

function XGoldenMinerDataDb:CheckIsBeSelectHex()
    return not XTool.IsTableEmpty(self._HexSelects)
end

function XGoldenMinerDataDb:AddHexRecords(hexId)
    if not self:CheckHaveHex(hexId) then
        table.insert(self._HexRecords, hexId)
    end
    --self:_UpdateHexMap() -- 2.17海克斯对应地图不止一个，依赖服务器随机出的地图
end

function XGoldenMinerDataDb:CheckIsNotHex()
    return XTool.IsTableEmpty(self._HexRecords)
end

function XGoldenMinerDataDb:_UpdateHexMap()
    if self:CheckIsNotHex() or XTool.IsTableEmpty(self._StageMapInfos) then
        return
    end
    XMVCA.XGoldenMiner:DebugWarning("海克斯更新前地图", self._StageMapInfos)
    for i, hexId in ipairs(self:GetSelectedHexList()) do
        local changeStageIndex = XMVCA.XGoldenMiner:GetCurActivityHexMapStages(i)
        self._StageMapInfos[changeStageIndex]:UpdateMapId(XMVCA.XGoldenMiner:GetCfgHexMapId(hexId))
    end
    XMVCA.XGoldenMiner:DebugWarning("海克斯更新后地图", self._StageMapInfos)
end

function XGoldenMinerDataDb:CheckHaveHex(hexId)
    return table.indexof(self._HexRecords, hexId)
end
--endregion

------------通关结算数据 begin--------------
function XGoldenMinerDataDb:ResetCurClearData()
    --所有关卡通关或中途退出的数据
    self.CurClearData = {
        ClearStageCount = 0,    --通关关卡数
        TotalScore = 0,         --总积分
        IsNew = false,          --是否新纪录
        IsShow = false,         --是否需要显示数据
    }
end

function XGoldenMinerDataDb:UpdateCurClearData(totalScore, isWin)
    totalScore = totalScore or 0
    local lastStageFinishCount = isWin and 1 or 0   --最后一关后端不会给通关结果，前端自己判断增加
    self.CurClearData = {
        ClearStageCount = self:GetFinishStageCount() + lastStageFinishCount,
        TotalScore = totalScore,
        IsNew = totalScore > self:GetTotalMaxScores(),
        IsShow = true
    }
end

function XGoldenMinerDataDb:GetCurClearData()
    return self.CurClearData
end
------------通关结算数据 end-----------------

return XGoldenMinerDataDb
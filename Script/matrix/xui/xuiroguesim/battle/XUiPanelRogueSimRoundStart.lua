---@class XUiPanelRogueSimRoundStart : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimRoundStart = XClass(XUiNode, "XUiPanelRogueSimRoundStart")

function XUiPanelRogueSimRoundStart:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnCloseClick)
    -- 传闻
    self.GridNews.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridNewList = {}
    -- 市场
    self.GridMarket.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridMarketList = {}
    -- 资源产出
    self.GridProduce.gameObject:SetActiveEx(false)
    -- 资源售价
    self.GridPrice.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimResource[]
    self.GridPriceList = {}
    -- 出售列表
    self.GridSell.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimRoundStartSell[]
    self.GridSellList = {}
    -- 直方图
    self.GridTurnData.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridTurnList = {}
end

function XUiPanelRogueSimRoundStart:OnDisable()
    -- 清空回合结算数据
    self._Control:ClearTurnSettleData()
end

function XUiPanelRogueSimRoundStart:Refresh()
    self.TxtRound.text = self:GetRoundStartShowTurnNumber()
    self:RefreshSell()
    self:RefreshPrice()
    self:RefreshNews()
    self:RefreshMarket()
    self:RefreshProduce()
    -- 引导
    self._Control:TriggerGuide()
end

-- 获取回合开始显示的回合数
function XUiPanelRogueSimRoundStart:GetRoundStartShowTurnNumber()
    -- 当前回合数
    local curTurnCount = self._Control:GetCurTurnNumber()
    -- 结算数据不为空，则获取结算时缓存的回合数
    if not self._Control:CheckStageSettleDataIsEmpty() then
        curTurnCount = self._Control:GetStageSettleTurnNumber()
    end
    return curTurnCount
end

-- 获取结算显示的回合数
function XUiPanelRogueSimRoundStart:GetSettleShowTurnNumber()
    -- 当前回合数
    local curTurnCount = self._Control:GetCurTurnNumber()
    -- 上一回合
    local lastTurnCount = curTurnCount - 1
    -- 结算数据不为空，则获取结算时缓存的回合数
    if not self._Control:CheckStageSettleDataIsEmpty() then
        lastTurnCount = self._Control:GetStageSettleTurnNumber()
    end
    return lastTurnCount
end

-- 刷新贸易
function XUiPanelRogueSimRoundStart:RefreshSell()
    local lastTurnCount = self:GetSettleShowTurnNumber()
    local lastSellResult = self._Control:GetSellResultByTurnNumber(lastTurnCount)
    -- 是否为空
    local isEmpty = XTool.IsTableEmpty(lastSellResult)
    self.TxtSellNone.gameObject:SetActiveEx(isEmpty)
    self.PanelHistogram.gameObject:SetActiveEx(not isEmpty)
    self.PanelProfit.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        for _, grid in pairs(self.GridSellList) do
            grid:Close()
        end
        self.SellList.gameObject:SetActiveEx(false)
        return
    end
    self.SellList.gameObject:SetActiveEx(true)
    -- 出售列表
    local infos = lastSellResult:GetDatas()
    for index, info in pairs(infos) do
        local grid = self.GridSellList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSell, self.SellList)
            grid = require("XUi/XUiRogueSim/Battle/XUiGridRogueSimRoundStartSell").New(go, self)
            self.GridSellList[index] = grid
        end
        grid:Open()
        grid:Refresh(info)
    end
    for i = #infos + 1, #self.GridSellList do
        self.GridSellList[i]:Close()
    end
    -- 总利润
    local totalPrice = lastSellResult:GetTotalPrice()
    self.TxtProfit.text = string.format("+%d", totalPrice)
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold))
    -- 相对之前是否增加
    local _, lastTotalPrice = self._Control:GetRecentSellResults(lastTurnCount - 1, 1)
    self.ImgUp.gameObject:SetActiveEx(totalPrice > lastTotalPrice)
    self.ImgDown.gameObject:SetActiveEx(totalPrice < lastTotalPrice)
    -- 直方图(只显示三个)
    local recentSellResults, maxTotalPrice = self._Control:GetRecentSellResults(lastTurnCount, 3)
    for index, info in pairs(recentSellResults) do
        local grid = self.GridTurnList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTurnData, self.TurnDataList)
            self.GridTurnList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtRoundNum").text = info.TurnNum
        grid:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(maxTotalPrice) and info.TotalPrice / maxTotalPrice or 1
        local color = self._Control:GetClientConfig("RoundStartSellHistogramColor", info.TurnNum == lastTurnCount and 2 or 1)
        grid:GetObject("ImgBar").color = XUiHelper.Hexcolor2Color(color)
    end
    for i = #recentSellResults + 1, #self.GridTurnList do
        self.GridTurnList[i].gameObject:SetActiveEx(false)
    end
end

-- 刷新价格
function XUiPanelRogueSimRoundStart:RefreshPrice()
    if not self._Control:CheckStageSettleDataIsEmpty() then
        for _, grid in pairs(self.GridPriceList) do
            grid:Close()
        end
        return
    end
    local gridName = self.GridPrice.gameObject.name
    local commodityIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(commodityIds) do
        local grid = self.GridPriceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPrice, self.PanelPrice)
            grid = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource").New(go, self)
            self.GridPriceList[index] = grid
        end
        grid:Open()
        grid:SetShowStatus(true, false, true)
        grid:Refresh(id)
        -- 修改名称引导使用
        grid.GameObject.name = string.format("%s%d", gridName, index)
    end
end

-- 刷新传闻
function XUiPanelRogueSimRoundStart:RefreshNews()
    local allTips = self._Control:GetAllTipList()
    self.TxtNewsNone.gameObject:SetActiveEx(XTool.IsTableEmpty(allTips))
    for index, msg in pairs(allTips) do
        local grid = self.GridNewList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridNews, self.PanelNews)
            self.GridNewList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtNews").text = msg
    end
    for index = #allTips + 1, #self.GridNewList do
        self.GridNewList[index].gameObject:SetActiveEx(false)
    end
end

-- 刷新市场
function XUiPanelRogueSimRoundStart:RefreshMarket()
    local buffIds = self._Control.BuffSubControl:GetRoundStartShowBuffs()
    self.TxtMarketNone.gameObject:SetActiveEx(XTool.IsTableEmpty(buffIds))
    for index, id in pairs(buffIds) do
        local grid = self.GridMarketList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridMarket, self.PanelMarket)
            self.GridMarketList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local buffId = self._Control.BuffSubControl:GetBuffIdById(id)
        grid:GetObject("RImgBuff"):SetRawImage(self._Control.BuffSubControl:GetBuffIcon(buffId))
        -- 剩余回合数
        local remainingRound = self._Control.BuffSubControl:GetBuffRemainingTurnById(id)
        grid:GetObject("PanelNum").gameObject:SetActiveEx(remainingRound >= 0)
        grid:GetObject("TxtNum").text = remainingRound >= 0 and remainingRound or ""
        grid:GetObject("TxtMarket").text = self._Control.BuffSubControl:GetBuffDesc(buffId)
    end
    for index = #buffIds + 1, #self.GridMarketList do
        self.GridMarketList[index].gameObject:SetActiveEx(false)
    end
end

-- 刷新产出
function XUiPanelRogueSimRoundStart:RefreshProduce()
    -- 回合结算数据
    local turnSettleData = self._Control:GetTurnSettleData()
    if XTool.IsTableEmpty(turnSettleData) then
        XLog.Error("error: TurnSettleData is empty")
        return
    end
    local id = turnSettleData.CommodityProduceId
    local count = turnSettleData.CommodityProduceCount
    local isCritical = turnSettleData.CommodityProduceIsCritical
    if not self.Produce then
        ---@type XUiGridRogueSimResource
        self.Produce = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource").New(self.GridProduce, self)
    end
    self.Produce:Open()
    self.Produce:SetShowStatus(false, true)
    self.Produce:SetProduceData(count, isCritical)
    self.Produce:HideBubble()
    self.Produce:Refresh(id)
    -- 是否溢出
    local isOverflow = turnSettleData.CommodityProduceIsOverflow
    self.TxtFull.gameObject:SetActiveEx(isOverflow)
end

function XUiPanelRogueSimRoundStart:OnBtnCloseClick()
    self:Close()
    if not self._Control:CheckStageSettleDataIsEmpty() then
        -- 显示结算
        XLuaUiManager.Open("UiRogueSimSettlement")
        -- 退出战斗
        self._Control:OnExitScene()
        XLuaUiManager.SafeClose("UiRogueSimBattle")
        return
    end
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowPopup(type)
end

return XUiPanelRogueSimRoundStart

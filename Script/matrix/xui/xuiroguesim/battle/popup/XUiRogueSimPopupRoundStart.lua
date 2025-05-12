local XUiGridRogueSimResource = require("XUi/XUiRogueSim/Common/XUiGridRogueSimResource")
local XUiPanelRogueSimRoundStartSell = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimRoundStartSell")
---@class XUiRogueSimPopupRoundStart : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimPopupRoundStart = XLuaUiManager.Register(XLuaUi, "UiRogueSimPopupRoundStart")

function XUiRogueSimPopupRoundStart:OnAwake()
    self:RegisterUiEvents()
    self.PanelSell.gameObject:SetActiveEx(false)
    self.GridPrice.gameObject:SetActiveEx(false)
    self.GridResource.gameObject:SetActiveEx(false)
    self.GridNews.gameObject:SetActiveEx(false)
    self.GridMarket.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimResource[]
    self.GridPriceList = {}
    ---@type XUiGridRogueSimResource[]
    self.GridProduceList = {}
    ---@type UiObject[]
    self.GridNewList = {}
    ---@type UiObject[]
    self.GridMarketList = {}
end

function XUiRogueSimPopupRoundStart:OnStart()
    self.TurnSettleData = self._Control:GetTurnSettleData()
    -- 回合数
    self.TurnNumber = 0
end

function XUiRogueSimPopupRoundStart:OnEnable()
    if not self.TurnSettleData then
        XLog.Error("TurnSettleData is empty")
        return
    end
    self.TurnNumber = self.TurnSettleData:GetTurnNumber()
    self:RefreshTitle()
    self:RefreshSell()
    self:RefreshPrice()
    self:RefreshProduce()
    self:RefreshNews()
    self:RefreshMarket()
end

function XUiRogueSimPopupRoundStart:OnDisable()
    -- 清空回合结算数据
    self._Control:ClearTurnSettleData()
end

-- 刷新标题
function XUiRogueSimPopupRoundStart:RefreshTitle()
    local curTurnNumber = self._Control:GetCurTurnNumber()
    if not XTool.IsNumberValid(curTurnNumber) then
        curTurnNumber = self.TurnNumber
    end
    local title = self._Control:GetClientConfig("BattleRoundNumDesc")
    self.TxtRound.text = string.format(title, curTurnNumber)
end

-- 刷新出售
function XUiRogueSimPopupRoundStart:RefreshSell()
    if not self.PanelSellUI then
        ---@type XUiPanelRogueSimRoundStartSell
        self.PanelSellUI = XUiPanelRogueSimRoundStartSell.New(self.PanelSell, self)
    end
    self.PanelSellUI:Open()
    self.PanelSellUI:Refresh(self.TurnNumber)
end

-- 刷新价格波动
function XUiRogueSimPopupRoundStart:RefreshPrice()
    if not self._Control:CheckStageSettleDataIsEmpty() then
        return
    end
    local gridName = self.GridPrice.gameObject.name
    local commodityIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(commodityIds) do
        local grid = self.GridPriceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPrice, self.PanelPrice)
            grid = XUiGridRogueSimResource.New(go, self)
            self.GridPriceList[index] = grid
        end
        grid:Open()
        grid:SetShowStatus(true, false, true)
        grid:Refresh(id)
        -- 修改名称引导使用
        grid.GameObject.name = string.format("%s%s", gridName, index)
    end
end

-- 刷新产出
function XUiRogueSimPopupRoundStart:RefreshProduce()
    local produceResult = self._Control:GetProduceResultByTurnNumber(self.TurnNumber)
    if not produceResult then
        return
    end
    local gridName = self.GridResource.gameObject.name
    local info = produceResult:GetDatas()
    for index, data in pairs(info) do
        local grid = self.GridProduceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridResource, self.ListResource)
            grid = XUiGridRogueSimResource.New(go, self)
            self.GridProduceList[index] = grid
        end
        grid:Open()
        grid:SetShowStatus(false, true)
        grid:SetProduceData(data:GetProduceCount(), data:GetIsCritical())
        grid:HideBubble()
        grid:Refresh(data:GetCommodityId())
        -- 修改名称引导使用
        grid.GameObject.name = string.format("%s%s", gridName, index)
    end
    for i = #info + 1, #self.GridProduceList do
        self.GridProduceList[i]:Close()
    end
end

-- 刷新传闻
function XUiRogueSimPopupRoundStart:RefreshNews()
    local tipIds = self._Control:GetCurTurnTipIds()
    self.TxtNewsNone.gameObject:SetActiveEx(XTool.IsTableEmpty(tipIds))
    for index, tipId in pairs(tipIds) do
        local grid = self.GridNewList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridNews, self.PanelNews)
            self.GridNewList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtNews").text = self._Control:GetTipContent(tipId)
    end
    for index = #tipIds + 1, #self.GridNewList do
        self.GridNewList[index].gameObject:SetActiveEx(false)
    end
end

-- 刷新市场
function XUiRogueSimPopupRoundStart:RefreshMarket()
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

function XUiRogueSimPopupRoundStart:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiRogueSimPopupRoundStart:OnBtnCloseClick()
    if not self._Control:CheckStageSettleDataIsEmpty() then
        -- 显示结算
        XLuaUiManager.Open("UiRogueSimSettlement")
        -- 退出战斗
        self._Control:OnExitScene()
        XLuaUiManager.Remove("UiRogueSimBattle")
        self:Remove()
        return
    end
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

return XUiRogueSimPopupRoundStart

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---黄金矿工商店界面
---@class XUiGoldenMinerShop : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerShop = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerShop")

function XUiGoldenMinerShop:OnAwake()
    self:_InitData()
    self:InitDynamicList()
    self:InitItemPanel()
    self:InitTipSellPanel()
    self:InitTxtCurScore()
    --4期没有页签和Buff列表
    --self:InitBtnGroup()
    --self:InitBuffPanel()
    self:AddBtnClickListener()
end

function XUiGoldenMinerShop:OnStart()
    self:_InitAutoCloseTimer()
    self:CloseTipSellPanel()
end

function XUiGoldenMinerShop:OnEnable()
    self:AddEventListener()
    XUiGoldenMinerShop.Super.OnEnable(self)
    self:Refresh()
end

function XUiGoldenMinerShop:OnDisable()
    self:RemoveEventListener()
end


--region Activity - AutoClose
function XUiGoldenMinerShop:_InitAutoCloseTimer()
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Data
function XUiGoldenMinerShop:_InitData()
    local hookItemDataList, upItemDataList = self._Control:GetUpgradeShowDataDir()
    self.DataDb = self._Control:GetMainDb()
    self._BtnGroupType = {
        BuyItem = 1,
        Hook = 2,
        LevelUp = 3,
    }
    self._BtnGroupData = {
        self.DataDb:GetMinerShopDbs(false),
        hookItemDataList,
        upItemDataList,
    }
    self._BuffListTitle = {
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopItemTitle"),
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopShipTitle"),
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopShipTitle"),
    }
    self._BuffRefreshFunc = {
        handler(self._Control, self._Control.GetShowTempBuffIdList),
        handler(self._Control, self._Control.GetShowShipBuffIdList),
        handler(self._Control, self._Control.GetShowShipBuffIdList),
    }
    self.CurStageId = self.DataDb:GetCurStageId()
    self.CurSelectBtnIndex = self._BtnGroupType.BuyItem
    self.DataList = self._BtnGroupData[self.CurSelectBtnIndex]
end
--endregion

--region Ui - Refresh
function XUiGoldenMinerShop:Refresh()
    self:UpdateTextCurScore()
    self:RefreshItemPanel()
    self:RefreshDynamicTable()
    --self:RefreshBuffPanel(self.CurSelectBtnIndex)
end
--endregion

--region Ui - ShopTabGroup
function XUiGoldenMinerShop:InitBtnGroup()
    local btnGroup = {
        self.BtnBuyItem,
        self.BtnLevelFinger,
        self.BtnLevelUp,
    }
    self.PanelTabBtn:Init(btnGroup, function(index) self:OnSelectButton(index) end)
    self.PanelTabBtn:SelectIndex(self._BtnGroupType.BuyItem)
end

function XUiGoldenMinerShop:OnSelectButton(index)
    if self.CurSelectBtnIndex == index then
        return
    end
    self.CurSelectBtnIndex = index
    self.DataList = self._BtnGroupData[index]
    --self:RefreshBuffPanel(index)
    if self.TxtShipBuffListTitle then
        self.TxtShipBuffListTitle.text = self._BuffListTitle[index]
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
    --self:PlayAnimation("QieHuan")
end
--endregion

--region Ui - ItemPanel
function XUiGoldenMinerShop:InitItemPanel()
    local XUiGoldenMinerItemPanel = require("XUi/XUiGoldenMiner/Panel/XUiGoldenMinerItemPanel")
    ---@type XUiGoldenMinerItemPanel
    self.ItemPanel = XUiGoldenMinerItemPanel.New(self.PanelSkillParent, self, false)
end

function XUiGoldenMinerShop:RefreshItemPanel()
    self.ItemPanel:UpdateItemColumns()
end
--endregion

--region Ui - BuffPanel
function XUiGoldenMinerShop:InitBuffPanel()
    local XUiGoldenMinerBuffPanel = require("XUi/XUiGoldenMiner/Panel/XUiGoldenMinerBuffPanel")
    ---@type XUiGoldenMinerBuffPanel
    self.BuffPanel = XUiGoldenMinerBuffPanel.New(self.PanelBuffParent, self)
end

function XUiGoldenMinerShop:RefreshBuffPanel(index)
    local func = self._BuffRefreshFunc[index]
    self.BuffPanel:UpdateBuff(func())
end
--endregion

--region Ui - ShopGrid DynamicTable
function XUiGoldenMinerShop:InitDynamicList()
    local XUiGoldenMinerShopGrid = require("XUi/XUiGoldenMiner/Shop/XUiGoldenMinerShopGrid")
    local buyCb = handler(self, self.Refresh)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGoldenMinerShopGrid, self, buyCb)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerShop:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGoldenMinerShopGrid
function XUiGoldenMinerShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curSelectBtnIndex = self.CurSelectBtnIndex
        local itemId = (curSelectBtnIndex == self._BtnGroupType.BuyItem and not XTool.IsTableEmpty(self.DataList[index]) and self.DataList[index]:GetGoldItemId()) or 0
        local upgradeLocalId = curSelectBtnIndex ~= self._BtnGroupType.BuyItem and self.DataList[index]
        grid:Refresh(itemId, upgradeLocalId, index)
        grid:SetCanvasGroupAlpha(0)
        local gridAnimationDelay = (index - 1) * 0.05
        self:Tween(gridAnimationDelay, function()
        end, function()
            grid:PlayAnimationRefresh()
        end)
    end
end
--endregion

--region Ui - Score
function XUiGoldenMinerShop:InitTxtCurScore()
    self.TextCurScoreChange.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerShop:UpdateTextCurScore()
    local score = self.DataDb:GetStageScores()
    self.TextTargetScore.text = XUiHelper.GetText("GoldenMinerShopTargetScore", self.DataDb:GetCurStageTargetScore())
    if not self.OriginScore then
        self.OriginScore = score
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", score)
    elseif self.OriginScore ~= score then
        self:PlayCurScoreChangeAnima(self.OriginScore - score, self.OriginScore)
        self.OriginScore = score
    end
end

function XUiGoldenMinerShop:PlayCurScoreChangeAnima(changeScore, originScore)
    if changeScore > 0 then
        self.TextCurScoreChange.text = -changeScore
        self.TextCurScoreChange.color = self._Control:GetClientShopScoreChangeColor(false)
    else
        self.TextCurScoreChange.text = "+"..-changeScore
        self.TextCurScoreChange.color = self._Control:GetClientShopScoreChangeColor(true)
    end
    self.TextCurScoreChange.gameObject:SetActiveEx(true)
    self:PlayAnimation("NumberEnable")
    self:StopCurScoreChangeAnima()

    self.CurScoreChangeAnima = XUiHelper.Tween(1, function(f)
        if XTool.UObjIsNil(self.TextCurScore) then  -- 防止动画还没结束就下一关导致报错
            return
        end
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", math.floor(originScore - changeScore * f))
    end, function()
        if XTool.UObjIsNil(self.TextCurScoreChange) then
            return
        end
        self.TextCurScoreChange.gameObject:SetActiveEx(false)
        self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", self.DataDb:GetStageScores())
    end)
end

function XUiGoldenMinerShop:StopCurScoreChangeAnima()
    if self.CurScoreChangeAnima then
        XScheduleManager.UnSchedule(self.CurScoreChangeAnima)
        self.CurScoreChangeAnima = nil
    end
end
--endregion

--region Ui - TipSellPanel
function XUiGoldenMinerShop:InitTipSellPanel()
    local XUiGoldenMinerShopTipPanel = require("XUi/XUiGoldenMiner/Shop/XUiGoldenMinerShopTipPanel")
    ---@type XUiGoldenMinerShopTipPanel
    self.TipPanel = XUiGoldenMinerShopTipPanel.New(self.PanelTips, self)
    self.BtnTipsClose.gameObject:SetActiveEx(false)
    self.TxtShipBuffListTitle = XUiHelper.TryGetComponent(self.Transform,
            "SafeAreaContentPane/PanelMainShop/PanelShop/PanelGreat/PanelBuff/PanelTitle/Text", "Text")
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShop:ShowTipSellPanel(buffId, itemGrid, positionX)
    self.TipPanel:Open()
    self.TipPanel:Refresh(buffId, itemGrid, positionX)
    self.BtnTipsClose.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelTipsEnable")
end

function XUiGoldenMinerShop:CloseTipSellPanel()
    self:PlayAnimation("PanelTipsDisable")
    self.TipPanel:Close()
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end
--endregion

--region Ui - GiveUpGame Tip
---打开放弃挑战的提示
function XUiGoldenMinerShop:OpenGiveUpGameTip()
    self._Control:OpenGiveUpGameTip()
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerShop:AddBtnClickListener()
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientHelpKey())
    self:RegisterClickEvent(self.BtnBack, self.OpenGiveUpGameTip)
    
    self:RegisterClickEvent(self.BtnEnterNextStage, self.OnBtnEnterNextStageClick)
    self:RegisterClickEvent(self.BtnTipsClose, self.CloseTipSellPanel)
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewMapClick)
    self:RegisterClickEvent(self.BtnOverview, self.OnBtnShipDetailClick)
end

function XUiGoldenMinerShop:OnBtnEnterNextStageClick()
    self.DataDb:ClearShopDb()
    self._Control:OpenGameUi()
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShop:OnSellItemClick(itemGrid)
    local itemColumn = itemGrid:GetItemColumn()
    local itemGridIndex = itemColumn:GetGridIndex()
    if self._Control:CheckUseItemIsInCD(itemGridIndex) then
        return
    end
    local itemId = itemGrid:GetItemColumn():GetItemId()
    local title = XUiHelper.GetText("GoldenMinerSellItemTitle")
    local content = XUiHelper.GetText("GoldenMinerSellItemContent",
            self._Control:GetCfgItemSellPrice(itemId),
            self._Control:GetCfgItemName(itemId))
    local sureCb = function()
        self._Control:RequestGoldenMinerSell(itemGridIndex, function()
            self:Refresh()
            self:CloseTipSellPanel()
        end)
    end
    XLuaUiManager.Open("UiGoldenMinerDialog", title, content, nil, sureCb)
end

function XUiGoldenMinerShop:OnBtnShipDetailClick()
    self._Control:RecordPreviewStage(
            XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI.UI_SHOP,
            XEnumConst.GOLDEN_MINER.CLIENT_RECORD_ACTION.SHIP_DETAIL)
    self:_OnBtnPreviewClick()
end

function XUiGoldenMinerShop:OnBtnPreviewMapClick()
    self._Control:RecordPreviewStage(
            XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI.UI_SHOP,
            XEnumConst.GOLDEN_MINER.CLIENT_RECORD_ACTION.STAGE_PREVIEW)
    self:_OnBtnPreviewClick()
end

function XUiGoldenMinerShop:_OnBtnPreviewClick()
    local stageId = self.DataDb:GetCurStageId()
    local mapId = self.DataDb:GetStageMapId(stageId)
    XLuaUiManager.Open("UiGoldenMinerBUFFDetails", mapId)
end
--endregion

--region Event - Listener
function XUiGoldenMinerShop:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_SELL_ITEM, self.OnSellItemClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.ShowTipSellPanel, self)
end

function XUiGoldenMinerShop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_SELL_ITEM, self.OnSellItemClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.ShowTipSellPanel, self)
end
--endregion
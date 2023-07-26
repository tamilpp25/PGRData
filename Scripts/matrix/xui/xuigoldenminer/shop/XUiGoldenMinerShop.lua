local XUiShopGrid = require("XUi/XUiGoldenMiner/Shop/XUiShopGrid")
local XUiShopTipPanel = require("XUi/XUiGoldenMiner/Shop/XUiShopTipPanel")
local XUiItemPanel = require("XUi/XUiGoldenMiner/Panel/XUiItemPanel")
local XUiBuffPanel = require("XUi/XUiGoldenMiner/Panel/XUiBuffPanel")

local BtnGroupType = {
    BuyItem = 1,
    Hook = 2,
    LevelUp = 3,
}

---黄金矿工商店界面
---@class XUiGoldenMinerShop : XLuaUi
local XUiGoldenMinerShop = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerShop")

function XUiGoldenMinerShop:OnAwake()
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:AddBtnClickListener()
    self:InitDynamicList()
    self:InitBtnGroup()
    self:InitUiObj()
end

function XUiGoldenMinerShop:OnStart()
    self.CurStageId = self.DataDb:GetCurStageId()
    self.PanelTabBtn:SelectIndex(BtnGroupType.BuyItem)
    self:InitTimes()
    self:CloseBuffTips()
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
function XUiGoldenMinerShop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Ui - Refresh
function XUiGoldenMinerShop:Refresh()
    self.TextTargetScore.text = XUiHelper.GetText("GoldenMinerShopTargetScore", self.DataDb:GetCurStageTargetScore())
    self:UpdateTextCurScore()
    self.ItemPanel:UpdateItemColumns()
    local func = self.BuffRefreshFunc[self.CurSelectBtnIndex]
    self.BuffPanel:UpdateBuff(func())
    self.DynamicTable:ReloadDataSync()
end
--endregion

--region Ui - ObjInit
function XUiGoldenMinerShop:InitUiObj()
    ---@type XUiGoldenMinerItemPanel
    self.ItemPanel = XUiItemPanel.New(self.PanelSkillParent, false)
    ---@type XUiGoldenMinerBuffPanel
    self.BuffPanel = XUiBuffPanel.New(self.PanelBuffParent, self)
    ---@type XGoldenMinerShopTipPanel
    self.TipPanel = XUiShopTipPanel.New(self.PanelTips)
    self.TextCurScoreChange.gameObject:SetActiveEx(false)
    self.BtnTipsClose.gameObject:SetActiveEx(false)
    self.TxtShipBuffListTitle = XUiHelper.TryGetComponent(self.Transform,
            "SafeAreaContentPane/PanelMainShop/PanelShop/PanelGreat/PanelBuff/PanelTitle/Text", "Text")
end
--endregion

--region Ui - ShopTabGroup
function XUiGoldenMinerShop:InitBtnGroup()
    local hookItemDataList, upItemDataList = XGoldenMinerConfigs.GetUpgradeShowDataDir()
    local btnGroup = {
        self.BtnBuyItem,
        self.BtnLevelFinger,
        self.BtnLevelUp,
    }
    self.BtnGroupData = {
        self.DataDb:GetMinerShopDbs(false),
        hookItemDataList,
        upItemDataList,
    }
    self.BuffRefreshFunc = {
        XDataCenter.GoldenMinerManager.GetTempBuffIdList,
        XDataCenter.GoldenMinerManager.GetShipBuffIdList,
        XDataCenter.GoldenMinerManager.GetShipBuffIdList,
    }
    self.BuffListTitle = {
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopItemTitle"),
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopShipTitle"),
        XUiHelper.ReadTextWithNewLine("GoldenMinerShopShipTitle"),
    }
    self.CurSelectBtnIndex = nil
    self.PanelTabBtn:Init(btnGroup, function(index) self:OnSelectButton(index) end)
end

function XUiGoldenMinerShop:OnSelectButton(index)
    if self.CurSelectBtnIndex == index then
        return
    end
    local func = self.BuffRefreshFunc[index]
    self.CurSelectBtnIndex = index
    self.BuffPanel:UpdateBuff(func())
    self.DataList = self.BtnGroupData[index]
    if self.TxtShipBuffListTitle then
        self.TxtShipBuffListTitle.text = self.BuffListTitle[index]
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
    --self:PlayAnimation("QieHuan")
end
--endregion

--region Ui - ShopGrid DynamicTable
function XUiGoldenMinerShop:InitDynamicList()
    local buyCb = handler(self, self.Refresh)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiShopGrid, self, buyCb)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end

---@param grid XGoldenMinerShopGrid
function XUiGoldenMinerShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curSelectBtnIndex = self.CurSelectBtnIndex
        local itemId = (curSelectBtnIndex == BtnGroupType.BuyItem and not XTool.IsTableEmpty(self.DataList[index]) and self.DataList[index]:GetGoldItemId()) or 0
        local upgradeLocalId = curSelectBtnIndex ~= BtnGroupType.BuyItem and self.DataList[index]
        grid:Refresh(itemId, upgradeLocalId, index)
    end
end
--endregion

--region Ui - Score
function XUiGoldenMinerShop:UpdateTextCurScore()
    local score = self.DataDb:GetStageScores()
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
        self.TextCurScoreChange.color = XGoldenMinerConfigs.GetShopScoreChangeColor(false)
    else
        self.TextCurScoreChange.text = "+"..-changeScore
        self.TextCurScoreChange.color = XGoldenMinerConfigs.GetShopScoreChangeColor(true)
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

--region Ui - Buff Tip
---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShop:ShowBuffTips(buffId, itemGrid, positionX)
    self.TipPanel:SetActive(true)
    self.TipPanel:Refresh(buffId, itemGrid, positionX)
    self.BtnTipsClose.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelTipsEnable")
end

function XUiGoldenMinerShop:CloseBuffTips()
    if not self.TipPanel.IsShow then
        return
    end
    self:PlayAnimation("PanelTipsDisable")
    self.TipPanel:SetActive(false)
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end
--endregion

--region Ui - GiveUpGame Tip
---打开放弃挑战的提示
function XUiGoldenMinerShop:OpenGiveUpGameTip()
    local SettleGame = function() self:GiveUpGame() end
    local SaveGame = function()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerSaveStage(0)
        XDataCenter.GoldenMinerManager.RecordSaveStage(XGoldenMinerConfigs.CLIENT_RECORD_UI.UI_SHOP)
    end
    XDataCenter.GoldenMinerManager:OpenGiveUpGameDialog(XUiHelper.GetText("GoldenMinerGiveUpGameTitle"),
            XUiHelper.GetText("GoldenMinerGiveUpGameContent"),
            nil,
            SaveGame,
            SettleGame,
            false)
end

function XUiGoldenMinerShop:GiveUpGame()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerExitGame(0, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
    end, nil, self.DataDb:GetStageScores(), self.DataDb:GetStageScores())
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerShop:AddBtnClickListener()
    self:BindHelpBtn(self.BtnHelp, XGoldenMinerConfigs.GetHelpKey())
    self:RegisterClickEvent(self.BtnBack, self.OpenGiveUpGameTip)
    
    self:RegisterClickEvent(self.BtnEnterNextStage, self.OnBtnEnterNextStageClick)
    self:RegisterClickEvent(self.BtnTipsClose, self.CloseBuffTips)
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewMapClick)
    self:RegisterClickEvent(self.BtnOverview, self.OnBtnShipDetailClick)
end

function XUiGoldenMinerShop:OnBtnEnterNextStageClick()
    local stageId = self.DataDb:GetCurStageId()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(stageId, function()
        XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
    end)
end

---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerShop:OnSellItemClick(itemGrid)
    local itemColumn = itemGrid:GetItemColumn()
    local itemGridIndex = itemColumn:GetGridIndex()
    if not XDataCenter.GoldenMinerManager.IsUseItem(itemGridIndex) then
        return
    end
    local itemId = itemGrid:GetItemColumn():GetItemId()
    local title = XUiHelper.GetText("GoldenMinerSellItemTitle")
    local content = XUiHelper.GetText("GoldenMinerSellItemContent",
            XGoldenMinerConfigs.GetItemSellPrice(itemId),
            XGoldenMinerConfigs.GetItemName(itemId))
    local sureCb = function()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerSell(itemGridIndex, function()
            self:Refresh()
            self:CloseBuffTips()
        end)
    end
    XLuaUiManager.Open("UiGoldenMinerDialog", title, content, nil, sureCb)
end

function XUiGoldenMinerShop:OnBtnShipDetailClick()
    XDataCenter.GoldenMinerManager.RecordPreviewStage(
            XGoldenMinerConfigs.CLIENT_RECORD_UI.UI_SHOP,
            XGoldenMinerConfigs.CLIENT_RECORD_ACTION.SHIP_DETAIL)
    self:_OnBtnPreviewClick()
end

function XUiGoldenMinerShop:OnBtnPreviewMapClick()
    XDataCenter.GoldenMinerManager.RecordPreviewStage(
            XGoldenMinerConfigs.CLIENT_RECORD_UI.UI_SHOP,
            XGoldenMinerConfigs.CLIENT_RECORD_ACTION.STAGE_PREVIEW)
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
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.ShowBuffTips, self)
end

function XUiGoldenMinerShop:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_SELL_ITEM, self.OnSellItemClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.ShowBuffTips, self)
end
--endregion
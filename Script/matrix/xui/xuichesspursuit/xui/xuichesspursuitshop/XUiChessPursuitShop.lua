local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiChessPursuitShopGrid = require("XUi/XUiChessPursuit/XUi/XUiChessPursuitShop/XUiChessPursuitShopGrid")
local XUiChessPursuitShop = XLuaUiManager.Register(XLuaUi, "UiChessPursuitShop")

function XUiChessPursuitShop:OnAwake()
    self.GridShop.gameObject:SetActiveEx(false)
    self:AutoAddListener()
    self:InitDynamicTable()
end

function XUiChessPursuitShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiChessPursuitShopGrid, self)
end

function XUiChessPursuitShop:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnRImgIconCost, self.OnBtnRImgIconCostClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
end

function XUiChessPursuitShop:OnStart(chessPursuitMapId, cb)
    self.ChessPursuitMapId = chessPursuitMapId
    self.Cb = cb

    self.CardMaxCount = XChessPursuitConfig.GetChessPursuitMapCardMaxCount(chessPursuitMapId)
    self:SetTempHaveCards()

    local addCoin = XChessPursuitConfig.GetChessPursuitMapAddCoin(chessPursuitMapId)
    self.TxtAdd.text = CSXTextManagerGetText("ChessPursuitEveryRoundAddCoinTips", addCoin)

    local coinId = XChessPursuitConfig.GetChessPursuitMapCoinId(chessPursuitMapId)
    local coinIcon = XDataCenter.ItemManager.GetItemIcon(coinId)
    self.RImgIconCost:SetRawImage(coinIcon)
end

function XUiChessPursuitShop:SetTempHaveCards()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.ChessPursuitMapId)
    self.TempHaveCards = XTool.Clone(chessPursuitMapDb:GetBuyedCards())
end

function XUiChessPursuitShop:OnEnable()
    self:Refresh()
end

function XUiChessPursuitShop:OnDestroy()
    if self.Cb then
        self.Cb(self.TempHaveCards)
    end
end

function XUiChessPursuitShop:Refresh()
    self:ClearCurSelectCard()
    self:RefreshCardMaxCount()
    self:RefreshDynamicTable()
    self:RefreshSelectCardTips()
    self.TxtRefreshCost.text = XDataCenter.ChessPursuitManager.GetCoinCount(self.ChessPursuitMapId)
end

function XUiChessPursuitShop:RefreshCardMaxCount()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.ChessPursuitMapId)
    local currCardCount = chessPursuitMapDb:GetHaveCardsCount()
    self.TxtCards.text = CSXTextManagerGetText("ChessPursuitCardMaxCount", currCardCount, self.CardMaxCount)
end

function XUiChessPursuitShop:RefreshDynamicTable()
    self.CardIdList = XDataCenter.ChessPursuitManager.GetShopCardIdList(self.ChessPursuitMapId)
    self.DynamicTable:SetDataSource(self.CardIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiChessPursuitShop:RefreshSelectCardTips()
    local curSelectCardId = self.CardIdList and self.CardIdList[self.CurSelectCardIndex]
    if not curSelectCardId then
        self:ClearCurSelectCard()
        return
    end
    local coin = XChessPursuitConfig.GetCardSubCoin(curSelectCardId)
    local coinId = XChessPursuitConfig.GetChessPursuitMapCoinId(self.ChessPursuitMapId)
    local coinName = XDataCenter.ItemManager.GetItemName(coinId)
    local name = XChessPursuitConfig.GetCardName(curSelectCardId)
    self.TxtTips.text = CSXTextManagerGetText("ChessPursuitShopBuyTips", coin, coinName, name)
    self.BtnBuy.gameObject:SetActiveEx(true)
end

function XUiChessPursuitShop:RefreshCurSelectCardGrid(grid)
    if self.CurSelectCardGrid then
        self.CurSelectCardGrid:ShowImgSelect(self.CurSelectCardIndex)
    end
    self.CurSelectCardGrid = grid
end

function XUiChessPursuitShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local cardId = self.CardIdList[index]
        grid:Refresh(cardId, self.CurSelectCardIndex, self.ChessPursuitMapId, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurSelectCardIndex = index
        grid:ShowImgSelect(self.CurSelectCardIndex)
        self:RefreshCurSelectCardGrid(grid)
        self:RefreshSelectCardTips()
    end
end

function XUiChessPursuitShop:OnBtnRImgIconCostClick()
    XDataCenter.ChessPursuitManager.OpenCoinTip()
end

function XUiChessPursuitShop:OnBtnBuyClick()
    local curSelectCardId = self.CardIdList[self.CurSelectCardIndex]
    XDataCenter.ChessPursuitManager.RequestChessPursuitBuyCardData({curSelectCardId}, handler(self, self.Refresh))
end

function XUiChessPursuitShop:ClearCurSelectCard()
    self.CurSelectCardIndex = -1
    self.CurSelectCardGrid = nil
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.TxtTips.text = ""
end